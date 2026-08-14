extends Label

func update_nametag(p_name: String, node_name: String, is_auth: bool) -> void:  
	text = p_name if p_name != "" else str(node_name)

    # # Căn giữa chữ trong khung
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# # Ép Label cập nhật lại kích thước thực tế theo độ dài chuỗi text
	reset_size()
	# # Đặt mép trái lùi về bên trái một nửa chiều rộng để tâm chữ trùng với X = 0
	position.x = -size.x / 2.0
	# position.y = -100 # Độ cao trên đầu nhân vật
	# Đổi màu Nametag
	if is_auth:
		modulate = Color.GREEN # Tên mình màu Xanh
	else:
		modulate = Color.WHITE # Tên người khác màu Trắng
