class_name NetworkProtocolHandler
extends RefCounted

# NetworkProtocolHandler — scripts/logic/network_protocol_handler.gd
# Role: Stateless protocol parser/dispatcher for client->server packet semantics.
# Owns: Packet JSON validation and translation into effect dictionaries.
# Does not own: Socket I/O, peer lifecycle, or signal emission (NetworkManager).
#
# Public API:
# - process_packet(peer_id, raw, device_id, room_code)
#
# Output contract:
# - Returns effects with keys: warnings, outgoing, events.
# - warnings: log strings for NetworkManager to push_warning.
# - outgoing: [{device_id, message}] packets for NetworkManager to send.
# - events: [{name, args}] domain events for NetworkManager to emit as typed signals.

func process_packet(peer_id: int, raw: String, device_id: String, room_code: String) -> Dictionary:
	var effects := {
		"warnings": [],
		"outgoing": [],
		"events": []
	}

	var parsed = JSON.parse_string(raw)
	if not parsed is Dictionary:
		effects["warnings"].append("NetworkManager: malformed packet from peer %d: %s" % [peer_id, raw])
		return effects

	var msg: Dictionary = parsed
	var msg_type: String = msg.get("type", "")

	match msg_type:
		"join":
			var player_name: String = msg.get("name", "").strip_edges()
			var avatar_index: int = int(msg.get("avatar_index", 0))
			if player_name.is_empty():
				effects["outgoing"].append({
					"device_id": device_id,
					"message": {"type": "error", "message": "Name cannot be empty"}
				})
				return effects
			effects["outgoing"].append({
				"device_id": device_id,
				"message": {
					"type": "room_joined",
					"player_id": device_id,
					"room_code": room_code
				}
			})
			effects["events"].append({
				"name": "player_join_received",
				"args": [device_id, player_name, avatar_index]
			})

		"ready":
			var is_ready: bool = bool(msg.get("ready", true))
			effects["events"].append({
				"name": "player_ready_received",
				"args": [device_id, is_ready]
			})

		"slider_click":
			var index: int = int(msg.get("index", -1))
			if index < 0:
				return effects
			effects["events"].append({
				"name": "slider_click_received",
				"args": [device_id, index]
			})

		"guess_start":
			effects["events"].append({
				"name": "guess_started_received",
				"args": [device_id]
			})

		"guess":
			var answer: String = msg.get("answer", "").strip_edges()
			if answer.is_empty():
				return effects
			effects["events"].append({
				"name": "guess_received",
				"args": [device_id, answer]
			})

		"vote":
			var accepted: bool = bool(msg.get("accepted", false))
			effects["events"].append({
				"name": "vote_cast_received",
				"args": [device_id, accepted]
			})

		"overlay_continue":
			effects["events"].append({
				"name": "overlay_continue_received",
				"args": [device_id]
			})

		_:
			effects["warnings"].append("NetworkManager: unknown message type '%s' from %s" % [msg_type, device_id])

	return effects
