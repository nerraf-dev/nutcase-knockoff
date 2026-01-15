extends Control

# GameBoard - game_board.gd
# This script manages the main game board scene, including HUD and round area.
# The RoundArea will host the 'game play'. That scene handles the game play logic.
# The GameBoard HUD shows the player list & details, main controls, etc.

signal return_to_home

const player_badge = preload("res://scenes/components/player_badge.tscn")

@onready var controls = $HUD/Controls
@onready var options_btn = $HUD/Controls/OptionsBtn
@onready var exit_btn = $HUD/Controls/ExitBtn
@onready var players_container = $HUD/PlayersContainer

@onready var res_overlay = $ResultOverlay
@onready var res_label = $ResultOverlay/ResultLabel
@onready var res_next_btn = $ResultOverlay/NextBtn

@onready var round_area = $RoundArea
@onready var exit_confirm = $AcceptDialog

const ROUND_SCENES = {
	"qna": "res://scenes/components/rounds/qna.tscn"
	# Add other round types here as needed
}

var round_instance = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Validate game state
	assert(GameManager.current_state == GameManager.GameState.IN_PROGRESS, "Game Board loaded but game not in progress!")
	assert(GameManager.game != null, "Game Board loaded but no game exists!")

	print("Game Board scene ready")
	res_overlay.visible = false
	exit_btn.pressed.connect(Callable(self, "_on_exit_btn_pressed"))
	options_btn.pressed.connect(Callable(self, "_on_options_btn_pressed"))
	exit_confirm.confirmed.connect(_on_exit_confirmed)
	# Connect to turn changes to update current player indicator
	PlayerManager.turn_changed.connect(_on_turn_changed)
	_setup_players_hud()
	_setup_round_area()

func _update_overlay(msg: String) -> void:
	res_label.text = msg
	res_overlay.visible = true
	await res_next_btn.pressed
	res_overlay.visible = false

func  _setup_players_hud() -> void:
	if players_container.get_child_count() > 0:
		for child in players_container.get_children():
			child.queue_free()
	for player in PlayerManager.players:
		var badge_instance = player_badge.instantiate()
		players_container.add_child(badge_instance)
		badge_instance.setup(player)

func _setup_round_area() -> void:
	var game_type = GameManager.game.game_type.to_lower()
	var round_scene_path = ROUND_SCENES.get(game_type, "")
	if round_scene_path == "":
		push_error("No round scene found for game type: %s" % game_type)
		return
	var round_scene = load(round_scene_path)
	if round_scene:
		round_instance = round_scene.instantiate()
		round_area.add_child(round_instance)
		round_instance.connect("round_result", Callable(self, "_on_round_result"))
	else:
		push_error("Failed to load round scene at path: %s" % round_scene_path)

func _on_round_result(player: Player, is_correct: bool, prize: int) -> void:
	if not is_correct:
		var result = GameManager.handle_wrong_answer(player, prize)
		_update_all_badges()
		if result["is_frozen"]:
			_update_overlay(result["message"])
		if result["is_last_standing"]:
			_update_overlay(result["message"])
			# Auto-show answer modal for free guess
			if round_instance:
				round_instance.show_answer_modal_for_free_guess()
	elif is_correct:
		var result = GameManager.handle_correct_answer(player, prize)
		_update_all_badges()
		_update_overlay(result["message"])
		if result["has_winner"]:
			GameManager.game_ended.emit(result["winner"])
			round_area.set_process_input(false)
			_update_overlay("The winner is\n%s!" % result["winner"].name)
		else:
			await get_tree().create_timer(1.0).timeout
			_update_overlay("No winner yet,\nstarting next round...")
			_start_next_round()

func _update_all_badges() -> void:
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
	# the winner of the last round should still be current player. 
	var next_question = GameManager.get_next_question()
	if next_question:
		PlayerManager.unfreeze_all_players()
		GameManager.game.current_round += 1
		round_instance.start_new_question(next_question)
	else:
		print("No more questions available!")

# Signal handlers for buttons
func _on_options_btn_pressed() -> void:
	print("Options button pressed")

func _on_exit_btn_pressed() -> void:
	print("Exit button pressed")
	exit_confirm.dialog_text = "Are you sure you want to exit to main menu?"
	exit_confirm.popup_centered()

func _on_exit_confirmed() -> void:
	print("Exit confirmed, returning to main menu")
	# Reset game state
	GameManager.game = null
	GameManager.current_state = GameManager.GameState.NONE
	PlayerManager.clear_all_players()
	return_to_home.emit()
