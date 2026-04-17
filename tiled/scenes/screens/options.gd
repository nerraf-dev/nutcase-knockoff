extends Control

signal back_to_home
signal close_requested

# Action buttons
@export var is_lobby_mode: bool = true

# Required nodes (in both scenes)
@onready var sfx_toggle = $Sound/Buttons/toggle
@onready var sfx_volume = $Sound/Buttons/Volume
@onready var sfx_volume_value = $Sound/Buttons/Value
@onready var music_toggle = $Music/Buttons/toggle
@onready var music_volume = $Music/Buttons/Volume
@onready var music_volume_value = $Music/Buttons/Value
@onready var master_volume = $Master/Buttons/Volume
@onready var master_volume_value = $Master/Buttons/Value

# Optional nodes (only in lobby mode)
var start_button: Node = null
var home_button: Node = null
var internet_toggle: Node = null
var close_button: Node = null

const MIN_LINEAR_VOLUME := 0.001
const DEFAULT_LINEAR_VOLUME := 0.8
const SILENT_DB := -80.0


func _ready() -> void:
	# Set up optional nodes if in lobby mode
	if is_lobby_mode:
		start_button = get_node_or_null("StartBtn")
		home_button = get_node_or_null("HomeBtn")
		internet_toggle = get_node_or_null("Network/Buttons/toggle")
		
		if start_button:
			start_button.pressed.connect(_on_back_pressed)
		if home_button:
			home_button.pressed.connect(_on_back_pressed)
		if internet_toggle:
			internet_toggle.toggled.connect(_on_internet_toggled)
	else:
		close_button = get_node_or_null("CloseBtn")
		if close_button:
			close_button.pressed.connect(_on_close_pressed)
	
	# Required connections (always present)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	music_toggle.toggled.connect(_on_music_toggled)
	music_volume.value_changed.connect(_on_music_volume_changed)
	master_volume.value_changed.connect(_on_master_volume_changed)

	_sync_from_settings()


func _sync_from_settings() -> void:
	_set_toggle_state(sfx_toggle, UserSettings.ui_sfx_enabled)
	_set_toggle_state(music_toggle, UserSettings.music_enabled)
	if is_lobby_mode and internet_toggle:
		_set_toggle_state(internet_toggle, UserSettings.internet_enabled)

	var sfx_linear = _slider_value_from_settings(UserSettings.ui_sfx_enabled, UserSettings.ui_sfx_volume_db)
	sfx_volume.set_value_no_signal(sfx_linear)
	_update_slider_label(sfx_volume_value, sfx_linear)

	var music_linear = _slider_value_from_settings(UserSettings.music_enabled, UserSettings.music_volume_db)
	music_volume.set_value_no_signal(music_linear)
	_update_slider_label(music_volume_value, music_linear)

	var master_linear = _slider_value_from_db(UserSettings.master_volume_db)
	master_volume.set_value_no_signal(master_linear)
	_update_slider_label(master_volume_value, master_linear)


func _set_toggle_state(button: Button, enabled: bool) -> void:
	button.set_pressed_no_signal(enabled)
	button.text = "On" if enabled else "Off"


func _on_back_pressed() -> void:
	UISfx.play_ui_back()
	
	back_to_home.emit()


func _on_close_pressed() -> void:
	UISfx.play_ui_back()
	close_requested.emit()


func _on_sfx_toggled(enabled: bool) -> void:
	if enabled and sfx_volume.value <= 0.0:
		sfx_volume.set_value_no_signal(DEFAULT_LINEAR_VOLUME)
		UserSettings.set_ui_sfx_volume_db(linear_to_db(DEFAULT_LINEAR_VOLUME))

	UserSettings.set_ui_sfx_enabled(enabled)
	_set_toggle_state(sfx_toggle, enabled)
	if enabled:
		UISfx.play_ui_confirm()


func _on_music_toggled(enabled: bool) -> void:
	UISfx.play_ui_click()
	if enabled and music_volume.value <= 0.0:
		music_volume.set_value_no_signal(DEFAULT_LINEAR_VOLUME)
		UserSettings.set_music_volume_db(linear_to_db(DEFAULT_LINEAR_VOLUME))

	UserSettings.set_music_enabled(enabled)
	_set_toggle_state(music_toggle, enabled)


func _on_internet_toggled(enabled: bool) -> void:
	UISfx.play_ui_click()
	if internet_toggle == null:
		return
	UserSettings.set_internet_enabled(enabled)
	_set_toggle_state(internet_toggle, enabled)


func _on_sfx_volume_changed(value: float) -> void:
	_update_slider_label(sfx_volume_value, value)
	if value <= 0.0:
		UserSettings.set_ui_sfx_enabled(false)
		_set_toggle_state(sfx_toggle, false)
		return

	var linear = max(value, MIN_LINEAR_VOLUME)
	UserSettings.set_ui_sfx_volume_db(linear_to_db(linear))
	if not UserSettings.ui_sfx_enabled:
		UserSettings.set_ui_sfx_enabled(true)
		_set_toggle_state(sfx_toggle, true)
	UISfx.play_ui_click()


func _on_music_volume_changed(value: float) -> void:
	_update_slider_label(music_volume_value, value)
	if value <= 0.0:
		UserSettings.set_music_enabled(false)
		_set_toggle_state(music_toggle, false)
		return

	var linear = max(value, MIN_LINEAR_VOLUME)
	UserSettings.set_music_volume_db(linear_to_db(linear))
	if not UserSettings.music_enabled:
		UserSettings.set_music_enabled(true)
		_set_toggle_state(music_toggle, true)


func _on_master_volume_changed(value: float) -> void:
	_update_slider_label(master_volume_value, value)
	if value <= 0.0:
		UserSettings.set_master_volume_db(SILENT_DB)
		return

	var linear = max(value, MIN_LINEAR_VOLUME)
	UserSettings.set_master_volume_db(linear_to_db(linear))


func _slider_value_from_settings(enabled: bool, volume_db: float) -> float:
	if not enabled:
		return 0.0
	return _slider_value_from_db(volume_db)


func _slider_value_from_db(volume_db: float) -> float:
	var linear = db_to_linear(volume_db)
	return clampf(linear, 0.0, 1.0)


func _update_slider_label(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(value * 100.0))
