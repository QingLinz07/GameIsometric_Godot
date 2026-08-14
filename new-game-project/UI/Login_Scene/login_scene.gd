extends Control
var custom_font = load("res://Asset/Font/Noto_Serif_SC/NotoSerifSC-VariableFont_wght.ttf")

@export var target_width: int = 1280
@export var target_height: int = 720
#Login Chính
@onready var new_button = $Login_Chinh/new_game
@onready var load_button = $Login_Chinh/load_game
@onready var exit_button = $Login_Chinh/exit_game
# Tạo Nhân Vật
@onready var username_input = $Tao_Nhan_Vat/UsernameInput  
@onready var status_label = $Tao_Nhan_Vat/StatusLabel
@onready var register_button = $Tao_Nhan_Vat/RegisterButton
@onready var back_button = $back_button
#Load Nhân Vật
@onready var save_list_container = $Load_Nhan_Vat/SaveListContainer/VBoxContainer # Đã sửa trỏ đúng vào VBoxContainer nằm trong ScrollContainer
@onready var khung_load = $Load_Nhan_Vat/SaveListContainer/VBoxContainer/load_players

const DEFAULT_MAP = "res://Main/Main.tscn"
const PLAYER_SCENE_PATH = "res://Characters/Player_Scene/player.tscn"

func _ready():
	# 1. Ép cửa sổ thoát khỏi chế độ Fullscreen của Project Setting, chuyển về Windowed
	get_window().mode = Window.MODE_WINDOWED
	
	# 2. Đặt lại kích thước cửa sổ thành 1280x720
	DisplayServer.window_set_size(Vector2i(target_width, target_height))
	
	# 3. Tự động căn cửa sổ ra giữa màn hình
	get_window().move_to_center()
	
	# 4. Ghi đè cấu hình co giãn (Stretch) để nội dung tự khớp với 1280x720
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().root.content_scale_size = Vector2i(target_width, target_height)

	# Chống phóng to / Không cho người dùng kéo giãn cửa sổ game
	get_window().unresizable = true

	# Khóa không cho bấm nút maximize (ô vuông) trên thanh tiêu đề
	get_window().maximize_disabled = true

	new_button.pressed.connect(_new_game_pressed)
	load_button.pressed.connect(_load_game_pressed)
	exit_button.pressed.connect(_exit_game_pressed)
	back_button.pressed.connect(_button_back_pressed)

	_login_chinh()
	
	register_button.pressed.connect(_on_create_character_pressed) # Nút tạo nhân vật mới
	refresh_character_list()

# --- HÀM LẤY ĐƯỜNG DẪN FILE SAVE CỦA NHÂN VẬT ---
func get_save_path(character_name: String) -> String:
	var safe_name = character_name.strip_edges().to_lower()
	return "res://Save_System/Save_Games/save_%s.json" % safe_name

