extends Area2D

# Màu tối và trong suốt để giả lập góc khuất
@export var shadow_color: Color = Color(0.3, 0.3, 0.4, 0.6)

var _original_colors: Dictionary = {}

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if body is CharacterBody2D:
        # Lưu màu gốc
        _original_colors[body.get_instance_id()] = body.modulate
        
        # Đổi màu thành tối hơn và trong suốt hơn
        # Chúng ta nhân màu gốc với màu shadow để giữ được sắc thái của nhân vật
        # nhưng làm nó tối đi đáng kể
        body.modulate = body.modulate * shadow_color

func _on_body_exited(body: Node2D) -> void:
    if body is CharacterBody2D:
        var instance_id = body.get_instance_id()
        if _original_colors.has(instance_id):
            # Khôi phục màu gốc hoàn toàn
            body.modulate = _original_colors[instance_id]
            _original_colors.erase(instance_id)