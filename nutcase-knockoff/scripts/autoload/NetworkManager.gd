# NetworkManager — scripts/autoload/NetworkManager.gd
# Autoload. Manages WebSocket server for Jackbox-style phone controllers.
#
# ARCHITECTURE
#   - Host device runs a WebSocketServer on GameConfig.WEBSOCKET_PORT.
#   - Each phone controller connects as a WebSocket client.
#   - All messages are JSON strings: { "type": "...", ...payload }
#
# LOCAL MODE
#   When is_local = true (default) all network methods are no-ops.
#   Local play is completely unaffected — no code path changes elsewhere.
#
# SIGNAL FLOW (server → game layer)
#   Incoming messages from clients are validated and re-emitted as typed signals.
#   The game layer (game_board, VoteModal, lobby screen) connects to these signals.
#
# MESSAGE PROTOCOL  (client → server)
#   join          { type, name, avatar_index }    — player joining lobby
#   ready         { type }                         — player ready to start
#   slider_click  { type, index }                  — reveal a slider tile
#   guess         { type, answer }                 — submit a guess
#   vote          { type, accepted }               — cast a vote (FUZZY round)
#
# MESSAGE PROTOCOL  (server → client)
#   room_joined   { type, player_id, room_code }   — join confirmed
#   error         { type, message }                — join/validation error
#   game_started  { type }                         — lobby closed, game beginning
#   new_round     { type, round_num, slider_count } — new round beginning
#   your_turn     { type }                         — sent to the active player
#   slider_revealed { type, index, word }          — a tile was revealed
#   turn_changed  { type, player_id }              — whose turn it is
#   vote_request  { type, guesser_id, answer }     — FUZZY round: cast a vote
#   vote_result   { type, accepted, correct_answer } — vote outcome revealed
#   scores        { type, players: [{id, name, score}...] }
#   round_end     { type, correct_answer, winner_id } — "" if no winner
#   game_over     { type, winner_id, winner_name }
extends Node

# ---------------------------------------------------------------------------
# Signals — emitted when validated client messages arrive
# ---------------------------------------------------------------------------
signal client_connected(device_id: String)
signal client_disconnected(device_id: String)
signal player_join_received(device_id: String, player_name: String, avatar_index: int)
signal player_ready_received(device_id: String, is_ready: bool)
signal slider_click_received(device_id: String, index: int)
signal guess_received(device_id: String, answer: String)
signal vote_cast_received(device_id: String, accepted: bool)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var is_local: bool = true
var room_code: String = ""

var _server: WebSocketMultiplayerPeer = null
# Map: peer_id (int) → device_id (String)  — device_id is the string form of peer_id
var _peer_ids: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Nothing to do until start_server() is called.
	pass

func _process(_delta: float) -> void:
	if is_local or _server == null:
		return
	_server.poll()
	_process_events()

# ---------------------------------------------------------------------------
# Public API — server control
# ---------------------------------------------------------------------------

## Start the WebSocket server and generate a room code.
## Returns true on success, false if already running or bind failed.
func start_server() -> bool:
	if is_local:
		return false
	if _server != null:
		push_warning("NetworkManager: start_server() called while already running")
		return false

	_server = WebSocketMultiplayerPeer.new()
	var err := _server.create_server(GameConfig.WEBSOCKET_PORT)
	if err != OK:
		push_error("NetworkManager: failed to start server on port %d (err %d)" % [GameConfig.WEBSOCKET_PORT, err])
		_server = null
		return false

	room_code = GameIdGenerator.get_random_id()
	print("NetworkManager: server started on port %d — room code: %s" % [GameConfig.WEBSOCKET_PORT, room_code])
	return true

## Stop the server and clear all connection state.
func stop_server() -> void:
	if _server != null:
		_server.close()
		_server = null
	_peer_ids.clear()
	room_code = ""

# ---------------------------------------------------------------------------
# Public API — send helpers
# ---------------------------------------------------------------------------

## Broadcast a message dict to every connected client.
func broadcast(message: Dictionary) -> void:
	if is_local or _server == null:
		return
	var json := JSON.stringify(message)
	for peer_id in _peer_ids:
		_server.get_peer(peer_id).put_packet(json.to_utf8_buffer())

## Send a message dict to a specific player by their device_id.
func send_to_player(device_id: String, message: Dictionary) -> void:
	if is_local or _server == null:
		return
	var peer_id := _device_id_to_peer(device_id)
	if peer_id == -1:
		return
	var json := JSON.stringify(message)
	_server.get_peer(peer_id).put_packet(json.to_utf8_buffer())

