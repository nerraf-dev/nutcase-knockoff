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
signal return_to_lobby(settings: Dictionary)
signal game_ended(winner: Player)
signal network_vote_resolved(result: Dictionary)

# const player_badge = preload("res://scenes/components/player_badge.tscn")
const player_badge_sm = preload("res://scenes/components/player_badge_small.tscn")

@onready var controls = $HUD/Controls
@onready var options_btn = $HUD/OptionsBtn
@onready var exit_btn = $HUD/ExitBtn
# @onready var players_container = $HUD/PlayersContainer
@onready var player_badges = $HUD/PlayerBadges


@onready var round_area = $RoundArea
@onready var exit_confirm = $AcceptDialog

const QUESTION_TRANSITION_SCENE: PackedScene = preload("res://scenes/screens/question_transition_overlay.tscn")
const OPTIONS_CONTENT_SCENE: PackedScene = preload("res://scenes/screens/options_content.tscn")
const OVERLAY_AUTO_DISMISS_SECONDS: float = 3.0

const ROUND_SCENES = {
	"qna": preload("res://scenes/components/rounds/qna.tscn")
	# Add other round types here as needed
}

const NETWORK_VOTE_TIMEOUT_SECONDS = 20.0
const DisconnectPolicyScript = preload("res://scripts/logic/GameBoardDisconnectPolicy.gd")
const VoteSessionScript = preload("res://scripts/logic/GameBoardVoteSession.gd")
const ControllerSyncScript = preload("res://scripts/logic/GameBoardControllerSync.gd")

var round_instance = null
var _stored_focus_modes: Dictionary = {} # node path -> focus mode, used by _recursive_set_focus
var _exit_dialog_disabled_states: Dictionary = {} # node path -> previous disabled state
var _exit_dialog_open: bool = false
var _round_area_mouse_filter_before_exit: int = Control.MOUSE_FILTER_STOP
var _round_area_mouse_filter_before_options: int = Control.MOUSE_FILTER_STOP
var _overlay_accepting_remote: bool = false
var question_transition: Control = null
var _disconnect_policy: GameBoardDisconnectPolicy = null
var _vote_session: GameBoardVoteSession = null
var _controller_sync: GameBoardControllerSync = null
var _options_open: bool = false
var _options_overlay: ColorRect = null
var _options_content_instance: Control = null
var _options_disabled_states: Dictionary = {}

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
	exit_confirm.visibility_changed.connect(_on_exit_confirm_popup_hide)
	
	# Connect to turn changes to update current player indicator
	PlayerManager.turn_changed.connect(_on_turn_changed)
	_setup_players_hud()
	_setup_round_area()
	_disconnect_policy = DisconnectPolicyScript.new(self )
	_vote_session = VoteSessionScript.new(self )
	_controller_sync = ControllerSyncScript.new(self )
	await get_tree().process_frame
	_broadcast_new_round_to_controllers()

	if not NetworkManager.is_local:
		NetworkManager.player_join_received.connect(_on_network_player_join_during_game)
		NetworkManager.client_disconnected.connect(_on_network_client_disconnected)
		NetworkManager.slider_click_received.connect(_on_network_slider_click)
		NetworkManager.guess_started_received.connect(_on_network_guess_started)
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

	# Allow B / Esc to close in-game options overlay
	if _options_open and event.is_action_pressed("ui_cancel"):
		_hide_options_overlay()
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
			var result = GameManager.handle_correct_answer(player, prize, is_correct, submitted_answer, _get_round_score_breakdown(prize))
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
		# In local play, show modal automatically. In network mode, controller handles guess input.
		if NetworkManager.is_local and round_instance:
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
	if _vote_session:
		await _vote_session.handle_fuzzy_answer(player, prize, submitted_answer, _get_round_score_breakdown(prize))

func _get_round_score_breakdown(prize: int) -> Dictionary:
	if round_instance and round_instance.has_method("get_current_score_breakdown"):
		var breakdown = round_instance.get_current_score_breakdown()
		if breakdown is Dictionary:
			breakdown["total_points"] = prize
			return breakdown
	return {
		"base_points": prize,
		"bonus_points": 0,
		"total_points": prize
	}

