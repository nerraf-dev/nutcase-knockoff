extends Control

# GameBoard — scenes/screens/game_board.gd
# Manages the main game board scene. Hosts the HUD (player badges, controls) and
# the RoundArea (the active round scene, e.g. QnA).
#
# Responsibilities:
#   - Load and swap round scenes based on game type
#   - Process round results (correct/wrong answer) via _on_round_result
#   - Show transition overlay messages between rounds
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
signal network_vote_resolved(result: Dictionary)

# const player_badge = preload("res://scenes/components/player_badge.tscn")
const player_badge_sm = preload("res://scenes/components/player_badge_small.tscn")

@onready var controls = $HUD/Controls
@onready var options_btn = $HUD/OptionsBtn
@onready var exit_btn = $HUD/ExitBtn
@onready var players_container = $HUD/PlayersContainer
@onready var player_badges = $HUD/PlayerBadges

@onready var round_area = $RoundArea
@onready var exit_confirm = $AcceptDialog

const QUESTION_TRANSITION_SCENE: PackedScene = preload("res://scenes/screens/question_transition_overlay.tscn")
const OVERLAY_AUTO_DISMISS_SECONDS: float = 3.0

const ROUND_SCENES = {
	"qna": preload("res://scenes/components/rounds/qna.tscn")
	# Add other round types here as needed
}

const NETWORK_VOTE_TIMEOUT_SECONDS = 20.0

var round_instance = null
var _stored_focus_modes: Dictionary = {} # node path -> focus mode, used by _recursive_set_focus
var _overlay_accepting_remote: bool = false
var question_transition: Control = null
var _vote_session_active: bool = false
var _vote_session_guesser: Player = null
var _vote_session_correct_answer: String = ""
var _vote_session_eligible_by_device: Dictionary = {} # device_id -> Player
var _vote_session_votes_by_device: Dictionary = {} # device_id -> bool

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
	_setup_question_transition_overlay()
	exit_btn.pressed.connect(Callable(self , "_on_exit_btn_pressed"))
	options_btn.pressed.connect(Callable(self , "_on_options_btn_pressed"))
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
		NetworkManager.overlay_continue_received.connect(_on_network_overlay_continue)
		NetworkManager.vote_cast_received.connect(_on_network_vote_cast)
		_broadcast_scores_to_controllers()
		_broadcast_turn_to_controllers()


	# Enable input handling for overlay
	set_process_input(true)

func _setup_question_transition_overlay() -> void:
	# Use dedicated transition scene instead of inline board nodes.
	question_transition = QUESTION_TRANSITION_SCENE.instantiate() as Control
	if question_transition == null:
		push_error("Failed to instantiate question_transition_overlay.tscn")
		return

	question_transition.name = "QuestionTransition"
	question_transition.visible = false
	question_transition.z_index = 100
	add_child(question_transition)

	if not question_transition.has_method("show_message") or not question_transition.has_method("dismiss") or not question_transition.has_method("is_showing"):
		push_error("QuestionTransition scene script must implement show_message, dismiss, and is_showing")

func _update_overlay(msg: String) -> void:
	if question_transition == null:
		push_error("QuestionTransition overlay is not configured correctly")
		return

	_overlay_accepting_remote = true
	_broadcast_turn_to_controllers()
	_broadcast_overlay_prompt(true, msg)
	await question_transition.show_message(msg, OVERLAY_AUTO_DISMISS_SECONDS)

	_overlay_accepting_remote = false
	_broadcast_overlay_prompt(false, "")

func _input(event):
	# Allow A button / Enter to dismiss overlay
	if question_transition != null and question_transition.is_showing() and event.is_action_pressed("ui_accept"):
		question_transition.dismiss()
		get_viewport().set_input_as_handled()

