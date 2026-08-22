extends CharacterBody2D

var stats_ui: StatsUI
var skill_bar: SkillBar

var health = load("res://Core/HealthSystem.cs").new()
var stamina = load("res://Core/StaminaSystem.cs").new()
var movement = load("res://Core/PlayerMovement.cs").new()
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D # Thêm dòng này để gọi node Agent
const STATS_UI_SCENE = preload("res://UI/Stats_UI/Stats_UI.tscn")
const SKILL_BAR_SCENE = preload("res://UI/Skill_Bar/Skill_Bar.tscn")

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

@export var inventory_ui: Control # Thay "/root/MainScene/InventoryUI"
const Binh_Mau_Nho = preload("res://Inventory/Item/Item_Tri_Lieu/BinhMauNho/BinhMauNho.tres")

# Các Biến Lưu Dữ Liệu Nhân Vật
var current_hp = GameManager.current_player_data.get("hp", 100)
var max_hp = GameManager.current_player_data.get("max_hp", 100)

var current_stamina = GameManager.current_player_data.get("stamina", 100)
var max_stamina = GameManager.current_player_data.get("max_stamina", 100)


func _ready() -> void:
	PlayerManager.current_player = self
	# Truyền thêm nav_agent vào script C#
	movement.PlayerMovementCreate(self, sprite, shadow, nav_agent, speed, turn_smoothness)
	
	# Khởi tạo giao diện StatsUI
	stats_ui = STATS_UI_SCENE.instantiate() as StatsUI
	add_child(stats_ui)

	# Khởi tạo giao diện SkillBar
	skill_bar = SKILL_BAR_SCENE.instantiate() as SkillBar
	skill_bar.player_ref = self
	add_child(skill_bar)

	stamina.Initialize(max_stamina, current_stamina)
	health.Initialize(max_hp, current_hp)
	#SavePlayerPos.setup_tracking(player_name, self)
	
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
	movement.HandleInput(event)

	if event is InputEventKey and event.pressed and not event.echo:
		# Kiểm tra từng phím một cách độc lập
		if event.is_action_pressed("skill_1"):
			_trigger_skill(0)
		elif event.is_action_pressed("skill_2"):
			_trigger_skill(1)
		elif event.is_action_pressed("skill_3"):
			_trigger_skill(2)
		elif event.is_action_pressed("skill_4"):
			_trigger_skill(3)
		elif event.is_action_pressed("skill_5"):
			_trigger_skill(4)
		elif event.is_action_pressed("skill_6"):
			_trigger_skill(5)
		
		# Các phím test cũ
		elif event.keycode == KEY_H:
			# Tìm node InventoryUI ngay lúc bấm phím bằng đường dẫn hoặc nhóm
			var inv = get_tree().get_first_node_in_group("InventoryUI")
			if inv != null and inv.has_method("AddItem"):
				inv.AddItem(Binh_Mau_Nho, 3)
				print("Đã thêm 3 bình máu nhỏ vào túi đồ từ GDScript!")
			else:
				print("Lỗi: Không tìm thấy node InventoryUI trong group hoặc chưa add vào group 'InventoryUI'!")
		elif event.keycode == KEY_J:
			TruStamina(20)

# Hàm phụ để gọi cho gọn
func _trigger_skill(index: int):
	if skill_bar:
		#print("Đang gọi skill tại ô: ", index + 1)
		skill_bar.use_skill(index)
