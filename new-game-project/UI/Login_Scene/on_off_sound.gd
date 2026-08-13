extends Button

var enable_sound: bool = true
var icon_on = preload("res://UI/Login_Scene/intro/bat_loa.png")   # Ảnh lúc bật
var icon_off = preload("res://UI/Login_Scene/intro/tat_loa.png")  # Ảnh lúc tắt

func _ready():
	pressed.connect(_on_button_pressed)
	icon = icon_on

func _on_button_pressed():
	enable_sound = not enable_sound
	
	# Lấy chỉ mục (index) của bus "VideoBus"
	var bus_index = AudioServer.get_bus_index("IntroBus")
	
	if enable_sound:
		# Bật lại tiếng của bus video
		AudioServer.set_bus_mute(bus_index, false)
		icon = icon_on
	else:
		# Tắt tiếng hoàn toàn bus video mà không làm dừng video
		AudioServer.set_bus_mute(bus_index, true)
		icon = icon_off
