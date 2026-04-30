extends Node

const CLICK_STREAM := preload("res://assets/sound/effects/click1.wav")
const UI_BUS_NAME := "UI"

var _ui_player: AudioStreamPlayer


func _ready() -> void:
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UIClickPlayer"
	_ui_player.stream = CLICK_STREAM
	_ui_player.bus = UI_BUS_NAME
	_ui_player.volume_db = 0.0
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
	_ui_player.pitch_scale = randf_range(0.95, 1.05) # Add slight random pitch variation for less repetitiveness.
	_ui_player.play()


func _on_settings_changed() -> void:
	_apply_settings()


func _apply_settings() -> void:
	if not is_instance_valid(_ui_player):
		return
	_apply_bus_settings(UI_BUS_NAME, UserSettings.ui_sfx_volume_db, UserSettings.ui_sfx_enabled)


func _apply_bus_settings(bus_name: String, volume_db: float, enabled: bool) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus '%s' not found; falling back to Master" % bus_name)
		bus_index = AudioServer.get_bus_index("Master")
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	AudioServer.set_bus_mute(bus_index, not enabled)