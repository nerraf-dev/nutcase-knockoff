extends Control

# GameBoard - game_board.gd
# This script manages the main game board scene, including HUD and round area.
# The RoundArea will host the 'game play'. That scene handles the game play logic.
# Teh GameBoard HUD shows the player list & details, main controls, etc.

signal return_to_home

const player_badge = preload("res://scenes/components/player_badge.tscn")

@onready var controls = $HUD/Controls  # Reference to the HUD controls container.
@onready var options_btn = $HUD/Controls/OptionsBtn  # Button to open the options menu.
@onready var exit_btn = $HUD/Controls/ExitBtn  # Button to exit the game.
@onready var players_container = $HUD/PlayersContainer  # Container for displaying player badges.

@onready var res_overlay = $ResultOverlay  # Overlay for displaying round results.
@onready var res_label = $ResultOverlay/ResultLabel  # Label for result messages.
@onready var res_next_btn = $ResultOverlay/NextBtn  # Button to proceed to the next round.

@onready var round_area = $RoundArea  # Node where the round scenes are loaded.
@onready var exit_confirm = $AcceptDialog  # Confirmation dialog for exiting the game.

const ROUND_SCENES = {
	"qna": "res://scenes/components/rounds/qna.tscn"  # Path to the QnA round scene.
	# Add other round types here as needed.
}

var qna_instance = null  # Instance of the currently loaded round scene.

func _ready() -> void:

	if Engine.is_editor_hint():
		return  # Don't run test code in the editor

	if not GameManager.game:
		# Setup dummy game for debugging
		GameManager.start_game({
			"game_type": "qna",
			"game_target": 250,
			"player_count": 2,
			"round_count": 10
		})

	print("Game Board scene ready")

	# Hide result overlay initially
	res_overlay.visible = false

	# Connect button signals
	exit_btn.pressed.connect(Callable(self, "_on_exit_btn_pressed"))
	options_btn.pressed.connect(Callable(self, "_on_options_btn_pressed"))
	
	exit_confirm.confirmed.connect(_on_exit_confirmed)
	
	# Connect to turn changes to update current player indicator
	PlayerManager.turn_changed.connect(_on_turn_changed)

	_setup_players_hud()
	_setup_round_area()


func _update_overlay(msg: String, delay: float = 0.0) -> void:
	res_label.text = msg
	res_overlay.visible = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	else:
		await res_next_btn.pressed
	res_overlay.visible = false


func  _setup_players_hud() -> void:
	# Sets up the player HUD by clearing existing badges and adding new ones for each player.
	if players_container.get_child_count() > 0:
		for child in players_container.get_children():
			child.queue_free()
	for player in PlayerManager.players:
		var badge_instance = player_badge.instantiate()
		players_container.add_child(badge_instance)
		badge_instance.setup(player)

func _setup_round_area() -> void:
	# Loads and sets up the appropriate round scene based on the game type.
	var game_type = GameManager.game.game_type.to_lower()
	var round_scene_path = ROUND_SCENES.get(game_type, "")
	if round_scene_path == "":
		push_error("No round scene found for game type: %s" % game_type)
		return
	var round_scene = load(round_scene_path)
	if round_scene:
		qna_instance = round_scene.instantiate()
		round_area.add_child(qna_instance)
		qna_instance.connect("round_result", Callable(self, "_on_round_result"))
	else:
		push_error("Failed to load round scene at path: %s" % round_scene_path)

func _on_round_result(player: Player, is_correct: bool, prize: int) -> void:
	if not is_correct:
		# Delegate freezing and penalty logic to PlayerManager
		PlayerManager.freeze_player(player)
		print("Player %s is now frozen for next round." % player.name)
		var penalty = int(prize * GameManager.game.question_penalty)  # Use penalty ratio from GameManager
		PlayerManager.award_points(player, -penalty)  # Deduct points
		_update_overlay("Incorrect %s!\n You lose %d points!" % [player.name, penalty])
	elif is_correct:
		# Delegate scoring and unfreezing logic to PlayerManager
		print("Player %s answered correctly!" % player.name)
		PlayerManager.award_points(player, prize)
		PlayerManager.unfreeze_player(player)
		_update_overlay("Correct %s!\n You get %d points!" % [player.name, prize])

	# Update the HUD badges
	_update_all_badges()

	# Notify GameManager to handle the round result
	GameManager.round_res_handler()


func _update_all_badges() -> void:
	# Updates all player badges to reflect the current game state.
	var badges = players_container.get_children()
	var current_player = PlayerManager.get_current_player()
	var leaders = PlayerManager.get_leaders()
	
	for i in range(badges.size()):
		if i < PlayerManager.players.size():
			var player = PlayerManager.players[i]
			badges[i].update_score(player.score)
			badges[i].set_current_player(player == current_player)
			badges[i].set_current_leader(leaders.has(player))

func _on_turn_changed(_player: Player) -> void:
	# Update badges when turn changes
	_update_all_badges()

func _start_next_round() -> void:
	# Starts the next round by loading the next question.
	var next_question = GameManager.get_next_question()
	if next_question:
		PlayerManager.unfreeze_all_players()
		GameManager.game.current_round += 1
		qna_instance.start_new_question(next_question)
	else:
		print("No more questions available!")

# Signal handlers for buttons.
func _on_options_btn_pressed() -> void:
	print("Options button pressed")

func _on_exit_btn_pressed() -> void:
	print("Exit button pressed")
	exit_confirm.dialog_text = "Are you sure you want to exit to main menu?"
	exit_confirm.popup_centered()

func _on_exit_confirmed() -> void:
	# Handles the confirmation to exit the game.
	print("Exit confirmed, returning to main menu")
	# Reset game state
	GameManager.game = null
	PlayerManager.clear_all_players()
	# Emit signal to main - let main handle scene cleanup
	return_to_home.emit()
