extends Node2D
@export_file("*.mp3", "*.ogg") var map_music: String = "res://Asset/Musics/《河阳城》.mp3"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if map_music:
		SoundManager.play_bgm(map_music)

