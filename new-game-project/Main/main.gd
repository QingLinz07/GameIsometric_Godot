extends Node2D
@export var target_width: int = 1920
@export var target_height: int = 1080
# Đường dẫn đến các file Scene map của bạn
const HOUSE_SCENE = preload("res://Maps/Thanh_Truong_An/ThanhTruongAn.tscn")
#const FARM_SCENE = preload("res://Maps/Farm.tscn")

@onready var map_container: Node2D = $MapContainer

var current_map: Node = null

func _ready() -> void:
	SceneManager.unload_scene_by_path("res://UI/Login_Scene/LoginScene.tscn")
	# 1. Ép cửa sổ thoát khỏi chế độ Fullscreen của Project Setting, chuyển về Windowed
	get_window().mode = Window.MODE_FULLSCREEN
	
	# 2. Đặt lại kích thước cửa sổ thành 1280x720
	DisplayServer.window_set_size(Vector2i(target_width, target_height))
	
	# 3. Tự động căn cửa sổ ra giữa màn hình
	get_window().move_to_center()
	
	# 4. Ghi đè cấu hình co giãn (Stretch) để nội dung tự khớp với 1280x720
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_tree().root.content_scale_size = Vector2i(target_width, target_height)
	# Khi game bắt đầu, load mặc định map đầu tiên (Ví dụ: Nhà - House)
	change_map(HOUSE_SCENE)

func change_map(map_scene: PackedScene) -> void:
	# 1. Xóa map cũ đang hiển thị (nếu có)
	if current_map != null:
		current_map.queue_free()
	
	# 2. Khởi tạo map mới từ PackedScene
	current_map = map_scene.instantiate()
	
	# 3. Thêm map mới vào trong MapContainer của Main Scene
	map_container.add_child(current_map)
