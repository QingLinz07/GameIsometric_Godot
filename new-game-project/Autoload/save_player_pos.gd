extends Node

static var instance = null
var tracked_player_name: String = ""
var tracked_player_node: Node2D = null

var save_timer: Timer

func _enter_tree() -> void:
	instance = self
	print("[SaveSystem] Autoload đã được khởi tạo thành công!")
	
	# Tạo Timer tự động lưu mỗi 3 giây
	save_timer = Timer.new()
	save_timer.wait_time = 5.0
	save_timer.autostart = true
	save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(save_timer)

func _exit_tree() -> void:
	_force_save_current_position()

func _on_auto_save_timeout() -> void:
	_force_save_current_position()

func _force_save_current_position() -> void:
	if tracked_player_name != "" and tracked_player_node != null and is_instance_valid(tracked_player_node):
		save_character_position(tracked_player_name, tracked_player_node.global_position)

# --- HÀM LẤY ĐƯỜNG DẪN FILE SAVE RIÊNG CỦA NHÂN VẬT ---
func get_save_path(p_name: String) -> String:
	var safe_name = p_name.strip_edges().to_lower()
	return "res://Save_System/Save_Games/save_%s.json" % safe_name

func setup_tracking(p_name: String, player_node: Node2D) -> void:
	if instance:
		instance.tracked_player_name = p_name
		instance.tracked_player_node = player_node
		print("[SaveSystem] Đã ghim theo dõi tọa độ thành công cho: ", p_name)
	else:
		print("[SaveSystem LỖI] Instance của Autoload đang bị null!")

func get_spawn_position(p_name: String) -> Vector2:
	var file_path = get_save_path(p_name)
	if not FileAccess.file_exists(file_path):
		return Vector2(200.0, 200.0)
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return Vector2(200.0, 200.0)
		
	var content = file.get_as_text()
	var json = JSON.parse_string(content)
	
	if typeof(json) == TYPE_DICTIONARY:
		var x = float(json.get("pos_x", 200.0))
		var y = float(json.get("pos_y", 200.0))
		return Vector2(x, y)
		
	return Vector2(200.0, 200.0)

func save_character_position(p_name: String, current_pos: Vector2) -> void:
	var file_path = get_save_path(p_name)
	var data = {}
	
	# Đọc dữ liệu hiện tại của file save nhân vật (để không làm mất các thông tin khác nếu có)
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file != null:
			var content = file.get_as_text()
			var json = JSON.parse_string(content)
			if typeof(json) == TYPE_DICTIONARY:
				data = json
				
	# Cập nhật tọa độ mới
	data["character_name"] = p_name
	data["pos_x"] = current_pos.x
	data["pos_y"] = current_pos.y
	
	# Ghi ngược lại file riêng của nhân vật đó
	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file != null:
		save_file.store_string(JSON.stringify(data, "\t"))
		save_file.flush()
		# print("[JSON] ĐÃ LƯU TỌA ĐỘ -> Nhân vật: ", p_name, " | X:", current_pos.x, " Y:", current_pos.y)
	else:
		print("[JSON LỖI] Không thể mở file save tại: ", file_path)