func _reset_vote_session() -> void:
	if _vote_session:
		_vote_session.reset_vote_session()

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
			if badges[i].has_method("update_identity"):
				badges[i].update_identity(player.name, player.avatar_index)
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
	if _disconnect_policy:
		_disconnect_policy.on_start_next_round()
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
		# Extra turn sync on the next idle tick ensures controllers recover if a
		# late/queued new_round packet temporarily reset their turn-known state.
		call_deferred("_broadcast_turn_to_controllers")
		
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

## Network handler: validates sender is current player, then updates round UI to show guess is being typed.
func _on_network_guess_started(device_id: String) -> void:
	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received guess_start from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return
	if round_instance and round_instance.has_method("begin_guessing"):
		round_instance.begin_guessing(sender.name)

## Network handler: validates sender is current player, then emits guess event to round.
func _on_network_guess(device_id: String, guess_text: String) -> void:
	if _disconnect_policy:
		_disconnect_policy.handle_network_guess(device_id, guess_text)

## Network handler: delegate in-game profile updates and reconnect handling to the disconnect policy helper.
func _on_network_player_join_during_game(device_id: String, player_name: String, avatar_index: int) -> void:
	if _disconnect_policy:
		_disconnect_policy.handle_network_player_join_during_game(device_id, player_name, avatar_index)


func _on_network_client_disconnected(device_id: String) -> void:
	if _disconnect_policy:
		_disconnect_policy.handle_network_client_disconnected(device_id)


func _show_disconnect_lps_prompt(player_id: String) -> void:
	var survivor = PlayerManager.get_player_by_id(player_id)
	if survivor == null:
		if _disconnect_policy:
			_disconnect_policy.on_disconnect_match_end()
		return

	await _update_overlay("%s is last standing among connected players!\nFree guess." % survivor.name)
	if NetworkManager.is_local and round_instance:
		round_instance.show_answer_modal_for_free_guess()

	if _disconnect_policy:
		_disconnect_policy.on_disconnect_match_end()


func _resolve_disconnect_match_end(winner_player_id: String) -> void:
	var winner: Player = null
	if not winner_player_id.is_empty():
		winner = PlayerManager.get_player_by_id(winner_player_id)

	if winner != null:
		await _update_overlay("%s wins by default!\nReturning to lobby..." % winner.name)
	else:
		await _update_overlay("All players disconnected.\nReturning to lobby...")

	var lobby_settings = _build_lobby_settings_from_current_game()
	_reset_vote_session()

	if _disconnect_policy:
		_disconnect_policy.clear_all()
		_disconnect_policy.on_disconnect_match_end()

	if not NetworkManager.is_local:
		NetworkManager.stop_server()

	GameManager.game = null
	PlayerManager.clear_all_players()

	return_to_lobby.emit(lobby_settings)


func _build_lobby_settings_from_current_game() -> Dictionary:
	var settings = {
		"game_mode": "multi",
		"game_type": "qna",
		"game_target": 200,
		"fuzzy_enabled": GameConfig.FUZZY_ENABLED_DEFAULT,
	}

	if GameManager.game != null:
		settings["game_mode"] = GameManager.game.game_mode
		settings["game_type"] = GameManager.game.game_type
		settings["game_target"] = GameManager.game.game_target
		settings["fuzzy_enabled"] = GameManager.game.fuzzy_enabled

	return settings

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
	if _controller_sync:
		_controller_sync.broadcast_scores()

## If multiplayer, broadcast current player and send "your turn" to their device.
func _broadcast_turn_to_controllers() -> void:
	if _controller_sync:
		_controller_sync.broadcast_turn()

## If multiplayer, send round number and slider count to controllers.
func _broadcast_new_round_to_controllers() -> void:
	if _controller_sync:
		_controller_sync.broadcast_new_round()

## If multiplayer, show/hide overlay prompt on controllers with optional message.
func _broadcast_overlay_prompt(active: bool, message: String) -> void:
	if _controller_sync:
		_controller_sync.broadcast_overlay_prompt(active, message)

func _on_network_vote_cast(device_id: String, accept: bool) -> void:
	if _vote_session:
		_vote_session.handle_network_vote_cast(device_id, accept)

## Button handlers
func _on_options_btn_pressed() -> void:
	print("Options button pressed")
	UISfx.play_ui_click()
	if _options_open:
		_hide_options_overlay()
	else:
		_show_options_overlay()


