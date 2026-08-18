extends Node
class_name SkillBar

@onready var h_box_container: HBoxContainer = $CanvasLayer/SkillBar/HBoxContainer
var equipped_skills: Array = []
var player_ref: Node2D = null

# Danh sách icon tương ứng với từng đường dẫn skill
var skill_icons = {
	"res://Core/Skill/Skill_Tam_Xa/Cau_Lua/Cau_Lua.tscn": preload("res://Core/Skill/Skill_Tam_Xa/Cau_Lua/Asset/frame_3.png")
}

func _ready() -> void:
	equipped_skills.resize(6)
	equipped_skills[0] = load("res://Core/Skill/Skill_Tam_Xa/Cau_Lua/Cau_Lua.tscn")
	setup_slots()
	update_skill_bar_ui()

func setup_slots() -> void:
	for i in range(h_box_container.get_child_count()):
		var slot = h_box_container.get_child(i)
		slot.set_meta("slot_index", i)

# --- 1. KÉO (DRAG) & HIỂN THỊ ICON DÍNH CHUỘT ---
func _get_drag_data(_at_position: Vector2, control: Control) -> Variant:
	var idx = control.get_meta("slot_index")
	if equipped_skills[idx] == null:
		return null
	
	# Lấy icon từ ô đang kéo để làm preview dính theo chuột
	var icon_rect = control.get_node("TextureRect") as TextureRect
	if not icon_rect or not icon_rect.texture:
		return null
		
	# Tạo preview mượt mà di chuyển theo chuột
	var preview = TextureRect.new()
	preview.texture = icon_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.custom_minimum_size = Vector2(48, 48)
	preview.size = Vector2(48, 48)
	
	# Căn tâm icon nằm ngay giữa trỏ chuột
	preview.position = - Vector2(24, 24)
	
	var wrapper = Control.new()
	wrapper.add_child(preview)
	
	# Đưa preview vào hệ thống kéo thả của Godot để bám theo chuột
	set_deferred("set_drag_preview", wrapper)
	
	# Làm mờ icon ở ô gốc tạo hiệu ứng "bóc" skill ra khỏi slot
	icon_rect.modulate.a = 0.3
	
	return {"from_index": idx}

# Khôi phục lại độ trong suốt của icon gốc khi kết thúc kéo thả
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		for slot in h_box_container.get_children():
			var icon = slot.get_node_or_null("TextureRect")
			if icon:
				icon.modulate.a = 1.0

# --- 2. KIỂM TRA THẢ (DROP) ---
func _can_drop_data(_at_position: Vector2, data: Variant, _control: Control) -> bool:
	return data is Dictionary and data.has("from_index")

# --- 3. XỬ LÝ KHI THẢ (DROP) & HIỆU ỨNG BAY CHÉO ---
func _drop_data(_at_position: Vector2, data: Variant, control: Control) -> void:
	var from_index = data["from_index"]
	var to_index = control.get_meta("slot_index")
	
	if from_index == to_index:
		return
	
	var slots = h_box_container.get_children()
	var start_node = slots[from_index].get_node("TextureRect") as TextureRect
	var end_node = slots[to_index].get_node("TextureRect") as TextureRect
	
	var icon_from_tex = start_node.texture
	var icon_to_tex = end_node.texture
	
	# Hoán đổi dữ liệu trong mảng skill
	var temp = equipped_skills[from_index]
	equipped_skills[from_index] = equipped_skills[to_index]
	equipped_skills[to_index] = temp
	
	# Tạm ẩn icon gốc để nhường chỗ cho animation bay
	start_node.visible = false
	end_node.visible = false
	
	# Chạy hiệu ứng bay đổi chỗ chuyên nghiệp
	animate_swap(slots[from_index].global_position, slots[to_index].global_position, icon_from_tex, icon_to_tex)

func animate_swap(start_pos: Vector2, end_pos: Vector2, tex_from: Texture, tex_to: Texture):
	var canvas_layer = $CanvasLayer # Đặt trên cùng qua CanvasLayer để không bị che khuất
	
	var icon1 = TextureRect.new()
	icon1.texture = tex_from
	icon1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon1.stretch_mode = TextureRect.STRETCH_SCALE
	icon1.custom_minimum_size = Vector2(48, 48)
	icon1.size = Vector2(48, 48)
	icon1.global_position = start_pos
	canvas_layer.add_child(icon1)
	
	var icon2 = TextureRect.new()
	icon2.texture = tex_to
	icon2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon2.stretch_mode = TextureRect.STRETCH_SCALE
	icon2.custom_minimum_size = Vector2(48, 48)
	icon2.size = Vector2(48, 48)
	icon2.global_position = end_pos
	canvas_layer.add_child(icon2)
	
	# Dùng Tween di chuyển mượt mà
	var tween = create_tween().set_parallel(true)
	tween.tween_property(icon1, "global_position", end_pos, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon2, "global_position", start_pos, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Xóa icon tạm và load lại UI chuẩn sau khi bay xong
	tween.chain().tween_callback(func():
		icon1.queue_free()
		icon2.queue_free()
		update_skill_bar_ui()
	)

# --- 4. HỆ THỐNG DÙNG SKILL ---
func use_skill(slot_index: int) -> void:
	var skill_scene = equipped_skills[slot_index]
	if not skill_scene or not player_ref:
		return
	
	var skill_instance = skill_scene.instantiate()
	skill_instance.global_position = player_ref.global_position
	
	# Xác định chính xác 8 hướng từ animation của player
	var look_dir = Vector2.RIGHT
	var sprite = player_ref.get_node_or_null("AnimatedSprite2D")
	if sprite:
		var anim_name = sprite.animation # Ví dụ: Walk_Down_Right hoặc Stand_Right
		
		if "Down_Right" in anim_name: look_dir = Vector2(1, 1).normalized()
		elif "Down_Left" in anim_name: look_dir = Vector2(-1, 1).normalized()
		elif "Up_Right" in anim_name: look_dir = Vector2(1, -1).normalized()
		elif "Up_Left" in anim_name: look_dir = Vector2(-1, -1).normalized()
		elif "Right" in anim_name: look_dir = Vector2.RIGHT
		elif "Left" in anim_name: look_dir = Vector2.LEFT
		elif "Up" in anim_name: look_dir = Vector2.UP
		elif "Down" in anim_name: look_dir = Vector2.DOWN
	
	if skill_instance.has_method("Initialize"):
		skill_instance.Initialize(look_dir)
		
	get_tree().current_scene.add_child(skill_instance)

# --- 5. CẬP NHẬT GIAO DIỆN UI ---
func update_skill_bar_ui() -> void:
	for i in range(h_box_container.get_child_count()):
		var slot = h_box_container.get_child(i)
		var icon_rect = slot.get_node_or_null("TextureRect") as TextureRect
		if not icon_rect:
			continue
			
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
		
		var skill = equipped_skills[i]
		if skill:
			var scene_path = skill.resource_path
			if skill_icons.has(scene_path):
				icon_rect.texture = skill_icons[scene_path]
			icon_rect.visible = true
			icon_rect.modulate.a = 1.0
		else:
			icon_rect.texture = null
			icon_rect.visible = false
