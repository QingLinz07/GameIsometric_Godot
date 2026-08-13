extends CharacterBody2D

var stats_ui: StatsUI
var health = load("res://Core/HealthSystem.cs").new()
var stamina = load("res://Core/StaminaSystem.cs").new()
var movement = load("res://Core/PlayerMovement.cs").new()
const STATS_UI_SCENE = preload("res://UI/Stats_UI/Stats_UI.tscn")

@export var player_name: String = "":
	set(value):
		player_name = value
		if is_inside_tree() and has_node("Nametag"):
			$Nametag.update_nametag(player_name, name, true)

@export var speed: float = 200.0
@export var turn_smoothness: float = 22.0  

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Node2D = $Shadow

@export var username: String = "Player_1"

# Khai báo biến gọi đối tượng di chuyển từ C#


# Các Biến Lưu Dữ Liệu Nhân Vật
var current_hp = GameManager.current_player_data.get("hp", 100)
var max_hp = GameManager.current_player_data.get("max_hp", 100)

var current_stamina = GameManager.current_player_data.get("stamina", 100)
var max_stamina = GameManager.current_player_data.get("max_stamina", 100)

func _ready() -> void:
	# Khởi tạo PlayerMovement viết bằng C#
	movement.PlayerMovementCreate(self, sprite, shadow, speed, turn_smoothness)
	
	stats_ui = STATS_UI_SCENE.instantiate() as StatsUI
	add_child(stats_ui)

	
	stamina.Initialize(max_stamina, current_stamina)
	health.Initialize(max_hp, current_hp)
	SavePlayerPos.setup_tracking(player_name, self)
	
	if has_node("Camera2D"):
		$Camera2D.make_current()
			
	movement.PlayStandAnimation()
	
	if shadow:
		shadow.z_index = -1
	
	await get_tree().process_frame
	if has_node("Nametag"):
		$Nametag.update_nametag(player_name, name, true)

func _physics_process(delta: float) -> void:
	movement.HandlePhysics(delta)

func CongMau(amount: float):
	health.CongMau(amount)
	stats_ui._update_hp_bar(health.current_hp, health.max_hp)
	
func TruMau(amount: float):
	health.TruMau(amount)
	stats_ui._update_hp_bar(health.current_hp, health.max_hp)

func CongStamina(amount: float):
	stamina.CongStamina(amount)
	stats_ui._update_stamina_bar(stamina.current_stamina, stamina.max_stamina)	

func TruStamina(amount: float):
	stamina.TruStamina(amount)
	stats_ui._update_stamina_bar(stamina.current_stamina, stamina.max_stamina)	
	
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			print("Đang test lệnh: Cộng 20 máu!")
			CongMau(50)
		if event.keycode == KEY_J:
			print("Đang test lệnh: Trừ 20 stamina!")
			TruStamina(20)	