# ---------------------------------------------------------------------------
# Game-event broadcasts — called by GameManager / game_board
# ---------------------------------------------------------------------------

func broadcast_game_started() -> void:
	broadcast({"type": "game_started"})

func broadcast_new_round(round_num: int, slider_count: int) -> void:
	broadcast({"type": "new_round", "round_num": round_num, "slider_count": slider_count})

func broadcast_your_turn(device_id: String) -> void:
	send_to_player(device_id, {"type": "your_turn"})

func broadcast_slider_revealed(index: int, word: String, revealer_id: String) -> void:
	broadcast({"type": "slider_revealed", "index": index, "word": word, "revealer_id": revealer_id})

func broadcast_turn_changed(player_id: String) -> void:
	broadcast({"type": "turn_changed", "player_id": player_id})

func broadcast_scores(players: Array) -> void:
	var payload: Array = []
	for p in players:
		payload.append({"id": p.id, "name": p.name, "score": p.score})
	broadcast({"type": "scores", "players": payload})

func broadcast_vote_request(guesser_id: String, submitted_answer: String) -> void:
	broadcast({"type": "vote_request", "guesser_id": guesser_id, "answer": submitted_answer})

func broadcast_vote_result(accepted: bool, correct_answer: String) -> void:
	broadcast({"type": "vote_result", "accepted": accepted, "correct_answer": correct_answer})

func broadcast_round_end(correct_answer: String, winner_id: String) -> void:
	broadcast({"type": "round_end", "correct_answer": correct_answer, "winner_id": winner_id})

func broadcast_game_over(winner: Player) -> void:
	broadcast({"type": "game_over", "winner_id": winner.id, "winner_name": winner.name})

# ---------------------------------------------------------------------------
# Internal — event processing
# ---------------------------------------------------------------------------

func _process_events() -> void:
	while _server.get_available_packet_count() > 0:
		var peer_id := _server.get_packet_peer()
		var raw := _server.get_packet().get_string_from_utf8()

		# Track newly seen peers from packet traffic.
		if not _peer_ids.has(peer_id):
			_peer_ids[peer_id] = str(peer_id)
			client_connected.emit(str(peer_id))

		_handle_packet(peer_id, raw)

	# Check for disconnections in an API-compatible way.
	for peer_id in _peer_ids.keys():
		var peer_connected := true
		if _server.has_method("has_peer"):
			peer_connected = _server.has_peer(peer_id)
		elif _server.has_method("get_peer"):
			peer_connected = _server.get_peer(peer_id) != null

		if not peer_connected:
			var device_id: String = _peer_ids[peer_id]
			_peer_ids.erase(peer_id)
			client_disconnected.emit(device_id)

func _handle_packet(peer_id: int, raw: String) -> void:
	var parsed = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_warning("NetworkManager: malformed packet from peer %d: %s" % [peer_id, raw])
		return

	var msg: Dictionary = parsed
	var msg_type: String = msg.get("type", "")
	var device_id: String = _peer_ids.get(peer_id, str(peer_id))

	match msg_type:
		"join":
			var player_name: String = msg.get("name", "").strip_edges()
			var avatar_index: int = int(msg.get("avatar_index", 0))
			if player_name.is_empty():
				send_to_player(device_id, {"type": "error", "message": "Name cannot be empty"})
				return
			send_to_player(device_id, {
				"type": "room_joined",
				"player_id": device_id,
				"room_code": room_code
			})
			player_join_received.emit(device_id, player_name, avatar_index)

		"ready":
			var is_ready: bool = bool(msg.get("ready", true))
			player_ready_received.emit(device_id, is_ready)

		"slider_click":
			var index: int = int(msg.get("index", -1))
			if index < 0:
				return
			slider_click_received.emit(device_id, index)

		"guess":
			var answer: String = msg.get("answer", "").strip_edges()
			if answer.is_empty():
				return
			guess_received.emit(device_id, answer)

		"vote":
			var accepted: bool = bool(msg.get("accepted", false))
			vote_cast_received.emit(device_id, accepted)

		_:
			push_warning("NetworkManager: unknown message type '%s' from %s" % [msg_type, device_id])

# ---------------------------------------------------------------------------
# Internal — helpers
# ---------------------------------------------------------------------------

func _device_id_to_peer(device_id: String) -> int:
	for peer_id in _peer_ids:
		if _peer_ids[peer_id] == device_id:
			return peer_id
	push_warning("NetworkManager: no peer found for device_id '%s'" % device_id)
	return -1
