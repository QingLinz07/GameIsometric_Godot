extends Node

# Lưu đường dẫn file save của nhân vật đang hoạt động
var current_save_path: String = ""

# Lưu bộ nhớ đệm dữ liệu của nhân vật để truy xuất nhanh trong game
var current_player_data: Dictionary = {}

func _ready() -> void:
	# Khởi tạo GameManager khi game bắt đầu
	get_window().unresizable = true

# --- 1. ĐỌC DỮ LIỆU TỪ FILE JSON ---
func load_character_data(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("[GameManager] Không tìm thấy file save tại: ", file_path)
		return {}
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[GameManager] Không thể mở file để đọc: ", file_path)
		return {}
		
	var content = file.get_as_text().strip_edges()
	if content.is_empty():
		return {}
		
	var json = JSON.parse_string(content)
	if typeof(json) == TYPE_DICTIONARY:
		return json
		
	print("[GameManager] Dữ liệu JSON không hợp lệ (không phải Dictionary)!")
	return {}

# --- 2. GHI / LƯU DỮ LIỆU VÀO FILE JSON ---
func save_character_data(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("[GameManager] Không thể mở file để ghi: ", file_path)
		return false
		
	file.store_string(JSON.stringify(data, "\t"))
	return true

# --- 3. LƯU NHANH DỰA TRÊN NHÂN VẬT ĐANG ĐĂNG NHẬP ---
func save_current_player() -> bool:
	if current_save_path.is_empty() or current_player_data.is_empty():
		print("[GameManager] Không có thông tin nhân vật hiện tại để lưu!")
		return false
		
	return save_character_data(current_save_path, current_player_data)

# --- 4. CẬP NHẬT MỘT THUỘC TÍNH BẤT KỲ VÀ TỰ ĐỘNG LƯU (TÙY CHỌN) ---
func update_player_property(key: String, value, auto_save: bool = true) -> void:
	if current_player_data.is_empty():
		print("[GameManager] Chưa có dữ liệu player nào được tải vào GameManager!")
		return
		
	current_player_data[key] = value
	
	if auto_save:
		save_current_player()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		print("[GameManager] Phát hiện yêu cầu thoát game! Đang tiến hành lưu khẩn cấp...")
		
		# 1. Đồng bộ dữ liệu mới nhất từ Player lần cuối
		if AutoSaveManager.has_method("sync_player_data_to_cache"):
			AutoSaveManager.sync_player_data_to_cache()
			
		# 2. Ghi file JSON ngay lập tức
		save_current_player()
		
		# 3. Cho phép thoát game an toàn
		get_tree().quit()
