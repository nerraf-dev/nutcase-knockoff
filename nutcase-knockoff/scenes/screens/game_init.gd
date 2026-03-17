extends Node2D

signal game_init_complete(settings: Dictionary)
signal back_to_home

# Button containers
# @onready var player_buttons = $PlayerSelect/Buttons
@onready var game_type_buttons = $GameType/Buttons
@onready var length_buttons = $LengthSelect/Buttons
@onready var mode_buttons = $ModeSelect/Buttons
@onready var fuzzy_buttons = $FuzzySelect/Buttons

# Action buttons
@onready var start_button = $StartBtn
@onready var home_button = $HomeBtn

# Confirm modal
@onready var confirm_modal = $ConfirmModal
@onready var confirm_button = $ConfirmModal/ConfirmBtn
@onready var back_button = $ConfirmModal/BackBtn
# @onready var confirm_players = $ConfirmModal/Players/PlayersValue
# @onready var confirm_mode = $ConfirmModal/Mode/ModeValue
# @onready var confirm_target = $ConfirmModal/Target/TargetValue
@onready var confirm_values = $ConfirmModal/Values

var settings = {
	"players": PlayerManager.players,
	"player_count": 1,
	"game_mode": "single",	# mode = "single", "multi", "pass_and_play" 
	"game_type": "qna",		# type = "qna", "challenge", "timed" etc
	"game_target": 200,
	"round_count": 5,
	"fuzzy_enabled": GameConfig.FUZZY_ENABLED_DEFAULT
}

func _ready() -> void:
	confirm_modal.visible = false
	
	# Setup all option button groups
	# _setup_buttons(player_buttons, "player_count")
	_setup_buttons(game_type_buttons, "game_type")
	_setup_buttons(length_buttons, "game_target")
	_setup_buttons(mode_buttons, "game_mode")
	_setup_buttons(fuzzy_buttons, "fuzzy_enabled")
	
	# Connect action buttons
	start_button.pressed.connect(_on_start_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Setup modal button navigation
	_setup_modal_focus()
	
	# Set initial focus for controller navigation
	player_buttons.get_child(0).grab_focus()


func _setup_buttons(container: Control, key: String) -> void:
	for button in container.get_children():
		if button is Button:
			button.pressed.connect(_on_option_selected.bind(button, key, container))

func _on_option_selected(button: Button, key: String, container: Control) -> void:
	var value = button.get_meta("value") if button.has_meta("value") else button.text
	settings[key] = value
	print("Selected %s: %s" % [key, str(value)])
	
	# Optional: Visual feedback for selected button
	_highlight_selected_button(button, container)

func _highlight_selected_button(selected: Button, container: Control) -> void:
	# Reset all buttons in this container
	for button in container.get_children():
		if button is Button:
			button.modulate = Color.WHITE
	# Highlight the selected one
	selected.modulate = Color.from_rgba8(251, 237, 43, 255)

func _on_start_button_pressed() -> void:
	# Show confirmation modal with selected settings
	confirm_modal.visible = true
	# confirm_players.text = str(settings["player_count"])
	# confirm_mode.text = settings["game_type"]
	# confirm_target.text = str(settings["game_target"])
	confirm_values.text = "Game Type: %s\nGame Mode: %s player\nTarget Score: %d\nFuzzy Matching: %s" % [
		settings["game_type"],
		settings["game_mode"],
		settings["game_target"],
		"Enabled" if settings["fuzzy_enabled"] else "Disabled"
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
	# for button in player_buttons.get_children():
	# 	if button is Button:
	# 		button.focus_mode = mode
	for button in game_type_buttons.get_children():
		if button is Button:
			button.focus_mode = mode
	for button in length_buttons.get_children():
		if button is Button:
			button.focus_mode = mode
	start_button.focus_mode = mode
	home_button.focus_mode = mode

func _on_back_button_pressed() -> void:
	confirm_modal.visible = false
	_set_background_focus(true)
	# player_buttons.get_child(0).grab_focus()

func _on_confirm_button_pressed() -> void:
	# TODO: if 1p - load game, if multi - load lobby and pass settings
	# Emit signal to start game with selected settings
	_set_background_focus(true)
	game_init_complete.emit(settings)
	confirm_modal.visible = false

func _on_home_button_pressed() -> void:
	confirm_modal.visible = false
	back_to_home.emit()
