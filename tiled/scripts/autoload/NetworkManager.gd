# NetworkManager — scripts/autoload/NetworkManager.gd
# Role: Autoload singleton for host-side WebSocket transport.
# Owns: Server lifecycle, peer tracking, outbound messaging, disconnect detection.
# Does not own: Packet message semantics (NetworkProtocolHandler), game rules/state.
#
# Public API:
# - start_server(), stop_server()
# - broadcast(message), send_to_player(device_id, message)
# - broadcast_game_started(), broadcast_new_round(), broadcast_your_turn()
# - broadcast_slider_revealed(), broadcast_turn_changed(), broadcast_scores()
# - broadcast_overlay_prompt(), broadcast_vote_request(), broadcast_vote_result()
# - broadcast_round_end(), broadcast_game_over()
#
# Runtime model:
# - Host runs server on GameConfig.WEBSOCKET_PORT.
# - Clients send JSON packets; protocol handler returns effects.
# - NetworkManager applies effects by sending packets and emitting typed signals.
# - When is_local is true, all network operations are no-ops.
extends Node

# ---------------------------------------------------------------------------
# Signals — emitted when validated client messages arrive
# ---------------------------------------------------------------------------
signal client_connected(device_id: String)
signal client_disconnected(device_id: String)
signal player_join_received(device_id: String, player_name: String, avatar_index: int)
signal player_ready_received(device_id: String, is_ready: bool)
signal slider_click_received(device_id: String, index: int)
signal guess_started_received(device_id: String)
signal guess_received(device_id: String, answer: String)
signal vote_cast_received(device_id: String, accepted: bool)
signal overlay_continue_received(device_id: String)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var is_local: bool = true
var room_code: String = ""

var _server: WebSocketMultiplayerPeer = null
# Map: peer_id (int) → device_id (String)  — device_id is the string form of peer_id
var _peer_ids: Dictionary = {}
const NetworkProtocolHandlerResource = preload("res://scripts/logic/NetworkProtocolHandler.gd")
var _protocol_handler = NetworkProtocolHandlerResource.new()

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

	if not _server.peer_connected.is_connected(_on_peer_connected):
		_server.peer_connected.connect(_on_peer_connected)
	if not _server.peer_disconnected.is_connected(_on_peer_disconnected):
		_server.peer_disconnected.connect(_on_peer_disconnected)

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
	var stale_peer_ids: Array[int] = []
	for peer_id in _peer_ids.keys():
		if not _send_json_to_peer(peer_id, json):
			stale_peer_ids.append(peer_id)

	for stale_peer_id in stale_peer_ids:
		_mark_peer_disconnected(stale_peer_id)

## Send a message dict to a specific player by their device_id.
func send_to_player(device_id: String, message: Dictionary) -> void:
	if is_local or _server == null:
		return
	var peer_id := _device_id_to_peer(device_id)
	if peer_id == -1:
		return
	var json := JSON.stringify(message)
	if not _send_json_to_peer(peer_id, json):
		_mark_peer_disconnected(peer_id)

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

func broadcast_overlay_prompt(active: bool, message: String) -> void:
	broadcast({"type": "overlay_prompt", "active": active, "message": message})

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

## Processes all incoming WebSocket packets and connection events.
## - Handles new packets from clients, emitting signals for validated messages.
## - Tracks new connections and emits `client_connected`.
## - Handles client disconnections and emits `client_disconnected`.
## Called every frame by _process() when the server is running.
func _process_events() -> void:
	while _server.get_available_packet_count() > 0:
		var peer_id := _server.get_packet_peer()
		var raw := _server.get_packet().get_string_from_utf8()

		# Track newly seen peers from packet traffic.
		if not _peer_ids.has(peer_id):
			_peer_ids[peer_id] = str(peer_id)
			client_connected.emit(str(peer_id))

		_handle_packet(peer_id, raw)

## Handles a single incoming packet from a client.
## - Parses the JSON message and validates its structure.
## - Dispatches actions based on the message type (join, ready, slider_click, guess, vote, overlay_continue).
## - Emits relevant signals for the game layer to handle.
## - Sends error responses for malformed or invalid packets.
## Called internally by _process_events().
func _handle_packet(peer_id: int, raw: String) -> void:
	var device_id: String = _peer_ids.get(peer_id, str(peer_id))
	var effects: Dictionary = _protocol_handler.process_packet(peer_id, raw, device_id, room_code)
	_apply_packet_effects(effects)

func _apply_packet_effects(effects: Dictionary) -> void:
	for warning in effects.get("warnings", []):
		push_warning(warning)

	for outgoing in effects.get("outgoing", []):
		send_to_player(outgoing.get("device_id", ""), outgoing.get("message", {}))

	for event_data in effects.get("events", []):
		_emit_protocol_event(event_data.get("name", ""), event_data.get("args", []))

func _emit_protocol_event(event_name: String, args: Array) -> void:
	match event_name:
		"player_join_received":
			player_join_received.emit(args[0], args[1], args[2])
		"player_ready_received":
			player_ready_received.emit(args[0], args[1])
		"slider_click_received":
			slider_click_received.emit(args[0], args[1])
		"guess_started_received":
			guess_started_received.emit(args[0])
		"guess_received":
			guess_received.emit(args[0], args[1])
		"vote_cast_received":
			vote_cast_received.emit(args[0], args[1])
		"overlay_continue_received":
			overlay_continue_received.emit(args[0])
		_:
			push_warning("NetworkManager: unhandled protocol event '%s'" % event_name)

# ---------------------------------------------------------------------------
# Internal — helpers
# ---------------------------------------------------------------------------

func _device_id_to_peer(device_id: String) -> int:
	for peer_id in _peer_ids:
		if _peer_ids[peer_id] == device_id:
			return peer_id
	push_warning("NetworkManager: no peer found for device_id '%s'" % device_id)
	return -1

func _send_json_to_peer(peer_id: int, json: String) -> bool:
	if _server == null:
		return false
	if not _peer_ids.has(peer_id):
		return false

	var peer = _server.get_peer(peer_id)
	if peer == null:
		return false

	peer.put_packet(json.to_utf8_buffer())
	return true


func _on_peer_connected(peer_id: int) -> void:
	# Wait for the first packet to bind peer_id to a device_id.
	print("NetworkManager: peer connected %d" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_mark_peer_disconnected(peer_id)

func _mark_peer_disconnected(peer_id: int) -> void:
	if not _peer_ids.has(peer_id):
		return
	var device_id: String = _peer_ids[peer_id]
	_peer_ids.erase(peer_id)
	client_disconnected.emit(device_id)
