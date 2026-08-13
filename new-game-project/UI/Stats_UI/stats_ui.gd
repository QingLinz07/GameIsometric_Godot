extends Node
class_name StatsUI

@onready var name_label: Label = $CanvasLayer/Name
@onready var level_label: Label = $CanvasLayer/Level
@onready var hp_label: Label = $CanvasLayer/Hp_Label
@onready var hp_progressbar: ProgressBar = $CanvasLayer/Hp
@onready var stamina_progressbar: ProgressBar = $CanvasLayer/Stamina
@onready var stamina_label: Label = $CanvasLayer/Stamina_Label

# Biến lưu trữ giá trị trên RAM
var player_hp = GameManager.current_player_data.get("hp", 100)
var player_max_hp = GameManager.current_player_data.get("max_hp", 100)
var player_stamina = GameManager.current_player_data.get("stamina", 100)
var player_max_stamina = GameManager.current_player_data.get("max_stamina", 100)

var current_hp_cache: float = 0.0
var max_hp_cache: float = 0.0
var current_stamina_cache: float = 0.0
var max_stamina_cache: float = 0.0

# Cờ chống lặp vô hạn
var is_updating: bool = false

func _ready() -> void:    
	name_label.text = GameManager.current_player_data.get("character_name", "Player")
	level_label.text = str(int(GameManager.current_player_data.get("level", 1)))
	
	# Khởi tạo đầy đủ cả HP và Stamina ngay từ đầu để tránh lỗi render thanh fill
	_update_hp_bar(player_hp, player_max_hp)
	_update_stamina_bar(player_stamina, player_max_stamina)


# --- HÀM VẼ LẠI TOÀN BỘ GIAO DIỆN ---
func update_stats_ui() -> void:
	if is_updating:
		return
	is_updating = true
   
	# --- Vẽ lại thanh HP ---
	if max_hp_cache <= 0:
		hp_progressbar.max_value = 1
		hp_progressbar.value = 0
		hp_label.text = "0/0"
	else:
		hp_progressbar.max_value = max_hp_cache
		hp_progressbar.value = clamp(current_hp_cache, 0, max_hp_cache)
		hp_label.text = str(int(current_hp_cache)) + "/" + str(int(max_hp_cache))
   
	# Ép refresh lại hiển thị (sửa chữ visable thành visible)
	hp_progressbar.visible = false
	hp_progressbar.visible = true

	# --- Vẽ lại thanh Stamina ---
	if max_stamina_cache <= 0:
		stamina_progressbar.max_value = 1
		stamina_progressbar.value = 0
		stamina_label.text = "0/0"
	else:
		stamina_progressbar.max_value = max_stamina_cache
		stamina_progressbar.value = clamp(current_stamina_cache, 0, max_stamina_cache)
		stamina_label.text = str(int(current_stamina_cache)) + "/" + str(int(max_stamina_cache))
	   
	# Ép refresh lại hiển thị cho Stamina
	stamina_progressbar.visible = false
	stamina_progressbar.visible = true

	is_updating = false

# --- HÀM UPDATE HP ---
func _update_hp_bar(current_hp: float, max_hp: float) -> void:
	current_hp_cache = current_hp
	max_hp_cache = max_hp
	update_stats_ui()

# --- HÀM UPDATE STAMINA ---
func _update_stamina_bar(current_stamina: float, max_stamina: float) -> void:
	current_stamina_cache = current_stamina
	max_stamina_cache = max_stamina
	update_stats_ui()
