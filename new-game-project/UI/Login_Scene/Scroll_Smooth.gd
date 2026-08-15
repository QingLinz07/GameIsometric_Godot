extends ScrollContainer

@export var scroll_speed: float = 15.0     # Tốc độ mượt của cuộn (càng cao càng nhanh)
@export var scroll_step: float = 80.0     # Độ dài mỗi lần lăn chuột

var target_vertical_scroll: float = 0.0

func _ready() -> void:
	# Khởi tạo vị trí đích ban đầu bằng vị trí thực tế
	target_vertical_scroll = scroll_vertical

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			# Lăn chuột lên
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				target_vertical_scroll -= scroll_step
				accept_event() # Chặn sự kiện mặc định để dùng hiệu ứng mượt
			# Lăn chuột xuống
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				target_vertical_scroll += scroll_step
				accept_event()

	# Giới hạn vị trí cuộn không vượt quá min/max của thanh cuộn
	var v_bar = get_v_scroll_bar()
	target_vertical_scroll = clamp(target_vertical_scroll, v_bar.min_value, v_bar.max_value)

func _process(delta: float) -> void:
	# Nội suy (Lerp) giá trị hiện tại về giá trị đích để tạo độ mượt
	if not is_equal_approx(float(scroll_vertical), target_vertical_scroll):
		scroll_vertical = int(lerp(float(scroll_vertical), target_vertical_scroll, scroll_speed * delta))