extends Camera2D

@export var min_zoom: float = 0.75
@export var max_zoom: float = 1.5
@export var zoom_step: float = 0.1
@export var zoom_speed: float = 10.0 # Tốc độ zoom mượt (càng cao zoom càng nhanh)

var target_zoom: float = 0.75

func _ready() -> void:
	# Đặt zoom mặc định ban đầu
	target_zoom = min_zoom
	zoom = Vector2(target_zoom, target_zoom)
	
	# Đợi 1-2 frame để đảm bảo Player đã được add vào Map Scene và Scene Tree đã sẵn sàng
	await get_tree().process_frame
	await get_tree().process_frame
	
	setup_camera_limits()

func _process(delta: float) -> void:
	# Nội suy mượt giá trị zoom hiện tại về phía target_zoom mỗi frame
	var current_zoom = zoom.x
	if not is_equal_approx(current_zoom, target_zoom):
		var new_zoom = lerpf(current_zoom, target_zoom, zoom_speed * delta)
		zoom = Vector2(new_zoom, new_zoom)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom += zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom -= zoom_step
		
		# Giới hạn giá trị zoom nằm trong khoảng min và max
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)

func setup_camera_limits() -> void:
	var current_scene = get_tree().current_scene
	var limit_rect = Rect2()
	
	# Ưu tiên 1: Tìm node ảnh nền map (Sprite2D) trong map hiện tại
	var bg_sprite = _find_node_by_type(current_scene, Sprite2D)
	if bg_sprite and bg_sprite.texture:
		var tex_size = bg_sprite.texture.get_size() * bg_sprite.scale
		limit_rect = Rect2(
			bg_sprite.global_position.x - (tex_size.x / 2),
			bg_sprite.global_position.y - (tex_size.y / 2),
			tex_size.x,
			tex_size.y
		)
	else:
		# Ưu tiên 2: Nếu không thấy Sprite2D, tìm NavigationRegion2D
		var nav_region = _find_node_by_type(current_scene, NavigationRegion2D)
		if nav_region and nav_region.navigation_polygon:
			var poly = nav_region.navigation_polygon
			if poly.get_outline_count() > 0:
				var points = poly.get_outline(0)
				var min_pos = points[0]
				var max_pos = points[0]
				
				for pt in points:
					min_pos.x = min(min_pos.x, pt.x)
					min_pos.y = min(min_pos.y, pt.y)
					max_pos.x = max(max_pos.x, pt.x)
					max_pos.y = max(max_pos.y, pt.y)
					
				var cam_offset = nav_region.global_position
				limit_rect = Rect2(
					min_pos.x + cam_offset.x,
					min_pos.y + cam_offset.y,
					max_pos.x - min_pos.x,
					max_pos.y - min_pos.y
				)
	
	# Áp dụng giới hạn vào Camera2D
	if limit_rect != Rect2():
		limit_left = int(limit_rect.position.x)
		limit_top = int(limit_rect.position.y)
		limit_right = int(limit_rect.end.x)
		limit_bottom = int(limit_rect.end.y)

# Hàm đệ quy tìm node theo kiểu dữ liệu
func _find_node_by_type(node: Node, type) -> Node:
	# Bỏ qua chính node Player để camera không tự nhận nhầm sprite của nhân vật
	if node is CharacterBody2D or node == self or (self.get_parent() and node == self.get_parent()):
		pass
	elif is_instance_of(node, type):
		return node
		
	for child in node.get_children():
		var result = _find_node_by_type(child, type)
		if result:
			return result
	return null