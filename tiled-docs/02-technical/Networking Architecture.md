# Networking Architecture

## Overview

The host game is authoritative. Controller clients (mobile browsers) are input devices that send actions over WebSocket and receive state updates from the host.

### Host-side components

- `ControllerServer.gd`: serves static controller assets (`controller/index.html`, `app.js`, `styles.css`) over HTTP.
- `NetworkManager.gd`: runs the WebSocket server, broadcasts host state, and emits validated gameplay signals from client packets.
- `NetworkProtocolHandler.gd`: parses and validates inbound JSON packet semantics.
- `game_board.gd`: consumes network signals and applies game actions if the sender is eligible.

### Client-side component

- `controller/app.js`: single-page state machine for connect/join/lobby/gameplay/vote/result flows.

## Message Model (Current)

### Client -> Host

- `join`
- `ready`
- `slider_click`
- `guess_start`
- `guess`
- `vote`
- `overlay_continue`

### Host -> Client

- `room_joined`
- `game_started`
- `new_round`
- `turn_changed`
- `your_turn`
- `slider_revealed`
- `overlay_prompt`
- `vote_request`
- `vote_result`
- `scores`
- `game_over`

## Controller Reconnect Behavior (Playtest Baseline)

### During active game

1. If a device disconnects, the player remains in `PlayerManager` and a reconnect grace timer starts in `game_board.gd`.
2. Grace window is currently `DISCONNECT_GRACE_SECONDS = 20.0`.
3. If the player rejoins within the grace window (matched by name), the host remaps the player's `device_id` and sends a targeted game-state sync.
4. If grace expires, host evaluates connected player count and applies disconnection rule policy.

## Disconnection Rule Policy (Current)

After grace timeout:

1. If connected players >= 2: game continues with remaining connected players.
2. If connected players == 1: remaining connected player wins by default; host returns to lobby.
3. If connected players == 0: no winner; host returns to lobby.

### LPS edge for disconnects

If exactly 2 connected players remain and only 1 of them is active (the other is frozen), host forces an LPS-style continuation:

1. Active connected player is set as current turn.
2. Overlay announces free-guess situation.
3. In local mode, host answer modal opens.
4. In network mode, controller remains the input surface.

### Targeted rejoin sync payload

The host sends to the rejoined device:

- `game_started`
- `new_round`
- `turn_changed` (+ `your_turn` if applicable)
- `scores`

This ensures the controller re-enters gameplay state instead of remaining stuck in lobby/profile UX.

## Validation Rules

Host validates sender identity before applying gameplay inputs:

- `slider_click`, `guess_start`, and `guess` are accepted only from current-turn player.
- `vote` accepted only from eligible voter set for active vote session.
- `overlay_continue` accepted only when overlay is active and sender is current-turn player.

## Open Next Decisions

- Add formal disconnection rule after grace timeout:
	- continue with remaining players, or
	- pause and return to lobby below minimum active threshold.
- Add explicit frozen/disconnected controller state push for clearer device UX.