# --- TẢI DANH SÁCH NHÂN VẬT ĐÃ CÓ ĐỂ HIỂN THỊ ---
func refresh_character_list():
	if not save_list_container:
		return
		
	# 1. Xóa các nút cũ trước khi load lại
	for child in save_list_container.get_children():
		child.queue_free()
		
	# 2. Quét thư mục tìm file save
	var dir = DirAccess.open("res://Save_System/Save_Games/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("save_") and file_name.ends_with(".json"):
				var char_name = file_name.trim_prefix("save_").trim_suffix(".json")
				
				# Đọc dữ liệu từ file JSON để lấy level
				var char_level = 0
				var file_path = "res://Save_System/Save_Games/" + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_data = JSON.parse_string(file.get_as_text())
					if json_data and json_data.has("level"):
						char_level = json_data["level"]
				
				# 3. Tạo TextureButton làm nút bấm chính (Nền)
				var btn = TextureButton.new()
				btn.custom_minimum_size = Vector2(400, 200) # Kích thước tổng của khung
				btn.ignore_texture_size = true
				btn.stretch_mode = TextureButton.STRETCH_SCALE
				btn.texture_normal = preload("res://UI/Login_Scene/intro/khung_load_nhan_vat.png") 
				btn.pressed.connect(func(): _on_load_character_pressed(char_name))
				
				# 4. TẠO TÊN NHÂN VẬT (Tự chỉnh tọa độ ở đây)
				var name_label = Label.new()
				name_label.text = char_name.capitalize()
				name_label.position = Vector2(220, 75) # <-- Tọa độ X, Y của Tên nhân vật
				#name_label.add_theme_font_size_override("font_size", 10) # Chỉnh cỡ chữ nếu muốn
				#name_label.add_theme_font_override("font", custom_font)
				name_label.add_theme_color_override("font_color", Color.BLACK)
				btn.add_child(name_label)
				
				# 5. TẠO LEVEL NHÂN VẬT (Tự chỉnh tọa độ ở đây)
				var level_label = Label.new()
				level_label.text = "Level: " + str(int(char_level))
				level_label.position = Vector2(220, 105) # <-- Tọa độ X, Y của Level
				#level_label.add_theme_font_size_override("font_size", 10) # Chỉnh cỡ chữ nếu muốn
				#level_label.add_theme_font_override("font", custom_font)
				level_label.add_theme_color_override("font_color", Color.BLACK)
				btn.add_child(level_label)
				
				# 6. TẠO NÚT DẤU X ĐỂ XÓA NHÂN VẬT (Tự chỉnh tọa độ và kích thước ở đây)
				var delete_btn = TextureButton.new()
				delete_btn.custom_minimum_size = Vector2(30, 30) # <-- Kích thước nút X
				delete_btn.ignore_texture_size = true
				delete_btn.stretch_mode = TextureButton.STRETCH_SCALE
				# Gán hình ảnh dấu X của bạn vào đây (nếu chưa có ảnh có thể đổi thành Button.new())
				delete_btn.texture_normal = preload("res://UI/Login_Scene/intro/x.png") 
				
				delete_btn.position = Vector2(310, 45) # <-- Tọa độ X, Y của nút X (Góc trên bên phải khung)
				
				# Sự kiện khi bấm nút Xóa
				delete_btn.pressed.connect(func():
					_on_delete_character_pressed(file_path)
				)
				btn.add_child(delete_btn)
				
				# Đưa nút hoàn chỉnh vào VBoxContainer danh sách
				save_list_container.add_child(btn)
				
			file_name = dir.get_next()

# Hàm xử lý xóa file save nhân vật
func _on_delete_character_pressed(file_path: String) -> void:
	# 1. Tạo hộp thoại xác nhận
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Xác nhận xóa"
	confirm_dialog.dialog_text = "Bạn có chắc chắn muốn xóa nhân vật này không?"
	
	# 2. Xử lý sự kiện khi người chơi bấm nút OK (Confirmed)
	confirm_dialog.confirmed.connect(func():
		var err = DirAccess.remove_absolute(file_path)
		if err == OK:
			#print("Đã xóa nhân vật thành công!")
			refresh_character_list() # Load lại danh sách sau khi xóa
		else:
			print("Lỗi khi xóa nhân vật!")
		confirm_dialog.queue_free() # Xóa dialog khỏi bộ nhớ sau khi dùng xong
	)
	
	# 3. Xử lý sự kiện khi người chơi bấm Hủy (Cancel hoặc đóng popup)
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free() # Xóa dialog khỏi bộ nhớ
	)
	
	# 4. Thêm hộp thoại vào Scene hiện tại để nó hiển thị lên màn hình
	get_tree().root.add_child(confirm_dialog)
	confirm_dialog.popup_centered() # Hiện popup ở giữa màn hình game
# --- Luân Chuẩn Các Phiên ---
func _login_chinh() -> void:
	$Login_Chinh.visible = true
	$Tao_Nhan_Vat.visible = false
	$Load_Nhan_Vat.visible = false
	$back_button.visible = false

func _tao_nhan_vat() -> void:
	$Login_Chinh.visible = false
	$Tao_Nhan_Vat.visible = true
	$Load_Nhan_Vat.visible = false
	$back_button.visible = true

func _load_nhan_vat() -> void:
	$Login_Chinh.visible = false
	$Tao_Nhan_Vat.visible = false
	$Load_Nhan_Vat.visible = true	
	$back_button.visible = true	


#--- NÚT CHUYỂN ĐẾN CÁC PHIÊN ---
func _new_game_pressed():
	_tao_nhan_vat()

func _load_game_pressed():
	_load_nhan_vat()

