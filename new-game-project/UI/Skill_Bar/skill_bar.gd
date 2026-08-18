extends Node
class_name SkillBar

@onready var h_box_container: HBoxContainer = $CanvasLayer/SkillBar/HBoxContainer
var equipped_skills: Array = []
var skill_cooldown_timers: Array = []
var max_cooldowns: Array = []
var player_ref: Node2D = null

# Danh sách icon tương ứng với từng đường dẫn skill
var skill_icons = {
	"res://Core/Skill/Skill_Tam_Xa/Cau_Lua/Cau_Lua.tscn": preload("res://Core/Skill/Skill_Tam_Xa/Cau_Lua/Asset/frame_3.png")
}

func _ready() -> void:
	equipped_skills.resize(6)
	skill_cooldown_timers.resize(6)
	skill_cooldown_timers.fill(0.0)
	max_cooldowns.resize(6)
	max_cooldowns.fill(1.0)
	
	equipped_skills[0] = load("res://Core/Skill/Skill_Tam_Xa/Cau_Lua/Cau_Lua.tscn")
	setup_slots()
	update_skill_bar_ui()

func _process(delta: float) -> void:
	for i in range(skill_cooldown_timers.size()):
		if skill_cooldown_timers[i] > 0:
			skill_cooldown_timers[i] -= delta
			if skill_cooldown_timers[i] < 0:
				skill_cooldown_timers[i] = 0.0
			
			# Cập nhật UI và yêu cầu vẽ lại hiệu ứng quạt
			update_slot_cooldown_ui(i)
		elif skill_cooldown_timers[i] == 0.0 and get_slot_cooldown_ui_active(i):
			update_slot_cooldown_ui(i)

func setup_slots() -> void:
	for i in range(h_box_container.get_child_count()):
		var slot = h_box_container.get_child(i)
		slot.set_meta("slot_index", i)
		slot.set_meta("cooldown_progress", 0.0)
		
		# Tạo một Control con chuyên biệt để vẽ hiệu ứng quạt xoay tròn giống MOBA
		if not slot.has_node("CooldownPieDrawer"):
			var pie_drawer = Control.new()
			pie_drawer.name = "CooldownPieDrawer"
			pie_drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pie_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(pie_drawer)
			
			# Gắn logic vẽ trực tiếp bằng phương thức lambda draw
			pie_drawer.draw.connect(func():
				var prog = slot.get_meta("cooldown_progress", 0.0)
				if prog <= 0:
					return
				
				var center = pie_drawer.size / 2.0
				var radius = max(center.x, center.y) * 1.5
				var points = PackedVector2Array()
				points.append(center)
				
				# Góc quét từ -90 độ (đỉnh) quay theo chiều kim đồng hồ
				var start_angle = - PI / 2.0
				var end_angle = start_angle + (prog * 2.0 * PI)
				var num_points = 32
				
				for p in range(num_points + 1):
					var angle = lerp(start_angle, end_angle, float(p) / float(num_points))
					points.append(center + Vector2(cos(angle), sin(angle)) * radius)
				
				# Vẽ vùng quạt tối màu đè lên icon
				pie_drawer.draw_polygon(points, PackedColorArray([Color(0, 0, 0, 0.65)]))
			)

		# Tạo Label hiển thị số giây căn giữa chuẩn tuyệt đối
		if not slot.has_node("CooldownLabel"):
			var label = Label.new()
			label.name = "CooldownLabel"
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 5)
			
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.visible = false
			slot.add_child(label)

func get_slot_cooldown_ui_active(slot_index: int) -> bool:
	var slot = h_box_container.get_child(slot_index)
	var label = slot.get_node_or_null("CooldownLabel") as Label
	return label and label.visible

# --- 1. KÉO (DRAG) & HIỂN THỊ ICON DÍNH CHUỘT ---
func _get_drag_data(_at_position: Vector2, control: Control) -> Variant:
	var idx = control.get_meta("slot_index")
	if equipped_skills[idx] == null:
		return null
	
	var icon_rect = control.get_node("TextureRect") as TextureRect
	if not icon_rect or not icon_rect.texture:
		return null
		
	var preview = TextureRect.new()
	preview.texture = icon_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.custom_minimum_size = Vector2(64, 64)
	preview.size = Vector2(64, 64)
	preview.position = - Vector2(32, 32)
	
	var wrapper = Control.new()
	wrapper.add_child(preview)
	
	set_deferred("set_drag_preview", wrapper)
	icon_rect.modulate.a = 0.3
	
	return {"from_index": idx}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		for slot in h_box_container.get_children():
			var icon = slot.get_node_or_null("TextureRect")
			if icon:
				icon.modulate.a = 1.0

