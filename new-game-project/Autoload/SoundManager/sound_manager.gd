extends Node

@onready var bgm_player: AudioStreamPlayer = $AudioStreamPlayer

func play_bgm(music_path: String) -> void:
	# Kiểm tra xem có đúng bài đang phát không để tránh bị load lại từ đầu khi không cần thiết
	var current_stream = bgm_player.stream
	if current_stream and current_stream.resource_path == music_path:
		if bgm_player.playing:
			return # Đang phát đúng bài này rồi thì thôi, không bật lại nữa

	# Nếu là bài khác thì đổi và phát mới
	var new_music = load(music_path)
	if new_music:
		bgm_player.stream = new_music
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()