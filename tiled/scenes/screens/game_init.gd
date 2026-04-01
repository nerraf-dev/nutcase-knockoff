extends Node2D

signal game_init_complete(settings: Dictionary)
signal back_to_home

const DEFAULT_GAME_TARGET = 200
const REQUIRED_SETTING_KEYS = ["game_mode", "game_type", "game_target", "fuzzy_enabled"]

# Button containers
@onready var game_type_buttons = $GameType/Buttons
@onready var length_buttons = $LengthSelect/Buttons
@onready var mode_buttons = $ModeSelect/Buttons

# Action buttons
@onready var start_button = $StartBtn
@onready var home_button = $HomeBtn

# Confirm modal
@onready var confirm_modal = $ConfirmModal
@onready var confirm_button = $ConfirmModal/ConfirmBtn
@onready var back_button = $ConfirmModal/BackBtn
@onready var confirm_values = $ConfirmModal/Values

var settings = {
	"players": PlayerManager.players,
	"player_count": 1,
	"game_mode": "multi", # mode = "single", "multi", "pass_and_play"
	"game_type": "qna", # type = "qna", "challenge", "timed" etc
	"game_target": DEFAULT_GAME_TARGET,
	"round_count": 5,
	"fuzzy_enabled": GameConfig.FUZZY_ENABLED_DEFAULT
}

func _ready() -> void:
	confirm_modal.visible = false
	# Setup all option button groups
	_setup_buttons(game_type_buttons, "game_type")
	_setup_buttons(length_buttons, "game_target")
	_setup_buttons(mode_buttons, "game_mode")
	
	# Connect action buttons
	start_button.pressed.connect(_on_start_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	# Setup modal button navigation
	_setup_modal_focus()
	# Highlight pre-selected defaults
	_highlight_selected_button(mode_buttons.get_child(1), mode_buttons) # Multiplayer (index 1)
	_highlight_selected_button(game_type_buttons.get_child(0), game_type_buttons) # Q'n'A (index 0)
	_highlight_selected_button(length_buttons.get_child(0), length_buttons) # Short (index 0)
	# Set initial focus for controller navigation
	game_type_buttons.get_child(0).grab_focus()

func _setup_buttons(container: Control, key: String) -> void:
	for button in _get_buttons(container):
		button.pressed.connect(_on_option_selected.bind(button, key, container))

func _get_buttons(container: Control) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in container.get_children():
		if child is Button:
			buttons.append(child)
	return buttons

func _on_option_selected(button: Button, key: String, container: Control) -> void:
	UISfx.play_ui_click()
	var value = button.get_meta("value") if button.has_meta("value") else button.text
	if key == "game_target":
		value = int(value)
		if value <= 0:
			push_warning("Invalid target score selected; falling back to default")
			value = DEFAULT_GAME_TARGET
	settings[key] = value
	print("Selected %s: %s" % [key, str(value)])
	
	# Optional: Visual feedback for selected button
	_highlight_selected_button(button, container)

func _highlight_selected_button(selected: Button, container: Control) -> void:
	# Show circle indicator on selected button, hide on others
	for button in _get_buttons(container):
		if button.has_node("TextureRect"):
			var rect = button.get_node("TextureRect")
			rect.visible = (button == selected)
	

func _on_start_button_pressed() -> void:
	UISfx.play_ui_click()
	# Show confirmation modal with selected settings
	confirm_modal.visible = true
	confirm_values.text = "Game Type: %s\nGame Mode: %s player\nTarget Score: %d\n" % [
		settings["game_type"],
		settings["game_mode"],
		settings["game_target"],
	]
	# Disable background controls and focus modal
	_set_background_focus(false)
	await get_tree().process_frame
	confirm_button.grab_focus()

func _setup_modal_focus() -> void:
	# Create focus loop between modal buttons
	back_button.focus_neighbor_right = confirm_button.get_path()
	confirm_button.focus_neighbor_left = back_button.get_path()
	# Loop vertically too
	back_button.focus_neighbor_bottom = confirm_button.get_path()
	confirm_button.focus_neighbor_top = back_button.get_path()
	back_button.focus_neighbor_top = back_button.get_path()
	confirm_button.focus_neighbor_bottom = confirm_button.get_path()
	
func _set_background_focus(enabled: bool) -> void:
	# Prevent controller from navigating to background buttons
	var mode = Control.FOCUS_NONE if not enabled else Control.FOCUS_ALL
	for button in _get_buttons(game_type_buttons):
		button.focus_mode = mode
	for button in _get_buttons(length_buttons):
		button.focus_mode = mode
	for button in _get_buttons(mode_buttons):
		button.focus_mode = mode
	start_button.focus_mode = mode
	home_button.focus_mode = mode

func _on_back_button_pressed() -> void:
	UISfx.play_ui_click()
	confirm_modal.visible = false
	_set_background_focus(true)
	game_type_buttons.get_child(0).grab_focus()

func _on_confirm_button_pressed() -> void:
	UISfx.play_ui_click()
	# TODO: if 1p - load game, if multi - load lobby and pass settings
	# Emit signal to start game with selected settings
	if not _validate_settings(settings):
		push_error("Invalid game settings; cannot start")
		return
	_set_background_focus(true)
	game_init_complete.emit(settings)
	confirm_modal.visible = false

func _validate_settings(settings_to_validate: Dictionary) -> bool:
	for key in REQUIRED_SETTING_KEYS:
		if not settings_to_validate.has(key):
			push_warning("Missing required setting: %s" % key)
			return false

	if not (settings_to_validate["game_target"] is int):
		push_warning("game_target must be an integer")
		return false

	if settings_to_validate["game_target"] <= 0:
		push_warning("game_target must be greater than zero")
		return false

	if not (settings_to_validate["fuzzy_enabled"] is bool):
		push_warning("fuzzy_enabled must be a boolean")
		return false

	return true

func _on_home_button_pressed() -> void:
	UISfx.play_ui_click()
	confirm_modal.visible = false
	back_to_home.emit()