## Sets up HUD: instantiates player badges (small) and displays them.
func _setup_players_hud() -> void:
	if player_badges.get_child_count() > 0:
		for child in player_badges.get_children():
			child.queue_free()
	for player in PlayerManager.players:
		var badge_instance = player_badge_sm.instantiate()
		player_badges.add_child(badge_instance)
		badge_instance.setup(player)

## Loads round scene based on game type and wires up round_result signal.
func _setup_round_area() -> void:
	var game_type = GameManager.game.game_type.to_lower()
	var round_scene: PackedScene = ROUND_SCENES.get(game_type, null)
	if round_scene == null:
		push_error("No round scene found for game type: %s" % game_type)
		return
	round_instance = round_scene.instantiate()
	round_area.add_child(round_instance)
	round_instance.connect("round_result", Callable(self , "_on_round_result"))
## Round result handler — dispatches to specific submission type handlers.
## Coordinates flow: wrong answer → freeze cascade, fuzzy → voting, exact → winner check
func _on_round_result(player: Player, is_correct: int, prize: int, submitted_answer: String) -> void:
	match is_correct:
		GameManager.SubmissionResult.INCORRECT:
			await _handle_incorrect_answer(player, prize, submitted_answer)
		GameManager.SubmissionResult.FUZZY:
			await _handle_fuzzy_answer(player, prize, submitted_answer)
		GameManager.SubmissionResult.EXACT, GameManager.SubmissionResult.AUTO_ACCEPT:
			var result = GameManager.handle_correct_answer(player, prize, is_correct, submitted_answer)
			await _handle_correct_result(result)

## Handles incorrect submission: freeze cascade, last standing free guess, LPS reveal-all.
func _handle_incorrect_answer(player: Player, prize: int, submitted_answer: String) -> void:
	var result = GameManager.handle_wrong_answer(player, prize, submitted_answer)
	print("RESULT DICT: %s" % str(result))
	_update_all_badges()
	
	# Simple freeze: player locked until next round
	if result["is_frozen"]:
		await _update_overlay(result["message"])
	
	# Last standing: only player left gets free guess
	if result["is_last_standing"]:
		await _update_overlay(result["message"])
		if round_instance:
			round_instance.show_answer_modal_for_free_guess()
	
	# LPS (Last Person Standing) wrong answer: all answers revealed, move to next round
	if result["is_lps_wrong"]:
		await _update_overlay(result["message"])
		await get_tree().create_timer(1.0).timeout
		_start_next_round()
		return
	
	# Edge case: no active players remain after wrong answer
	var has_no_special_end = not result["is_last_standing"] and not result["is_lps_wrong"]
	if has_no_special_end and PlayerManager.get_active_players().is_empty():
		await _update_overlay("No players left!\nStarting next round...")
		await get_tree().create_timer(1.0).timeout
		_start_next_round()

## Handles fuzzy (close-enough) answer: vote on acceptance or move to next round.
func _handle_fuzzy_answer(player: Player, prize: int, submitted_answer: String) -> void:
	# Find eligible voters: active (unfrozen) players who are not the guesser
	var eligible_voters: Array[Player] = []
	for p in PlayerManager.get_active_players():
		if p != player:
			eligible_voters.append(p)
	
	# No voters: auto-accept the answer
	if eligible_voters.is_empty():
		var result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY, submitted_answer)
		await _handle_correct_result(result)
		return

	# If multiplayer call to broadcast vote request
	#   wait for result
	# Else Local: keep current path
	if not NetworkManager.is_local:
		var network_voters: Array[Player] = []
		for voter in eligible_voters:
			if voter.device_id != "":
				network_voters.append(voter)
		if network_voters.is_empty():
			# Safety fallback in case no eligible voter has a mapped device.
			var no_device_result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY, submitted_answer)
			await _handle_correct_result(no_device_result)
			return

		_start_network_vote_session(player, submitted_answer, network_voters)
		var network_vote_result: Dictionary = await network_vote_resolved
		await _apply_fuzzy_vote_result(player, prize, submitted_answer, network_vote_result)
	else:
		# Show vote modal and wait for result
		var vote_modal = VoteModal.new()
		vote_modal.setup(player, submitted_answer, round_instance.current_question.answer, eligible_voters)
		add_child(vote_modal)
		var vote_result: Dictionary = await vote_modal.vote_resolved
		await _apply_fuzzy_vote_result(player, prize, submitted_answer, vote_result)

