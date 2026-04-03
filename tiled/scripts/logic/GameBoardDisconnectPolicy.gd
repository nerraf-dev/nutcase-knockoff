extends RefCounted

class_name GameBoardDisconnectPolicy

const DISCONNECT_GRACE_SECONDS := 20.0
const DISCONNECT_MIN_CONNECTED_PLAYERS := 2

var board: Node = null
var _disconnect_grace_timers_by_player_id: Dictionary = {} # player_id -> SceneTreeTimer
var _disconnect_resolution_in_progress: bool = false
var _forced_guess_player_id: String = ""


func _init(p_board: Node = null) -> void:
	board = p_board


func handle_network_player_join_during_game(device_id: String, player_name: String, avatar_index: int) -> void:
	if board == null or GameManager.current_state != GameManager.GameState.IN_PROGRESS:
		return

	var player_by_device = PlayerManager.get_player_by_device_id(device_id)
	if player_by_device != null:
		var changed_identity = player_by_device.name != player_name or player_by_device.avatar_index != avatar_index
		player_by_device.name = player_name
		player_by_device.avatar_index = avatar_index
		if changed_identity:
			print("Updated in-game profile for %s" % player_by_device.id)
			board._update_all_badges()
		_sync_rejoined_controller_state(device_id)
		board._broadcast_turn_to_controllers()
		return

	for player in PlayerManager.players:
		if player.name.to_lower() == player_name.to_lower():
			_clear_disconnect_grace_timer(player.id)
			player.device_id = device_id
			player.name = player_name
			player.avatar_index = avatar_index
			print("Reconnected player %s to device %s during game" % [player.name, device_id])
			board._update_all_badges()
			_sync_rejoined_controller_state(device_id)
			board._broadcast_turn_to_controllers()
			return


func handle_network_client_disconnected(device_id: String) -> void:
	if board == null or GameManager.current_state != GameManager.GameState.IN_PROGRESS:
		return

	var player = PlayerManager.get_player_by_device_id(device_id)
	if player == null:
		return

	player.device_id = ""
	if player.id == _forced_guess_player_id:
		_forced_guess_player_id = ""
	_arm_disconnect_grace_timer(player)
	board._broadcast_turn_to_controllers()


func handle_network_guess(device_id: String, guess_text: String) -> void:
	if board == null:
		return

	var sender = PlayerManager.get_player_by_device_id(device_id)
	var current = PlayerManager.get_current_player()
	if sender == null or sender != current:
		print("Received guess from %s but it's %s's turn" % [sender.name if sender else "Unknown", current.name if current else "None"])
		return
	if sender.id == _forced_guess_player_id:
		_forced_guess_player_id = ""
	if board.round_instance:
		board.round_instance.guess_submitted.emit(guess_text)


func arm_current_turn_forced_guess() -> void:
	var survivor = _get_connected_survivor()
	if survivor == null:
		return

	_forced_guess_player_id = survivor.id
	var current = PlayerManager.get_current_player()
	if current == null or current.id != survivor.id:
		for i in range(PlayerManager.players.size()):
			if PlayerManager.players[i].id == survivor.id:
				PlayerManager.current_turn_index = i
				PlayerManager.turn_changed.emit(survivor)
				break

	if not survivor.device_id.is_empty() and not NetworkManager.is_local:
		NetworkManager.send_to_player(survivor.device_id, {"type": "force_guess"})


func clear_forced_guess() -> void:
	_forced_guess_player_id = ""


func clear_all() -> void:
	_disconnect_grace_timers_by_player_id.clear()
	_disconnect_resolution_in_progress = false
	_forced_guess_player_id = ""


func sync_rejoined_controller_state(device_id: String) -> void:
	_sync_rejoined_controller_state(device_id)


func on_disconnect_match_end() -> void:
	_disconnect_resolution_in_progress = false


func on_start_next_round() -> void:
	_forced_guess_player_id = ""


func _arm_disconnect_grace_timer(player: Player) -> void:
	_clear_disconnect_grace_timer(player.id)
	print("Player %s disconnected. Waiting %.1fs for reconnect." % [player.name, DISCONNECT_GRACE_SECONDS])
	var timer = board.get_tree().create_timer(DISCONNECT_GRACE_SECONDS)
	_disconnect_grace_timers_by_player_id[player.id] = timer
	timer.timeout.connect(_on_disconnect_grace_timeout.bind(player.id))