# --- 2. KIỂM TRA THẢ (DROP) ---
func _can_drop_data(_at_position: Vector2, data: Variant, _control: Control) -> bool:
	return data is Dictionary and data.has("from_index")

# --- 3. XỬ LÝ KHI THẢ (DROP) & HOÁN ĐỔI ---
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
	
	var temp_skill = equipped_skills[from_index]
	equipped_skills[from_index] = equipped_skills[to_index]
	equipped_skills[to_index] = temp_skill
	
	var temp_cooldown = skill_cooldown_timers[from_index]
	skill_cooldown_timers[from_index] = skill_cooldown_timers[to_index]
	skill_cooldown_timers[to_index] = temp_cooldown
	
	var temp_max = max_cooldowns[from_index]
	max_cooldowns[from_index] = max_cooldowns[to_index]
	max_cooldowns[to_index] = temp_max
	
	start_node.visible = false
	end_node.visible = false
	
	animate_swap(slots[from_index].global_position, slots[to_index].global_position, icon_from_tex, icon_to_tex)

func animate_swap(start_pos: Vector2, end_pos: Vector2, tex_from: Texture, tex_to: Texture):
	var canvas_layer = $CanvasLayer
	
	var icon1 = create_temp_icon(tex_from, start_pos)
	var icon2 = create_temp_icon(tex_to, end_pos)
	canvas_layer.add_child(icon1)
	canvas_layer.add_child(icon2)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(icon1, "global_position", end_pos, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon2, "global_position", start_pos, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(func():
		icon1.queue_free()
		icon2.queue_free()
		update_skill_bar_ui()
	)

func create_temp_icon(tex: Texture, pos: Vector2) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size = Vector2(64, 64)
	icon.global_position = pos
	return icon

# --- 4. HỆ THỐNG DÙNG SKILL ---
func use_skill(slot_index: int) -> void:
	var skill_scene = equipped_skills[slot_index]
	if not skill_scene or not player_ref:
		return
	
	if skill_cooldown_timers[slot_index] > 0:
		return
	
	var skill_instance = skill_scene.instantiate()
	
	#Kiểm tra Stamina của Skill và Stamina của người chơi
	var skill_stamina = 0.0
	if "Stamina" in skill_instance:
		skill_stamina = skill_instance.Stamina

	var player_stamina = PlayerManager.stamina

	if (player_stamina >= skill_stamina):
		PlayerManager.TruStamina(skill_stamina)
		var max_cd = 1.0
		if "Cooldown" in skill_instance:
			max_cd = skill_instance.Cooldown
		
		skill_cooldown_timers[slot_index] = max_cd
		max_cooldowns[slot_index] = max_cd
		
		skill_instance.global_position = player_ref.global_position
		
		var look_dir = Vector2.RIGHT
		var sprite = player_ref.get_node_or_null("AnimatedSprite2D")
		if sprite:
			var anim_name = sprite.animation
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
		update_slot_cooldown_ui(slot_index)

	else: print("Khong du stamina")

# --- 5. CẬP NHẬT GIAO DIỆN UI & VẼ HIỆU ỨNG QUẠT (SWEEP) ---
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
			
		update_slot_cooldown_ui(i)

func update_slot_cooldown_ui(slot_index: int) -> void:
	var slot = h_box_container.get_child(slot_index)
	var icon_rect = slot.get_node_or_null("TextureRect") as TextureRect
	var label = slot.get_node_or_null("CooldownLabel") as Label
	
	if not icon_rect:
		return
		
	var current_cd = skill_cooldown_timers[slot_index]
	var max_cd = max_cooldowns[slot_index]
	
	if current_cd > 0:
		icon_rect.modulate = Color(0.4, 0.4, 0.4, 1.0)
		if label:
			label.visible = true
			if current_cd < 1.0:
				label.text = "%.1f" % current_cd
			else:
				label.text = "%d" % ceil(current_cd)
		
		# Lưu dữ liệu tính toán quạt trực tiếp vào slot để vẽ
		slot.set_meta("cooldown_progress", current_cd / max_cd)
		slot.queue_redraw() # Yêu cầu gọi hàm _draw() của slot
	else:
		icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if label: label.visible = false
		slot.set_meta("cooldown_progress", 0.0)
		slot.queue_redraw()

# Bổ sung hàm _draw tự động cho các slot thông qua kịch bản gắn thêm hoặc xử lý vẽ đè
# Để Godot gọi hàm vẽ trên các Panel/Control slot, ta tạo một Custom Control nhỏ vẽ quạt đè lên
