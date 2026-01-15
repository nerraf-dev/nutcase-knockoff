extends Node2D

signal game_init_complete(settings: Dictionary)

@onready var players_container = $PlayersContainer
@onready var players_grid = $PlayersContainer/PlayersGrid
@onready var game_settings_container = $GameSettingsContainer
@onready var game_mode_list = $GameSettingsContainer/GameModes
@onready var game_target_list = $GameSettingsContainer/GameTargets
@onready var start_button = $StartBtn
@onready var total_players = $PlayerCount
@onready var confirm_modal = $ConfirmModal
@onready var confirm_button = $ConfirmModal/ConfirmBtn
@onready var back_button = $ConfirmModal/BackBtn
@onready var confirm_players = $ConfirmModal/Players/PlayersValue
@onready var confirm_mode = $ConfirmModal/Mode/ModeValue
@onready var confirm_target = $ConfirmModal/Target/TargetValue


@onready var player_picker = preload("res://scenes/components/player_picker.tscn")

var settings = {
	"players": PlayerManager.players,
	"player_count": 2,
	"game_type": "qna",
	"game_target": 200,
	"round_count": 5
}

# populate game modes and lengths
const GAME_MODES = ["qna"]
const GAME_TARGETS = [200, 1000, 2000, 3000]  # winning score thresholds

# Main Functions
func _ready() -> void:
	confirm_modal.visible = false
	_make_connections()
	_init_lists()

# helper functions
func _make_connections() -> void:
	game_mode_list.item_selected.connect(Callable(self, "_on_game_mode_selected"))
	game_target_list.item_selected.connect(Callable(self, "_on_game_target_selected"))
	start_button.pressed.connect(Callable(self, "_on_start_button_pressed"))
	confirm_button.pressed.connect(Callable(self, "_on_confirm_button_pressed"))
	back_button.pressed.connect(Callable(self, "_on_back_button_pressed"))

func _init_lists() -> void:
	game_mode_list.clear()
	game_target_list.clear()
	for mode in GAME_MODES:
		game_mode_list.add_item(mode)
	game_mode_list.select(0)  # Default selection

	for i in range(GAME_TARGETS.size()):
		game_target_list.add_item("%d Rounds" % GAME_TARGETS[i])
	game_target_list.select(0)  # Default selection

# signal handlers
func _on_game_mode_selected(index: int) -> void:
	var selected_mode = game_mode_list.get_item_text(index)
	print("Game mode selected: %s" % selected_mode)
	settings["game_type"] = selected_mode

func _on_game_target_selected(index: int) -> void:
	print("Game length selected: %d" % index)
	settings["game_target"] = GAME_TARGETS[index]

func _on_start_button_pressed() -> void:
	confirm_modal.visible = true
	settings["player_count"] = int(total_players.value)
	confirm_players.text = str(settings["player_count"])
	confirm_mode.text = settings["game_type"]
	confirm_target.text = str(settings["game_target"])

func _on_back_button_pressed() -> void:
	confirm_modal.visible = false
	print("Back button pressed, returning to game init setup")

func _on_confirm_button_pressed() -> void:
	game_init_complete.emit(settings)
	confirm_modal.visible = false