func _on_disconnect_grace_timeout(player_id: String) -> void:
	_disconnect_grace_timers_by_player_id.erase(player_id)
	var player = PlayerManager.get_player_by_id(player_id)
	if player == null:
		return
	if not player.device_id.is_empty():
		return

	print("Player %s did not reconnect within grace window." % player.name)
	var current = PlayerManager.get_current_player()
	if current != null and current.id == player_id:
		print("Disconnected player was current turn; advancing turn.")
		PlayerManager.next_turn()
		board._broadcast_turn_to_controllers()

	_evaluate_post_disconnect_state()


func _clear_disconnect_grace_timer(player_id: String) -> void:
	if _disconnect_grace_timers_by_player_id.has(player_id):
		_disconnect_grace_timers_by_player_id.erase(player_id)


func _evaluate_post_disconnect_state() -> void:
	if NetworkManager.is_local or GameManager.current_state != GameManager.GameState.IN_PROGRESS:
		return
	if _disconnect_resolution_in_progress:
		return

	var connected_players = _get_connected_players()
	if connected_players.size() >= DISCONNECT_MIN_CONNECTED_PLAYERS:
		_handle_disconnect_lps_edge(connected_players)
		return

	_disconnect_resolution_in_progress = true
	var winner_id = ""
	if connected_players.size() == 1:
		winner_id = connected_players[0].id
	board.call_deferred("_resolve_disconnect_match_end", winner_id)


func _handle_disconnect_lps_edge(connected_players: Array[Player]) -> void:
	if connected_players.size() != 2:
		return

	var connected_active: Array[Player] = []
	for player in connected_players:
		if not player.is_frozen:
			connected_active.append(player)

	if connected_active.size() != 1:
		return

	var survivor = connected_active[0]
	_forced_guess_player_id = survivor.id
	var current = PlayerManager.get_current_player()
	if current == null or current.id != survivor.id:
		for i in range(PlayerManager.players.size()):
			if PlayerManager.players[i].id == survivor.id:
				PlayerManager.current_turn_index = i
				PlayerManager.turn_changed.emit(survivor)
				break

	if not survivor.device_id.is_empty() and not NetworkManager.is_local:
		NetworkManager.send_to_player(survivor.device_id, {"type": "force_guess"})

	if _disconnect_resolution_in_progress:
		return
	_disconnect_resolution_in_progress = true
	board.call_deferred("_show_disconnect_lps_prompt", survivor.id)


func _get_connected_players() -> Array[Player]:
	var connected: Array[Player] = []
	for player in PlayerManager.players:
		if not player.device_id.is_empty():
			connected.append(player)
	return connected


func _get_connected_survivor() -> Player:
	var connected_players = _get_connected_players()
	if connected_players.size() != 2:
		return null

	var connected_active: Array[Player] = []
	for player in connected_players:
		if not player.is_frozen:
			connected_active.append(player)

	if connected_active.size() != 1:
		return null

	return connected_active[0]


func _sync_rejoined_controller_state(device_id: String) -> void:
	if NetworkManager.is_local or device_id.is_empty() or board == null:
		return

	NetworkManager.send_to_player(device_id, {"type": "game_started"})

	var slider_count := 9
	if board.round_instance and board.round_instance.get("current_question") != null:
		slider_count = board.round_instance.current_question.question_text.split(" ").size()
	NetworkManager.send_to_player(device_id, {
		"type": "new_round",
		"round_num": GameManager.game.current_round,
		"slider_count": slider_count
	})

	var current = PlayerManager.get_current_player()
	if current != null:
		NetworkManager.send_to_player(device_id, {"type": "turn_changed", "player_id": current.id})
		if current.device_id == device_id:
			NetworkManager.send_to_player(device_id, {"type": "your_turn"})
			if current.id == _forced_guess_player_id:
				NetworkManager.send_to_player(device_id, {"type": "force_guess"})

	var score_payload: Array = []
	for p in PlayerManager.players:
		score_payload.append({"id": p.id, "name": p.name, "score": p.score})
	NetworkManager.send_to_player(device_id, {"type": "scores", "players": score_payload})
