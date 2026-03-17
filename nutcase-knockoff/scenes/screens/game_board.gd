extends Control

# GameBoard — scenes/screens/game_board.gd
# Manages the main game board scene. Hosts the HUD (player badges, controls) and
# the RoundArea (the active round scene, e.g. QnA).
#
# Responsibilities:
#   - Load and swap round scenes based on game type
#   - Process round results (correct/wrong answer) via _on_round_result
#   - Show result overlay messages between rounds
#   - Update player badges (score, current player, leader)
#
# MULTIPLAYER TODO:
#   - In multiplayer, the "Guess" button and slider clicks come from phones via
#     NetworkManager, not from this screen. This scene remains the authoritative
#     display but stops being the input surface for players.
#   - The result overlay (_update_overlay) is host-only; player phones will need
#     their own state-change feedback (e.g. "Wrong! -50pts" on their device).
#   - _recursive_set_focus / focus management becomes less critical once input
#     moves to phones, but keep it for the host's local keyboard fallback.

signal return_to_home
signal game_ended(winner: Player)

# const player_badge = preload("res://scenes/components/player_badge.tscn")
const player_badge_sm = preload("res://scenes/components/player_badge_small.tscn")

@onready var controls = $HUD/Controls
@onready var options_btn = $HUD/Controls/OptionsBtn
@onready var exit_btn = $HUD/Controls/ExitBtn
@onready var players_container = $HUD/PlayersContainer
@onready var player_badges = $HUD/PlayerBadges

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
var _stored_focus_modes: Dictionary = {}  # node path -> focus mode, used by _recursive_set_focus

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Validate game state
	if GameManager.current_state != GameManager.GameState.IN_PROGRESS:
		push_warning("Game Board loaded but game not in IN_PROGRESS state: %s" % GameManager.GameState.keys()[GameManager.current_state])
	if GameManager.game == null:
		push_error("Game Board loaded but no game exists!")
		return
	print("Game Board scene ready")
	res_overlay.visible = false
	exit_btn.pressed.connect(Callable(self, "_on_exit_btn_pressed"))
	options_btn.pressed.connect(Callable(self, "_on_options_btn_pressed"))
	exit_confirm.confirmed.connect(_on_exit_confirmed)
	
	# Connect to turn changes to update current player indicator
	PlayerManager.turn_changed.connect(_on_turn_changed)
	_setup_players_hud()
	_setup_round_area()
	await get_tree().process_frame
	_broadcast_new_round_to_controllers()

	if not NetworkManager.is_local:
		NetworkManager.slider_click_received.connect(_on_network_slider_click)
		NetworkManager.guess_received.connect(_on_network_guess)
		_broadcast_scores_to_controllers()
		_broadcast_turn_to_controllers()


	# Enable input handling for overlay
	set_process_input(true)

func _update_overlay(msg: String) -> void:
	res_label.text = msg
	res_overlay.visible = true
	res_next_btn.grab_focus()  # Auto-focus for controller
	await res_next_btn.pressed
	res_overlay.visible = false

func _input(event):
	# Allow A button / Enter to dismiss overlay
	if res_overlay.visible and event.is_action_pressed("ui_accept"):
		res_next_btn.emit_signal("pressed")
		get_viewport().set_input_as_handled()

func  _setup_players_hud() -> void:
	# if players_container.get_child_count() > 0:
	# 	for child in players_container.get_children():
	# 		child.queue_free()
	# for player in PlayerManager.players:
	# 	var badge_instance = player_badge.instantiate()
	# 	players_container.add_child(badge_instance)
	# 	badge_instance.setup(player)

	if player_badges.get_child_count() > 0:
		for child in player_badges.get_children():
			child.queue_free()
	for player in PlayerManager.players:
		var badge_instance = player_badge_sm.instantiate()
		player_badges.add_child(badge_instance)
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

func _on_round_result(player: Player, is_correct: int, prize: int, submitted_answer: String) -> void:
	if is_correct == GameManager.SubmissionResult.INCORRECT:
		var result = GameManager.handle_wrong_answer(player, prize)
		print("RESULT DICT: %s" % str(result))
		_update_all_badges()
		
		if result["is_frozen"]:
			await _update_overlay(result["message"])
		
		if result["is_last_standing"]:
			await _update_overlay(result["message"])
			# Auto-show answer modal for free guess
			if round_instance:
				round_instance.show_answer_modal_for_free_guess()
		
		# Handle LPS wrong answer - show correct answer and move to next round
		if result["is_lps_wrong"]:
			await _update_overlay(result["message"])
			await get_tree().create_timer(1.0).timeout
			_start_next_round()
		
		# Handle edge case: no active players left
		var no_special_end_condition = not result["is_last_standing"] and not result["is_lps_wrong"]
		var no_active_players_left = PlayerManager.get_active_players().size() == 0
		if no_special_end_condition and no_active_players_left:
			await _update_overlay("No players left!\nStarting next round...")
			await get_tree().create_timer(1.0).timeout
			_start_next_round()
	elif is_correct == GameManager.SubmissionResult.FUZZY:
		# Find eligible voters: active (unfrozen) players who are not the guesser
		var eligible_voters: Array[Player] = []
		for p in PlayerManager.get_active_players():
			if p != player:
				eligible_voters.append(p)
		
		if eligible_voters.is_empty():
			# No one to vote — auto-accept silently
			var result = GameManager.handle_correct_answer(player, prize, is_correct)
			await _handle_correct_result(result)
		else:
			var vote_modal = VoteModal.new()
			vote_modal.setup(player, submitted_answer, round_instance.current_question.answer, eligible_voters)
			add_child(vote_modal)
			var vote_result: Dictionary = await vote_modal.vote_resolved
			
			if vote_result["accepted"]:
				var result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY)
				await _handle_correct_result(result)
			else:
				var no_voters: Array[Player] = vote_result["no_voters"]
				GameManager.handle_vote_rejection(prize, no_voters)
				_update_all_badges()
				if no_voters.is_empty():
					await _update_overlay("It's a tie!\nNobody wins the prize.")
				else:
					await _update_overlay("Rejected!\nThe prize was shared among those who voted no.")
				_start_next_round()

	elif is_correct == GameManager.SubmissionResult.EXACT or is_correct == GameManager.SubmissionResult.AUTO_ACCEPT:
		var result = GameManager.handle_correct_answer(player, prize, is_correct)
		await _handle_correct_result(result)

	# hook for multiplayer: emit signal to send round result to clients so they can update their displays (e.g. show correct answer, update scores)

