extends Node

# Thời gian tự động lưu (tính bằng giây)
# 5 phút = 5 * 60 = 300 giây. (Có thể chỉnh nhỏ lại để test, ví dụ 10-30 giây)
@export var save_interval: float = 180.0

var timer: Timer

func _ready() -> void:
	# Đợi một chút để đảm bảo các node khác đã sẵn sàng khi khởi động game
	await get_tree().process_frame
	setup_auto_save_timer()

func setup_auto_save_timer() -> void:
	timer = Timer.new()
	timer.wait_time = save_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_auto_save_timeout)
	add_child(timer)
	print("[AutoSaveManager] Đã kích hoạt hệ thống Auto-save định kỳ (5 phút/lần).")

func _on_auto_save_timeout() -> void:
	# Kiểm tra xem có đang có nhân vật nào chơi không
	if GameManager.current_save_path.is_empty() or GameManager.current_player_data.is_empty():
		return
	
	# 1. CẬP NHẬT DỮ LIỆU MỚI NHẤT TỪ NHÂN VẬT TRÊN MÀN HÌNH
	sync_player_data_to_cache()
	
	# 2. GỌI HÀM LƯU CỦA GAMEMANAGER
	var success = GameManager.save_current_player()
	if success:
		print("[AutoSaveManager] Auto-save thành công lúc: ", Time.get_time_string_from_system())
	else:
		print("[AutoSaveManager] Auto-save thất bại!")

# Hàm đồng bộ dữ liệu thời gian thực từ Scene Game vào Dictionary
func sync_player_data_to_cache() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_tree().current_scene.get_node_or_null("Player")
		if player == null:
			return
			
	var data = GameManager.current_player_data
	
	# 1. Cập nhật tọa độ vị trí
	if "global_position" in player:
		data["pos_x"] = player.global_position.x
		data["pos_y"] = player.global_position.y
	elif "position" in player:
		data["pos_x"] = player.position.x
		data["pos_y"] = player.position.y
		
	# 2. Lấy HP và Max HP từ file C# HealthSystem của player
	if player.get("health") != null:
		var h_sys = player.health
		if "current_hp" in h_sys: data["hp"] = h_sys.current_hp
		if "max_hp" in h_sys: data["max_hp"] = h_sys.max_hp
		
	# 3. Lấy Stamina và Max Stamina từ file C# StaminaSystem của player
	if player.get("stamina") != null:
		var s_sys = player.stamina
		if "current_stamina" in s_sys: data["stamina"] = s_sys.current_stamina
		if "max_stamina" in s_sys: data["max_stamina"] = s_sys.max_stamina

	# 4. Các chỉ số khác (nếu player có khai báo biến trực tiếp)
	if "level" in player: data["level"] = player.level
	if "exp" in player: data["exp"] = player.exp
	if "max_exp" in player: data["max_exp"] = player.max_exp
	
	# Lưu tên nhân vật và map nếu có
	if "player_name" in player and not player.player_name.is_empty():
		data["character_name"] = player.player_name

	var inventory_ui = get_tree().get_first_node_in_group("InventoryUI")
	if inventory_ui and inventory_ui.has_method("GetInventorySaveData"):
		data["inventory_data"] = inventory_ui.GetInventorySaveData()
