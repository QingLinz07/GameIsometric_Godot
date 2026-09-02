extends Node2D

const COLS = 13
const ROWS = 7
const TILE_SIZE = 1024

func _ready() -> void:
	# Tìm node Sprite2D gốc (hãy đổi tên node đó thành "Sprite2D_Goc" cho dễ tìm)
	var original_sprite = get_parent().get_node("Sprite2D_Goc")
	
	if not original_sprite:
		push_error("Không tìm thấy node Sprite2D_Goc!")
		return
		
	# Lấy trực tiếp vị trí và scale của node (không cần texture nữa)
	var pos = original_sprite.global_position
	var sca = original_sprite.scale
	
	# Xóa node gốc này luôn cho sạch sẽ, không tốn tài nguyên
	original_sprite.queue_free()
	
	# Tiến hành rải 91 mảnh
	spawn_all_tiles(pos, sca)

func spawn_all_tiles(pos: Vector2, sca: Vector2) -> void:
	var total_width = 13120
	var total_height = 7047
	
	# Tính kích thước thực tế dựa vào width x height của ảnh gốc và scale
	var img_size = Vector2(total_width, total_height) * sca
	var top_left_pos = pos - (img_size / 2.0)
	
	for row in range(ROWS):
		for col in range(COLS):
			var x = col * TILE_SIZE
			var y = row * TILE_SIZE
			
			if x >= total_width or y >= total_height:
				continue
				
			var tile = Sprite2D.new()
			tile.centered = false
			
			# Đúng định dạng hàng_cột của bạn
			var file_path = "res://Maps/Thanh_Truong_An/Asset/tile_%d_%d.png" % [row, col]
			
			if ResourceLoader.exists(file_path):
				tile.texture = null # Ban đầu để trống cho nhẹ RAM
				tile.position = top_left_pos + Vector2(x, y) * sca
				tile.scale = sca
				
				# Cơ chế load/unload thông minh qua Camera
				var notifier = VisibleOnScreenNotifier2D.new()
				notifier.rect = Rect2(Vector2.ZERO, Vector2(TILE_SIZE, TILE_SIZE))
				
				notifier.screen_entered.connect(func(): tile.texture = load(file_path))
				notifier.screen_exited.connect(func(): tile.texture = null)
				
				tile.add_child(notifier)
				add_child(tile)