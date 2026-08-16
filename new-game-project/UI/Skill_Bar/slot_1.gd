extends Panel # Hoặc Control tùy thuộc vào node của ô slot bạn đang dùng

# 1. Khi bắt đầu kéo, trả về dữ liệu định danh của ô này (ví dụ: trả về chính node này hoặc index của nó)
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Lấy vị trí index của ô hiện tại thông qua metadata hoặc thứ tự của nó trong HBoxContainer
	var slot_index = get_index() # Lấy số thứ tự slot trong HBoxContainer (0, 1, 2, 3, 4, 5)
	
	# Tìm node SkillBar (node cha quản lý logic chính)
	var skill_bar = _find_skill_bar(self)
	if skill_bar and skill_bar.equipped_skills[slot_index] == null:
		return null # Ô trống thì không cho kéo
		
	# Tạo hình ảnh preview trôi theo chuột
	var preview = TextureRect.new()
	var icon_rect = get_node_or_null("TextureRect")
	if icon_rect and icon_rect.texture:
		preview.texture = icon_rect.texture
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.custom_minimum_size = Vector2(40, 40)
		set_deferred("set_drag_preview", preview)
		
	return {"from_index": slot_index}

# 2. Cho phép thả dữ liệu vào ô này
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("from_index")

# 3. Khi thả chuột vào ô đích, gọi hàm đổi chỗ trong SkillBar
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_index = data["from_index"]
	var to_index = get_index() # Lấy index của ô nhận
	
	var skill_bar = _find_skill_bar(self)
	if skill_bar:
		# Thực hiện hoán đổi vị trí trong mảng skill
		var temp = skill_bar.equipped_skills[from_index]
		skill_bar.equipped_skills[from_index] = skill_bar.equipped_skills[to_index]
		skill_bar.equipped_skills[to_index] = temp
		
		# Cập nhật lại giao diện
		skill_bar.update_skill_bar_ui()
		print("Đã đổi skill từ ô ", from_index + 1, " sang ô ", to_index + 1)

# Hàm hỗ trợ tự động tìm node cha chứa SkillBar
func _find_skill_bar(node: Node) -> Node:
	var p = node.get_parent()
	while p:
		if p.has_method("use_skill"):
			return p
		p = p.get_parent()
	return null
