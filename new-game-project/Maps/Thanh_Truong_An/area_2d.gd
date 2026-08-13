extends Area2D

@export var highlight_color: Color = Color(0.0, 0.0, 0.0, 0.5)
@export var behind_z_index: int = -1

# Dùng Dictionary để lưu thuộc tính gốc của từng Player (tránh lỗi khi 2 Player cùng chui vào cây)
var _original_colors: Dictionary = {}
var _original_z_indices: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# SỬA: Kiểm tra xem body có phải là CharacterBody2D (Nhân vật chơi) hay không
	if body is CharacterBody2D:
		# Lưu lại thuộc tính gốc theo ID của Node
		_original_colors[body.get_instance_id()] = body.modulate
		_original_z_indices[body.get_instance_id()] = body.z_index
		
		# Đổi Z-Index và màu sắc
		body.z_index = behind_z_index
		body.modulate = highlight_color

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		var instance_id = body.get_instance_id()
		
		# Khôi phục lại Z-Index và màu ban đầu
		if _original_z_indices.has(instance_id):
			body.z_index = _original_z_indices[instance_id]
			_original_z_indices.erase(instance_id)
			
		if _original_colors.has(instance_id):
			body.modulate = _original_colors[instance_id]
			_original_colors.erase(instance_id)