func _apply_fuzzy_vote_result(player: Player, prize: int, submitted_answer: String, vote_result: Dictionary) -> void:
	if vote_result.get("accepted", false):
		var result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY, submitted_answer)
		await _handle_correct_result(result)
		return

	# Vote rejected: distribute prize to "no" voters and continue
	var no_voters: Array[Player] = vote_result.get("no_voters", [])
	GameManager.handle_vote_rejection(prize, no_voters)
	_update_all_badges()

	if no_voters.is_empty():
		await _update_overlay("It's a tie!\nNobody wins the prize.")
	else:
		await _update_overlay("Rejected!\nThe prize was shared among those who voted no.")
	_start_next_round()

func _start_network_vote_session(guesser: Player, submitted_answer: String, eligible_voters: Array[Player]) -> void:
	_reset_vote_session()
	_vote_session_active = true
	_vote_session_guesser = guesser
	_vote_session_correct_answer = ""
	if round_instance and round_instance.get("current_question") != null:
		_vote_session_correct_answer = str(round_instance.current_question.answer)

	for voter in eligible_voters:
		_vote_session_eligible_by_device[voter.device_id] = voter

	print("Broadcasting vote request to controllers for fuzzy answer: '%s'" % submitted_answer)
	NetworkManager.broadcast_vote_request(guesser.id, submitted_answer)

	var timeout = get_tree().create_timer(NETWORK_VOTE_TIMEOUT_SECONDS)
	timeout.timeout.connect(_on_network_vote_timeout)

func _on_network_vote_timeout() -> void:
	if not _vote_session_active:
		return
	print("Network vote timed out after %.1f seconds, finalizing with received votes" % NETWORK_VOTE_TIMEOUT_SECONDS)
	_finalize_network_vote_session()

func _finalize_network_vote_session() -> void:
	if not _vote_session_active:
		return

	var yes_voters: Array[Player] = []
	var no_voters: Array[Player] = []
	for device_id in _vote_session_eligible_by_device.keys():
		var voter: Player = _vote_session_eligible_by_device[device_id]
		if _vote_session_votes_by_device.get(device_id, true):
			yes_voters.append(voter)
		else:
			no_voters.append(voter)

	var tied = yes_voters.size() == no_voters.size()
	var accepted = not tied and yes_voters.size() > no_voters.size()
	var vote_result = {
		"accepted": accepted,
		"yes_voters": yes_voters,
		"no_voters": no_voters
	}

	if not NetworkManager.is_local:
		NetworkManager.broadcast_vote_result(accepted, _vote_session_correct_answer)

	_reset_vote_session()
	network_vote_resolved.emit(vote_result)

func _reset_vote_session() -> void:
	_vote_session_active = false
	_vote_session_guesser = null
	_vote_session_correct_answer = ""
	_vote_session_eligible_by_device.clear()
	_vote_session_votes_by_device.clear()

## Checks for game-end condition; if winner exists, ends game; else shows overlay and loads next round.
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

## Syncs all player badge UI: score, current turn indicator, leader highlight. Also broadcasts to controllers.
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

## Callback: when PlayerManager emits turn_changed, refresh UI and notify controllers.
func _on_turn_changed(_player: Player) -> void:
	_update_all_badges()
	_broadcast_turn_to_controllers()

