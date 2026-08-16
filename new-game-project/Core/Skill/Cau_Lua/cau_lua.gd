extends Area2D

@export var speed: float = 400.0
@export var max_range: float = 200.0 # <--- Tầm đánh tối đa (đơn vị pixel)

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0 # <--- Biến lưu quãng đường đã bay

func initialize(dir: Vector2) -> void:
	direction = dir
	rotation = direction.angle()

func _ready() -> void:
	$AnimatedSprite2D.play("Skill")
	
	# Kết nối sự kiện va chạm (nếu bạn chưa có)
	#body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var move_distance = speed * delta
	global_position += direction * move_distance
	
	# Cộng dồn quãng đường đã bay
	distance_traveled += move_distance
	
	# Kiểm tra nếu bay quá tầm thì hủy
	if distance_traveled >= max_range:
		queue_free()

# Xử lý khi va chạm vào kẻ địch
func _on_body_entered(_body: Node2D) -> void:
	# Ở đây bạn viết code gây sát thương cho kẻ địch
	# Sau khi gây sát thương xong thì gọi queue_free()
	queue_free()