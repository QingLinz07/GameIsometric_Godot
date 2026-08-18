extends Node

# Biến này sẽ chứa tham chiếu đến node Player hiện tại trong game
var current_player: CharacterBody2D = null

# Giúp truy cập nhanh các thuộc tính
# Sử dụng getter để kiểm tra nếu Player bị null thì tránh lỗi
var hp: float:
	get: return current_player.health.current_hp if current_player else 0

var stamina: float:
	get: return current_player.stamina.current_stamina if current_player else 0

# Hàm gọi trực tiếp (Ví dụ: PlayerManager.Heal(50))
func TruStamina(amount: float):
	if current_player:
		current_player.TruStamina(amount)