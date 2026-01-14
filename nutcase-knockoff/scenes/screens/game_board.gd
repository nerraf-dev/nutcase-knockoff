extends Control

# GameBoard - game_board.gd
# This script manages the main game board scene, including HUD and round area.
# The RoundArea will host the 'game play'. That scene handles the game play logic.
# Teh GameBoard HUD shows the player list & details, main controls, etc.

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

var qna_instance = null

func _ready() -> void:
	print("Game Board scene ready")
	res_overlay.visible = false
	exit_btn.pressed.connect(Callable(self, "_on_exit_btn_pressed"))
	options_btn.pressed.connect(Callable(self, "_on_options_btn_pressed"))
	
	exit_confirm.confirmed.connect(_on_exit_confirmed)

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
		qna_instance = round_scene.instantiate()
		round_area.add_child(qna_instance)
		qna_instance.connect("round_result", Callable(self, "_on_round_result"))
	else:
		push_error("Failed to load round scene at path: %s" % round_scene_path)

func _on_round_result(player: Player, is_correct: bool, prize: int) -> void:
	# occurs when a player chooses to answer.
	# if the player guesses incorrectly:
		#  - they are frozen until the next round.
		#  - they are given the point deduction penalty (half of the question score)
		#  - play continues with remaining players
			# if only one player remains, they are given the chance of penalty free guess. (handled in qna??)
	# if the player guesses correctly:
		#  - they are awarded the current question prize points
		#  - they are un-frozen if they were frozen
		#  - check for winners (based on score)
			# if winner(s) found, end game
			# else continue to next round
	if not is_correct:
		player.is_frozen = true
		print("Player %s is now frozen for this question." % player.name)
		
		# Check if only one player left unfrozen (free guess rule)
		var active_players = PlayerManager.get_active_players()
		if active_players.size() == 1:
			# Last player standing gets a free guess (no penalty)
			PlayerManager.next_turn()  # Advance to last player
			_update_overlay("Last player standing!\n%s gets a free guess!" % active_players[0].name)
			print("Free guess for %s - no penalty applied" % active_players[0].name)
			# Auto-show answer modal for free guess
			if qna_instance:
				qna_instance.show_answer_modal_for_free_guess()
		else:
			# Normal penalty applies
			var penalty = int(player.score * 0.5)  # 50% of player's current score
			PlayerManager.award_points(player, -penalty)
			_update_all_badges()
			_update_overlay("Incorrect %s!\nYou lose %d points!" % [player.name, penalty])
		
		PlayerManager.next_turn()	

	elif is_correct:
		print("Player %s answered correctly!" % player.name)
		PlayerManager.award_points(player, prize)
		_update_all_badges()
		player.is_frozen = false  # Unfreeze if they were frozen
		
		# PLACEHOLDER: Show result overlay for correct answer
		# await get_tree().create_timer(2.0).timeout  # Show result for 2 seconds
		_update_overlay("Correct %s!\n You get %d points!" % [player.name, prize])
		print("NEXT pressed")

		# Check for winners
		var winners = GameManager.check_for_winner()
		if winners.is_empty():
			print("No winner yet,\n continuing to next round.")
			await get_tree().create_timer(1.0).timeout  # Placeholder delay
			# TODO: Show round summary overlay

			_update_overlay("No winner yet,\nstarting next round...")
			_start_next_round()
		else:
			print("We have a winner: %s!" % winners[0].name)
			GameManager.game_ended.emit(winners[0])
			round_area.set_process_input(false)
			_update_overlay("The winner is\n%s!" % winners[0].name)
			# await get_tree().create_timer(2.0).timeout

func _update_all_badges() -> void:
	var badges = players_container.get_children()
	var current_player = PlayerManager.get_current_player()
	for i in range(badges.size()):
		if i < PlayerManager.players.size():
			var player = PlayerManager.players[i]
			badges[i].update_score(player.score)
			badges[i].set_current_player(player == current_player)

func _start_next_round() -> void:
	# the winner of the last round should still be current player. 
	var next_question = GameManager.get_next_question()
	if next_question:
		PlayerManager.unfreeze_all_players()
		GameManager.game.current_round += 1
		qna_instance.start_new_question(next_question)
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
	PlayerManager.clear_all_players()
	# Emit signal to main - let main handle scene cleanup
	return_to_home.emit()
