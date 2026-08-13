extends Node2D

# Đường dẫn đến các file Scene map của bạn
const HOUSE_SCENE = preload("res://Maps/Thanh_Truong_An/ThanhTruongAn.tscn")
#const FARM_SCENE = preload("res://Maps/Farm.tscn")

@onready var map_container: Node2D = $MapContainer

var current_map: Node = null

func _ready() -> void:
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