func _show_options_overlay() -> void:
	if _options_open or _exit_dialog_open:
		return

	if _options_overlay == null:
		_options_overlay = ColorRect.new()
		_options_overlay.name = "InGameOptionsOverlay"
		_options_overlay.anchors_preset = Control.PRESET_FULL_RECT
		_options_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_options_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
		_options_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		_options_overlay.color = Color(0, 0, 0, 0.45)
		_options_overlay.z_index = 95
		add_child(_options_overlay)

	if _options_content_instance == null:
		var options_node = OPTIONS_CONTENT_SCENE.instantiate()
		if options_node is Control:
			_options_content_instance = options_node as Control
			_options_content_instance.name = "InGameOptionsContent"
			if _options_content_instance.has_signal("close_requested"):
				_options_content_instance.connect("close_requested", Callable(self , "_hide_options_overlay"))
			_options_overlay.add_child(_options_content_instance)
		else:
			push_error("options_content.tscn root must be a Control")
			return

	_options_overlay.visible = true
	_options_content_instance.visible = true
	_options_open = true

	_set_round_focus(false)
	if round_area is Control:
		var round_control := round_area as Control
		_round_area_mouse_filter_before_options = round_control.mouse_filter
		round_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for node in [exit_btn]:
		var button := node as BaseButton
		if button == null:
			continue
		var key = button.get_path()
		if not _options_disabled_states.has(key):
			_options_disabled_states[key] = button.disabled
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE


func _hide_options_overlay() -> void:
	if not _options_open:
		return

	if _options_content_instance:
		_options_content_instance.visible = false
	if _options_overlay:
		_options_overlay.visible = false
	_options_open = false

	_set_round_focus(true)
	if round_area is Control:
		(round_area as Control).mouse_filter = _round_area_mouse_filter_before_options as Control.MouseFilter

	for node in [exit_btn]:
		var button := node as BaseButton
		if button == null:
			continue
		var key = button.get_path()
		if _options_disabled_states.has(key):
			button.disabled = _options_disabled_states[key]
			_options_disabled_states.erase(key)
		button.focus_mode = Control.FOCUS_ALL

## Called when exit button is pressed; shows confirmation dialog.
func _on_exit_btn_pressed() -> void:
	print("Exit button pressed")
	UISfx.play_ui_click()
	_set_exit_dialog_background_enabled(false)
	exit_confirm.dialog_text = "Are you sure you want to exit to main menu?"
	exit_confirm.popup_centered()

func _set_exit_dialog_background_enabled(enabled: bool) -> void:
	if enabled:
		for node in [options_btn, exit_btn]:
			var button := node as BaseButton
			if button == null:
				continue
			var key = button.get_path()
			button.focus_mode = Control.FOCUS_ALL
			if _exit_dialog_disabled_states.has(key):
				button.disabled = _exit_dialog_disabled_states[key]
				_exit_dialog_disabled_states.erase(key)

		_set_round_focus(true)
		if round_area is Control:
			(round_area as Control).mouse_filter = _round_area_mouse_filter_before_exit as Control.MouseFilter
		_exit_dialog_open = false
		return

	if _exit_dialog_open:
		return

	_exit_dialog_open = true
	for node in [options_btn, exit_btn]:
		var button := node as BaseButton
		if button == null:
			continue
		var key = button.get_path()
		if not _exit_dialog_disabled_states.has(key):
			_exit_dialog_disabled_states[key] = button.disabled
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE

	_set_round_focus(false)
	if round_area is Control:
		var round_control := round_area as Control
		_round_area_mouse_filter_before_exit = round_control.mouse_filter
		round_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_exit_confirm_popup_hide() -> void:
	_set_exit_dialog_background_enabled(true)

## Confirmed exit: stops network server, resets game state, returns to home.
func _on_exit_confirmed() -> void:
	print("Exit confirmed, returning to main menu")
	UISfx.play_ui_click()
	_reset_vote_session()
	if not NetworkManager.is_local:
		NetworkManager.stop_server()
	# Reset game state
	GameManager.game = null
	GameManager.current_state = GameManager.GameState.NONE
	PlayerManager.clear_all_players()
	return_to_home.emit()
