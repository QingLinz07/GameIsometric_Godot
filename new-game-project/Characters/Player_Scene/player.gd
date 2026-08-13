extends CharacterBody2D

var stats_ui: StatsUI
var health = load("res://Core/HealthSystem.cs").new()
const STATS_UI_SCENE = preload("res://UI/Stats_UI/Stats_UI.tscn")

@export var player_name: String = "":
	set(value):
		player_name = value
		if is_inside_tree() and has_node("Nametag"):
			$Nametag.update_nametag(player_name, name, true)

@export var speed: float = 200.0
@export var turn_smoothness: float = 22.0  

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Node2D = $Shadow # <-- Thêm tham chiếu đến node bóng

@export var last_direction_name: String = "Down"
var anim_move_dir: Vector2 = Vector2.ZERO

@export var username: String = "Player_1"

# Định nghĩa vị trí lệch của bóng tương ứng với 8 hướng nhìn của bạn
const SHADOW_OFFSETS = {
	"Right":      Vector2(0, 30),
	"Down_Right": Vector2(0, 30),
	"Down":       Vector2(0, 30),
	"Down_Left":  Vector2(0, 30),
	"Left":       Vector2(0, 30),
	"Up_Left":    Vector2(0, 30),
	"Up":         Vector2(0, 30),
	"Up_Right":   Vector2(0, 30)
}
# Các Biến Lưu Dữ Liệu Nhân Vật
var current_hp = GameManager.current_player_data.get("hp",)
var max_hp = GameManager.current_player_data.get("max_hp")


func _ready() -> void:
	stats_ui = STATS_UI_SCENE.instantiate() as StatsUI
	add_child(stats_ui)
	
	health.Initialize(max_hp, current_hp)
	SavePlayerPos.setup_tracking(player_name, self)
	
	if has_node("Camera2D"):
		$Camera2D.make_current()
			
	play_stand_animation()
	
	# Đặt z_index của bóng thấp hơn nhân vật để bóng luôn ở phía sau chân
	if shadow:
		shadow.z_index = -1
	
	await get_tree().process_frame
	if has_node("Nametag"):
		$Nametag.update_nametag(player_name, name, true)

func _physics_process(delta: float) -> void:
	# Lấy input 8 hướng từ bàn phím (WASD hoặc phím mũi tên)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
		move_and_slide()
		
		# Cập nhật hướng animation mượt mà
		if anim_move_dir == Vector2.ZERO:
			anim_move_dir = input_dir
		else:
			anim_move_dir = anim_move_dir.slerp(input_dir, turn_smoothness * delta).normalized()
			
		var new_dir_name = get_8way_direction_name(anim_move_dir)
		if new_dir_name != last_direction_name or sprite.animation != "Walk_" + new_dir_name:
			last_direction_name = new_dir_name
			sprite.play("Walk_" + last_direction_name)
			update_shadow_position(last_direction_name) # Cập nhật bóng khi đổi hướng
	else:
		velocity = Vector2.ZERO
		stop_movement()

func stop_movement() -> void:
	anim_move_dir = Vector2.ZERO
	velocity = Vector2.ZERO
	play_stand_animation()

func play_stand_animation() -> void:
	var stand_anim_name = "Stand_" + last_direction_name
	if sprite.animation != stand_anim_name:
		sprite.play(stand_anim_name)
		update_shadow_position(last_direction_name) # Cập nhật bóng khi đứng lại

# Hàm cập nhật vị trí bóng mượt mà bằng Tween
func update_shadow_position(dir_name: String) -> void:
	if shadow and SHADOW_OFFSETS.has(dir_name):
		var tween = create_tween()
		tween.tween_property(shadow, "position", SHADOW_OFFSETS[dir_name], 0.15)
		tween.set_trans(Tween.TRANS_SINE)

# Tối ưu hóa: Nới rộng vùng góc cho các hướng chéo (Diagonal) lên 60 độ 
# thay vì chia đều cứng nhắc 45 độ, giúp thao tác di chuyển chéo bắt animation chuẩn hơn.
func get_8way_direction_name(dir: Vector2) -> String:
	var angle = posmod(rad_to_deg(dir.angle()), 360.0)
	
	if angle >= 330.0 or angle < 30.0:
		return "Right"
	elif angle >= 30.0 and angle < 120.0:
		return "Down_Right" if angle < 75.0 else "Down" 
	elif angle >= 120.0 and angle < 150.0:
		return "Down_Left"
	elif angle >= 150.0 and angle < 210.0:
		return "Left"
	elif angle >= 210.0 and angle < 300.0:
		return "Up_Left" if angle < 255.0 else "Up" 
	else:
		return "Up_Right"

func CongMau(amount: float):
	health.CongMau(amount)
	# Lấy current_hp mới nhất từ thăng health truyền qua cho UI
	stats_ui._update_hp_bar(health.current_hp, health.max_hp)
	
func TruMau(amount: float):
	health.TruMau(amount)
	# Lấy current_hp mới nhất từ thằng health truyền qua cho UI
	stats_ui._update_hp_bar(health.current_hp, health.max_hp)
	
func _input(event):
	# Kiểm tra xem có bấm phím H trên bàn phím không
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			print("Đang test lệnh: Cộng 20 máu!")
			CongMau(20) # Gọi trực tiếp hàm cộng máu khi đang chơi
