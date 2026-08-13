extends Node
class_name StatsUI

@onready var name_label: Label = $CanvasLayer/Name
@onready var level_label: Label = $CanvasLayer/Level
@onready var hp_label: Label = $CanvasLayer/Hp_Label
@onready var hp_progressbar: ProgressBar = $CanvasLayer/Hp
@onready var stamina_progressbar: ProgressBar = $CanvasLayer/Stamina
@onready var stamina_label: Label = $CanvasLayer/Stamina_Label

# Tách riêng 2 StyleBox cho HP và Stamina
var hp_fill_style = StyleBoxFlat.new()
var stamina_fill_style = StyleBoxFlat.new()

func _ready() -> void:
    hp_bar_style()
    stamina_bar_style()
    
    var player_hp = float(GameManager.current_player_data.get("hp", 100))
    var max_hp = float(GameManager.current_player_data.get("max_hp", 100))

    var player_stamina = float(GameManager.current_player_data.get("stamina", 100))
    var max_stamina = float(GameManager.current_player_data.get("max_stamina", 100))
    
    var player_name = GameManager.current_player_data.get("character_name", "Player")
    name_label.text = player_name
    
    var player_level = GameManager.current_player_data.get("level", 1)
    level_label.text = "Level: " + str(int(player_level))
    
    _update_hp_bar(player_hp, max_hp)
    _update_stamina_bar(player_stamina, max_stamina)

func hp_bar_style() -> void:
    hp_fill_style.bg_color = Color(1.0, 0.0, 0.0, 1.0) # Màu đỏ cho thanh máu
    hp_progressbar.add_theme_stylebox_override("fill", hp_fill_style)

func stamina_bar_style() -> void:
    # Sửa lại giá trị màu trong khoảng 0.0 -> 1.0 (hoặc dùng Color.html("#hex"))
    stamina_fill_style.bg_color = Color(0.06, 0.2, 0.56, 0.8) # Màu xanh lam cho thanh stamina
    stamina_progressbar.add_theme_stylebox_override("fill", stamina_fill_style)

func _update_hp_bar(current_hp: float, max_hp: float) -> void:
    if max_hp <= 0:
        hp_progressbar.value = 0
        return
        
    var hp_percent = (current_hp / max_hp) * 100.0
    hp_progressbar.value = hp_percent
    hp_label.text = str(current_hp) + "/" + str(max_hp)
    
    if hp_progressbar.value >= 97.23:
        hp_fill_style.corner_radius_bottom_right = 150
        return
    else: 
        hp_fill_style.corner_radius_bottom_right = 0

func _update_stamina_bar(current_stamina: float, max_stamina: float) -> void:
    if max_stamina <= 0:
        stamina_progressbar.value = 0
        return
        
    var stamina_percent = (current_stamina / max_stamina) * 100.0
    stamina_progressbar.value = stamina_percent
    stamina_label.text = str(current_stamina) + "/" + str(max_stamina)

    if stamina_progressbar.value >= 67.21:
        stamina_fill_style.corner_radius_bottom_right = 150
        return
    else: 
        stamina_fill_style.corner_radius_bottom_right = 0