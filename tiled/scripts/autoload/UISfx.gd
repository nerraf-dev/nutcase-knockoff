extends Node

const CLICK_STREAM := preload("res://assets/sound/effects/click1.wav")

var _ui_player: AudioStreamPlayer


func _ready() -> void:
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UIClickPlayer"
	_ui_player.stream = CLICK_STREAM
	add_child(_ui_player)
	_apply_settings()
	if not UserSettings.settings_changed.is_connected(_on_settings_changed):
		UserSettings.settings_changed.connect(_on_settings_changed)


func play_ui_click() -> void:
	_play(CLICK_STREAM)


func play_ui_confirm() -> void:
	_play(CLICK_STREAM)


func play_ui_back() -> void:
	_play(CLICK_STREAM)


func _play(stream: AudioStream) -> void:
	if not is_instance_valid(_ui_player):
		return
	if not UserSettings.ui_sfx_enabled:
		return
	if stream != null:
		_ui_player.stream = stream
	# Restart if already playing so rapid taps still feel responsive.
	if _ui_player.playing:
		_ui_player.stop()
	_ui_player.play()


func _on_settings_changed() -> void:
	_apply_settings()


func _apply_settings() -> void:
	if not is_instance_valid(_ui_player):
		return
	_ui_player.volume_db = UserSettings.ui_sfx_volume_db