func _handle_correct_result(result: Dictionary) -> void:
	_update_all_badges()
	if result["has_winner"]:
		GameManager.game.record_round_result(GameManager.game.current_round, GameManager.game.current_question, result)
		round_area.set_process_input(false)
		GameManager.game_ended.emit(result["winner"])
		game_ended.emit(result["winner"])
	else:
		await _update_overlay(result["message"])
		await _update_overlay("No winner yet,\nstarting next round...")
		_start_next_round()

func _update_all_badges() -> void:
	var badges = player_badges.get_children()
	var current_player = PlayerManager.get_current_player()
	var leaders = PlayerManager.get_leaders()
	
	for i in range(badges.size()):
		if i < PlayerManager.players.size():
			var player = PlayerManager.players[i]
			badges[i].update_score(player.score)
			badges[i].set_current_player(player == current_player)
			badges[i].set_current_leader(leaders.has(player))

	_broadcast_scores_to_controllers()

func _on_turn_changed(_player: Player) -> void:
	# Update badges when turn changes
	_update_all_badges()
	_broadcast_turn_to_controllers()

func _start_next_round() -> void:
	# Record the completed round before moving on
	if GameManager.game and GameManager.game.current_question:
		GameManager.game.record_round_result(GameManager.game.current_round, GameManager.game.current_question, {})
	
	# Disable focus on existing round before loading new one
	if round_instance:
		_set_round_focus(false)
	
	# Load next question
	var next_question = GameManager.get_next_question()
	if next_question:
		PlayerManager.unfreeze_all_players()
		GameManager.game.current_round += 1
		round_instance.start_new_question(next_question)
		_broadcast_new_round_to_controllers()
		
		# Re-enable focus after round loads (sliders will auto-focus)
		await get_tree().process_frame
		_set_round_focus(true)
	else:
		print("No more questions available!")

func _set_round_focus(enabled: bool) -> void:
	# Recursively enable/disable focus on all round controls
	if round_instance:
		_recursive_set_focus(round_instance, enabled)

func _recursive_set_focus(node: Node, enabled: bool) -> void:
	if node is Control:
		if enabled:
			var key = node.get_path()
			if _stored_focus_modes.has(key):
				node.focus_mode = _stored_focus_modes[key]
				_stored_focus_modes.erase(key)
		else:
			if node.focus_mode != Control.FOCUS_NONE:
				_stored_focus_modes[node.get_path()] = node.focus_mode
				node.focus_mode = Control.FOCUS_NONE
	
	for child in node.get_children():
		_recursive_set_focus(child, enabled)

#  Network event handlers for multiplayer input
func _on_network_slider_click(device_id: String, slider_index: int) -> void:
	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received slider click from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return
	if round_instance:
		round_instance.slider_reveal_requested.emit(slider_index)

func _on_network_guess(device_id: String, guess_text: String) -> void:
	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received guess from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return
	if round_instance:
		round_instance.guess_submitted.emit(guess_text)

func _broadcast_scores_to_controllers() -> void:
	if NetworkManager.is_local:
		return
	NetworkManager.broadcast_scores(PlayerManager.players)

func _broadcast_turn_to_controllers() -> void:
	if NetworkManager.is_local:
		return

	var current = PlayerManager.get_current_player()
	if current == null:
		return

	NetworkManager.broadcast_turn_changed(current.id)
	if current.device_id != "":
		NetworkManager.broadcast_your_turn(current.device_id)

func _broadcast_new_round_to_controllers() -> void:
	if NetworkManager.is_local:
		return
	if round_instance == null:
		return

	var slider_count := 9
	if round_instance.has_method("get") and round_instance.get("current_question") != null:
		var words = round_instance.current_question.question_text.split(" ")
		slider_count = words.size()

	NetworkManager.broadcast_new_round(GameManager.game.current_round, slider_count)


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
