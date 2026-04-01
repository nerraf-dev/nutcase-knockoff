extends Node

const MENU_MUSIC_STREAM := preload("res://assets/sound/music/8bit Bossa.mp3")
const GAME_MUSIC_STREAM := preload("res://assets/sound/music/8bit Bossa.mp3")

var _player: AudioStreamPlayer
var _active_track: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	_player.stream_paused = false
	add_child(_player)
	_apply_settings()
	if not UserSettings.settings_changed.is_connected(_on_settings_changed):
		UserSettings.settings_changed.connect(_on_settings_changed)


func play_menu_music() -> void:
	_play_track("menu", MENU_MUSIC_STREAM)


func play_game_music() -> void:
	_play_track("game", GAME_MUSIC_STREAM)


func stop_music() -> void:
	if is_instance_valid(_player) and _player.playing:
		_player.stop()


func _play_track(track_key: String, stream: AudioStream) -> void:
	if not is_instance_valid(_player):
		return
	if stream == null:
		return

	var same_track = _active_track == track_key
	if same_track and _player.playing:
		_apply_settings()
		return

	_player.stream = stream
	_player.play()
	_active_track = track_key
	_apply_settings()


func _on_settings_changed() -> void:
	_apply_settings()


func _apply_settings() -> void:
	if not is_instance_valid(_player):
		return
	_player.volume_db = UserSettings.music_volume_db
	_player.stream_paused = not UserSettings.music_enabled