## Loads next question, unfreezes players, re-enables input focus, and broadcasts state.
func _start_next_round() -> void:
	_reset_vote_session()
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
		_broadcast_turn_to_controllers()
		
		# Re-enable focus after round loads (sliders will auto-focus)
		await get_tree().process_frame
		_set_round_focus(true)
	else:
		print("No more questions available!")

## Recursively enable/disable focus on all controls in the round (for local keyboard fallback).
func _set_round_focus(enabled: bool) -> void:
	if round_instance:
		_recursive_set_focus(round_instance, enabled)

## Internal: recursive traversal to toggle focus_mode on all child Controls.
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

## Network handler: validates sender is current player, then emits slider event to round.
func _on_network_slider_click(device_id: String, slider_index: int) -> void:
	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received slider click from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return
	if round_instance:
		round_instance.slider_reveal_requested.emit(slider_index)

## Network handler: validates sender is current player, then emits guess event to round.
func _on_network_guess(device_id: String, guess_text: String) -> void:
	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received guess from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return
	if round_instance:
		round_instance.guess_submitted.emit(guess_text)

## Network handler: validates sender is current player and overlay is active, then dismisses overlay.
func _on_network_overlay_continue(device_id: String) -> void:
	if not _overlay_accepting_remote or question_transition == null or not question_transition.is_showing():
		return

	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received overlay continue from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return

	question_transition.dismiss()

## If multiplayer, send all player scores to connected controllers.
func _broadcast_scores_to_controllers() -> void:
	if NetworkManager.is_local:
		return
	NetworkManager.broadcast_scores(PlayerManager.players)

## If multiplayer, broadcast current player and send "your turn" to their device.
func _broadcast_turn_to_controllers() -> void:
	if NetworkManager.is_local:
		return

	var current = PlayerManager.get_current_player()
	if current == null:
		return

	NetworkManager.broadcast_turn_changed(current.id)
	if current.device_id != "":
		NetworkManager.broadcast_your_turn(current.device_id)

## If multiplayer, send round number and slider count to controllers.
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

## If multiplayer, show/hide overlay prompt on controllers with optional message.
func _broadcast_overlay_prompt(active: bool, message: String) -> void:
	if NetworkManager.is_local:
		return
	NetworkManager.broadcast_overlay_prompt(active, message)

func _on_network_vote_cast(device_id: String, accept: bool) -> void:
	if not _vote_session_active:
		return
	if not _vote_session_eligible_by_device.has(device_id):
		push_warning("Ignoring vote from ineligible device %s" % device_id)
		return
	if _vote_session_votes_by_device.has(device_id):
		push_warning("Ignoring duplicate vote from device %s" % device_id)
		return

	var sender = PlayerManager.get_player_by_device_id(device_id)
	if sender == null:
		print("Received vote from unknown device %s" % device_id)
		return

	_vote_session_votes_by_device[device_id] = accept
	print("Vote received from %s: %s (%d/%d)" % [sender.name, "accept" if accept else "reject", _vote_session_votes_by_device.size(), _vote_session_eligible_by_device.size()])

	if _vote_session_votes_by_device.size() >= _vote_session_eligible_by_device.size():
		_finalize_network_vote_session()

## Button handlers
## Called when options button is pressed. (Placeholder for future implementation.)
func _on_options_btn_pressed() -> void:
	print("Options button pressed")

## Called when exit button is pressed; shows confirmation dialog.
func _on_exit_btn_pressed() -> void:
	print("Exit button pressed")
	exit_confirm.dialog_text = "Are you sure you want to exit to main menu?"
	exit_confirm.popup_centered()

## Confirmed exit: stops network server, resets game state, returns to home.
func _on_exit_confirmed() -> void:
	print("Exit confirmed, returning to main menu")
	_reset_vote_session()
	if not NetworkManager.is_local:
		NetworkManager.stop_server()
	# Reset game state
	GameManager.game = null
	GameManager.current_state = GameManager.GameState.NONE
	PlayerManager.clear_all_players()
	return_to_home.emit()
