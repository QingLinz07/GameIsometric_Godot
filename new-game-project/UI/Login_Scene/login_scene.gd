extends Control

@onready var username_input = $UsernameInput  # Dùng để nhập tên nhân vật mới
@onready var status_label = $StatusLabel
@onready var save_list_container = $SaveListContainer/VBoxContainer # Đã sửa trỏ đúng vào VBoxContainer nằm trong ScrollContainer

const DEFAULT_MAP = "res://Main/Main.tscn"
const PLAYER_SCENE_PATH = "res://Characters/Player_Scene/player.tscn"

func _ready():
	$RegisterButton.pressed.connect(_on_create_character_pressed) # Nút tạo nhân vật mới
	refresh_character_list()

# --- HÀM LẤY ĐƯỜNG DẪN FILE SAVE CỦA NHÂN VẬT ---
func get_save_path(character_name: String) -> String:
	var safe_name = character_name.strip_edges().to_lower()
	return "res://Save_System/Save_Games/save_%s.json" % safe_name

# --- TẢI DANH SÁCH NHÂN VẬT ĐÃ CÓ ĐỂ HIỂN THỊ ---
func refresh_character_list():
	if not save_list_container:
		return
		
	# Xóa các nút cũ trước khi load lại danh sách
	for child in save_list_container.get_children():
		child.queue_free()
		
	# Quét thư mục user:// để tìm các file save nhân vật
	var dir = DirAccess.open("res://Save_System/Save_Games/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("save_") and file_name.ends_with(".json"):
				var char_name = file_name.trim_prefix("save_").trim_suffix(".json")
				
				# Tạo một nút (Button) cho mỗi nhân vật để bấm vào chơi luôn
				var btn = Button.new()
				btn.text = "Vào vai: " + char_name.capitalize()
				btn.pressed.connect(func(): _on_load_character_pressed(char_name))
				save_list_container.add_child(btn)
				
			file_name = dir.get_next()

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
		"max_stamina": 100
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
