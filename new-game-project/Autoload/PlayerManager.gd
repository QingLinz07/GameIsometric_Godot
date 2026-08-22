extends Node

# Biến này sẽ chứa tham chiếu đến node Player hiện tại trong game
var current_player: CharacterBody2D = null

# Giúp truy cập nhanh các thuộc tính
# Sử dụng getter để kiểm tra nếu Player bị null thì tránh lỗi
# Đổi thành hàm (function) thay vì property
func get_max_hp() -> float:
	return current_player.health.max_hp if current_player else 0

func get_hp() -> float:
	return current_player.health.current_hp if current_player else 0

func get_stamina() -> float:
	return current_player.stamina.current_stamina if current_player else 0

# Hàm gọi trực tiếp (Ví dụ: PlayerManager.Heal(50))
func TruStamina(amount: float): if current_player: current_player.TruStamina(amount)

func CongMau(amount: float): if current_player: current_player.CongMau(amount)