func _exit_game_pressed():
	# 1. Khởi tạo hộp thoại
	var dialog = ConfirmationDialog.new()
	dialog.title = "Thông báo!"
	dialog.dialog_text = "Bạn có muốn thoát khỏi trò chơi?"
	
	# 2. Bắt sự kiện khi người dùng bấm nút OK (Confirmed)
	dialog.confirmed.connect(func():
		get_tree().quit()
	)
	
	# 3. Bắt sự kiện khi người dùng bấm Hủy (Canceled)
	dialog.canceled.connect(func():
		dialog.queue_free() # Dọn dẹp bộ nhớ
	)
	
	# 4. Thêm vào màn hình và hiện lên giữa màn hình
	get_tree().root.add_child(dialog)
	dialog.popup_centered()	

func _button_back_pressed():
	_login_chinh()		
# --- TẠO NHÂN VẬT MỚI ---
func _on_create_character_pressed():
	var character_name = username_input.text.strip_edges()
	
	if character_name.is_empty():
		status_label.text = "Vui lòng nhập tên nhân vật!"
		return
		
	# --- THÊM ĐIỀU KIỆN KIỂM TRA ĐỘ DÀI TÊN ---
	if character_name.length() > 12:
		status_label.text = "Tên nhân vật không được quá 12 ký tự!"
		return
	# -------------------------------------------
		
	var file_path = get_save_path(character_name)
	
	if FileAccess.file_exists(file_path):
		status_label.text = "Nhân vật này đã tồn tại!"
		return
		
	# Khởi tạo dữ liệu mặc định cho nhân vật mới
	var new_data = {
		"character_name": character_name,
		"map_path": DEFAULT_MAP,
		"pos_x": 200.0,
		"pos_y": 200.0,
		"hp": 100,
		"max_hp": 100,
		"level": 1,
		"stamina": 100,
		"max_stamina": 100,
		"exp": 0,
		"max_exp": 100
	}
	
	if save_character_data(file_path, new_data):
		status_label.text = "Tạo nhân vật thành công!"
		username_input.text = ""
		refresh_character_list()
	else:
		status_label.text = "Lỗi khi tạo file save!"

# --- CHỌN NHÂN VẬT CÓ SẴN ĐỂ VÀO GAME ---
func _on_load_character_pressed(character_name: String):
	var file_path = get_save_path(character_name)
	
	if not FileAccess.file_exists(file_path):
		status_label.text = "Không tìm thấy file save của nhân vật này!"
		refresh_character_list()
		return
		
	var user_data = load_character_data(file_path)
	if user_data.is_empty():
		status_label.text = "File save bị lỗi hoặc hỏng dữ liệu!"
		return
		
	# --- GỌI GAMEMANAGER TẠI ĐÂY ---
	GameManager.current_save_path = file_path
	GameManager.current_player_data = user_data
	# -----------------------------	
		
	status_label.text = "Đang vào game cho " + character_name + "..."
	
	var target_map_path = user_data.get("map_path", DEFAULT_MAP)
	var spawn_pos = Vector2(float(user_data.get("pos_x", 200.0)), float(user_data.get("pos_y", 200.0)))
	
	await get_tree().create_timer(0.3).timeout
	
	if not ResourceLoader.exists(target_map_path):
		status_label.text = "Lỗi: Không tìm thấy file Map!"
		return
		
	# 1. Load và đổi scene sang Map
	var map_scene = load(target_map_path).instantiate()
	get_tree().root.add_child(map_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = map_scene
	
	# 2. Tự động tìm node "Players" trên bản đồ
	var players_container = map_scene.get_node_or_null("Players")
	if not players_container:
		players_container = Node2D.new()
		players_container.name = "Players"
		map_scene.add_child(players_container)
		
	# 3. Khởi tạo player và gán đúng tên + tọa độ
	var player_scene = load(PLAYER_SCENE_PATH)
	if player_scene:
		var player_instance = player_scene.instantiate()
		player_instance.name = character_name
		player_instance.player_name = character_name
		player_instance.global_position = spawn_pos
		
		players_container.add_child(player_instance)
		
		if player_instance.has_node("Camera2D"):
			player_instance.get_node("Camera2D").make_current()
			
		print("[SaveSystem] Đã vào game với nhân vật: ", character_name, " tại: ", spawn_pos)

# --- HÀM ĐỌC/GHI FILE JSON RIÊNG LẺ ---

func load_character_data(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
		
	var content = file.get_as_text().strip_edges()
	if content.is_empty():
		return {}
		
	var json = JSON.parse_string(content)
	if typeof(json) == TYPE_DICTIONARY:
		return json
		
	return {}

func save_character_data(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
		
	file.store_string(JSON.stringify(data, "\t"))
	return true
