extends Control

var target_scene_path: String = "res://Main/Main.tscn"
@onready var progress_bar: ProgressBar = $ProgressBar 

var progress_array: Array = []
var is_transitioning: bool = false

func _ready() -> void:
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	
	# Bắt đầu yêu cầu load ngầm
	ResourceLoader.load_threaded_request(target_scene_path)

func _process(_delta: float) -> void:
	if is_transitioning:
		return
		
	# Lấy trạng thái và tiến độ load (progress_array[0] trả về từ 0.0 đến 1.0)
	var load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress_array)
	
	if progress_array.size() > 0:
		progress_bar.value = progress_array[0] * 100.0
	
	# Khi load xong thì chuyển scene
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		is_transitioning = true
		set_process(false)
		transition_to_game()
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		# Báo lỗi nếu load thất bại
		set_process(false)
		print("Lỗi: Không thể load scene!")

func transition_to_game() -> void:
	progress_bar.value = 100.0
	await get_tree().create_timer(0.1).timeout
	
	var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	else:
		get_tree().change_scene_to_file(target_scene_path)
