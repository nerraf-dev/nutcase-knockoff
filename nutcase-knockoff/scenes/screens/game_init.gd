extends Node2D

signal game_init_complete

@onready var players_container = $PlayersContainer
@onready var players_grid = $PlayersContainer/PlayersGrid
# @onready var player_slider = $PlayersContainer/PlayerSlider/Slider
# @onready var player_count_label = $PlayersContainer/PlayerSlider/PlayerCount
@onready var add_player_button = $PlayersContainer/AddPlayerButton
@onready var game_settings_container = $GameSettingsContainer
@onready var game_mode_list = $GameSettingsContainer/GameModes
@onready var game_length_list = $GameSettingsContainer/GameLengths
@onready var start_button = $StartBtn
@onready var confirm_modal = $ConfirmModal
@onready var confirm_players = $ConfirmModal/Players/PlayersValue
@onready var confirm_mode = $ConfirmModal/Mode/ModeValue
@onready var confirm_length = $ConfirmModal/Length/LengthValue

@onready var player_picker = preload("res://scenes/components/player_picker.tscn")

var player_count: int = 2
var settings = {
	"players": PlayerManager.players,
	"game_type": "qna",
	"round_count": 5
}

# populate game modes and lengths
const GAME_MODES = ["Q'n'A"]
const GAME_LENGTHS = [5, 10, 15, 20, 25]  # number of rounds

# Main Functions
func _ready() -> void:
	print("GameInit scene ready")
	confirm_modal.visible = false
	_make_connections()
	_init_lists()
	_initialize_players()
	# game_init_complete.emit()


# helper functions
func _make_connections() -> void:
	add_player_button.pressed.connect(Callable(self, "_on_add_player_button_pressed"))
	# player_slider.connect("value_changed", Callable(self, "_on_h_slider_value_changed"))
	game_mode_list.item_selected.connect(Callable(self, "_on_game_mode_selected"))
	game_length_list.item_selected.connect(Callable(self, "_on_game_length_selected"))
	start_button.pressed.connect(Callable(self, "_on_start_button_pressed"))

func _init_lists() -> void:
	game_mode_list.clear()
	game_length_list.clear()
	for mode in GAME_MODES:
		game_mode_list.add_item(mode)
	game_mode_list.select(0)  # Default selection

	for i in range(GAME_LENGTHS.size()):
		game_length_list.add_item("%d Rounds" % GAME_LENGTHS[i])
	game_length_list.select(0)  # Default selection

func _initialize_players() -> void:
	for i in range(player_count):
		var player_name = "Player %d" % (i + 1)
		PlayerManager.add_player(player_name)
		var picker_instance = player_picker.instantiate()
		picker_instance.set_player_name(player_name)
		players_grid.add_child(picker_instance)
	settings["players"] = PlayerManager.players

# signal handlers
func _on_game_mode_selected(index: int) -> void:
	var selected_mode = game_mode_list.get_item_text(index)
	print("Game mode selected: %s" % selected_mode)
	settings["game_type"] = selected_mode

func _on_game_length_selected(index: int) -> void:
	print("Game length selected: %d" % index)
	settings["round_count"] = GAME_LENGTHS[index]

func _on_add_player_button_pressed() -> void:
	var new_player_index = PlayerManager.players.size() + 1
	var player_name = "Player %d" % new_player_index
	PlayerManager.add_player(player_name)
	var picker_instance = player_picker.instantiate()
	picker_instance.set_player_name(player_name)
	players_grid.add_child(picker_instance)
	print("Added new player: %s" % player_name)

	if PlayerManager.players.size() >= 8:
		print("Maximum number of players reached.")
		add_player_button.disabled = true
		return

func _on_start_button_pressed() -> void:
	confirm_modal.visible = true
	print("Start button pressed, game settings: %s" % settings)
	confirm_players.text = str(PlayerManager.players.size())
	confirm_mode.text = settings["game_type"]
	confirm_length.text = str(settings["round_count"])
