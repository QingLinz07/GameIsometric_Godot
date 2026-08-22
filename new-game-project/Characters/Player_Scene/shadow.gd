extends Node2D

@export var ban_kinh: float = 16.0
@export var mau_sac: Color = Color(0, 0, 0, 0.4) # Màu đen, độ mờ 40%

# Thêm 2 biến chỉnh kích thước ngang/dọc trực tiếp ở Inspector
@export var scale_x: float = 1.2:
    set(value):
        scale_x = value
        queue_redraw() # Tự động vẽ lại khi thay đổi thông số

@export var scale_y: float = 0.7:
    set(value):
        scale_y = value
        queue_redraw() # Tự động vẽ lại khi thay đổi thông số

func _ready() -> void:
    queue_redraw()

func _process(_delta: float) -> void:
    if z_index != 1: # Hoặc giá trị bạn mong muốn
        z_index = 1

func _draw() -> void:
    # Dùng draw_set_transform để co giãn hình tròn trực tiếp khi vẽ
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale_x, scale_y))
    draw_circle(Vector2.ZERO, ban_kinh, mau_sac)