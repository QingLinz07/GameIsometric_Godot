extends Node

var current_scene: Node = null

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

# Hàm chuyển scene chính tự động xóa scene cũ
func change_scene(path: String) -> void:
	_deferred_change_scene.call_deferred(path)

func _deferred_change_scene(path: String) -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free() # Tự động xóa scene cũ khỏi RAM
		current_scene = null
	
	var s = load(path)
	if s:
		current_scene = s.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene

# --- HÀM MỚI: CHỈ ĐÍCH DANH ĐƯỜNG DẪN ĐỂ "CHO CÚT" MỘT SCENE BẤT KỲ ---
func unload_scene_by_path(scene_path: String) -> void:
	var root = get_tree().root
	# Duyệt qua các con nằm ở root (nơi chứa các scene chính hoặc canvas layer lớn)
	for child in root.get_children():
		# Kiểm tra xem node đó có thuộc tính 'scene_file_path' và khớp với đường dẫn không
		if child.scene_file_path == scene_path:
			if is_instance_valid(child):
				print("[SceneManager] Đang cho cút scene theo yêu cầu: ", scene_path)
				child.queue_free()
				# Nếu scene bị xóa đúng là current_scene thì gán lại bằng null
				if child == current_scene:
					current_scene = null
				return
	print("[SceneManager] Không tìm thấy scene nào có đường dẫn: ", scene_path)