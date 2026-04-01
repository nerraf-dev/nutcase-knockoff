extends Node2D

signal back_to_home

# Action buttons
@onready var start_button = $StartBtn
@onready var home_button = $HomeBtn
@onready var sfx_toggle = $Sound/Buttons/toggle
@onready var music_toggle = $Music/Buttons/toggle
@onready var network_toggle = $Network/Buttons/toggle


func _ready() -> void:
	start_button.pressed.connect(_on_back_pressed)
	home_button.pressed.connect(_on_back_pressed)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	network_toggle.toggled.connect(_on_network_toggled)

	_sync_from_settings()


func _sync_from_settings() -> void:
	_set_toggle_state(sfx_toggle, UserSettings.ui_sfx_enabled)
	_set_toggle_state(music_toggle, UserSettings.music_enabled)
	_set_toggle_state(network_toggle, UserSettings.network_enabled)


func _set_toggle_state(button: Button, enabled: bool) -> void:
	button.set_pressed_no_signal(enabled)
	button.text = "On" if enabled else "Off"


func _on_back_pressed() -> void:
	UISfx.play_ui_back()
	back_to_home.emit()


func _on_sfx_toggled(enabled: bool) -> void:
	# Play before saving the disabled state so users get immediate feedback.
	if not enabled:
		UISfx.play_ui_click()
	UserSettings.set_ui_sfx_enabled(enabled)
	if enabled:
		UISfx.play_ui_confirm()
	_set_toggle_state(sfx_toggle, enabled)


func _on_music_toggled(enabled: bool) -> void:
	UISfx.play_ui_click()
	UserSettings.set_music_enabled(enabled)
	_set_toggle_state(music_toggle, enabled)


func _on_network_toggled(enabled: bool) -> void:
	UISfx.play_ui_click()
	UserSettings.set_network_enabled(enabled)
	_set_toggle_state(network_toggle, enabled)
