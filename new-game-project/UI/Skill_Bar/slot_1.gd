extends Panel # Hoặc Control tùy thuộc vào node của ô slot bạn đang dùng

# 1. Khi bắt đầu kéo, trả về dữ liệu định danh của ô này (ví dụ: trả về chính node này hoặc index của nó)
func _get_drag_data(_at_position: Vector2) -> Variant:
    var slot_index = get_index()
    
    var skill_bar = _find_skill_bar(self)
    if skill_bar and skill_bar.equipped_skills[slot_index] == null:
        return null # Ô trống thì không cho kéo
        
    # --- TẠO HIỆU ỨNG KÉO THẢ (PREVIEW) GIỐNG TÚI ĐỒ ---
    var icon_rect = get_node_or_null("TextureRect")
    if icon_rect and icon_rect.texture:
        # 1. Tạo một TextureRect hiển thị icon đang kéo
        var preview = TextureRect.new()
        preview.texture = icon_rect.texture
        preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        preview.custom_minimum_size = Vector2(40, 40) # Kích thước icon khi đang kéo
        
        # 2. Đưa vào một Control container để canh chỉnh tâm theo con trỏ chuột
        var preview_container = Control.new()
        preview_container.add_child(preview)
        preview.position = Vector2(-20, -20) # Canh giữa icon vào con trỏ chuột
        
        # 3. Gán vào hệ thống Drag Preview của Godot
        set_drag_preview(preview_container)
        
    return {
        "from_index": slot_index,
        "type": "skill"
    }

# 2. Cho phép thả dữ liệu vào ô này
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if not (data is Dictionary):
       return false
		
	# Chặn tuyệt đối nếu đây là dữ liệu kéo từ túi đồ (có chứa from_page)
    if data.has("from_page"):
       return false
		
	# Chỉ cho phép nếu đúng là dữ liệu kéo giữa các ô skill với nhau
    return data.has("from_index")

# 3. Khi thả chuột vào ô đích, gọi hàm đổi chỗ trong SkillBar
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Lớp bảo vệ chống crash game nếu dữ liệu không hợp lệ
    if not (data is Dictionary) or data.has("from_page") or not data.has("from_index"):
       return
		
    var from_index = data["from_index"]
    var to_index = get_index() # Lấy index của ô nhận
	
    var skill_bar = _find_skill_bar(self)
    if skill_bar:
		# Kiểm tra giới hạn mảng an toàn tuyệt đối trước khi truy cập
        if from_index >= skill_bar.equipped_skills.size() or to_index >= skill_bar.equipped_skills.size():
            return
			
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
