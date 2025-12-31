# PlayerManager.gd Documentation

## Overview
PlayerManager is responsible for managing all player-related logic in the game. It keeps track of players, their states, turn order, and scoring, and emits signals for other parts of the game to react to player events.

---

## Signals
- **turn_changed(player: Player):** Emitted when the active player changes.
- **player_added(player: Player):** Emitted when a new player joins the game.
- **player_removed(player: Player):** Emitted when a player leaves the game.
- **player_scored(player: Player, points: int):** Emitted when a player is awarded points.

---

## Properties
- **players:** Array of Player objects currently in the game.
- **current_turn_index:** Index of the player whose turn it is.

---

## Key Methods
- **add_player(player_name, device_id):** Adds a new player to the game and emits `player_added`.
- **remove_player(player_id):** Removes a player by ID and emits `player_removed`.
- **get_current_player():** Returns the Player whose turn it is.
- **get_active_players():** Returns a list of players who are not frozen.
- **next_turn():** Advances to the next non-frozen player's turn and emits `turn_changed`.
- **award_points(player, points):** Adds points to a player and emits `player_scored`.
- **freeze_player(player):** Freezes a player (e.g., after a wrong guess) and advances the turn if needed.
- **unfreeze_all_players():** Unfreezes all players (e.g., at the start of a new round).
- **get_player_by_id(player_id):** Returns a player by their unique ID.
- **get_scoreboard():** Returns a list of players sorted by score (descending).
- **reset_game():** Resets all player scores and states for a new game.
- **clear_all_players():** Removes all players from the game.

---

## Usage Example
- Add players at the start of the game.
- Use `next_turn()` to cycle through players.
- Freeze a player if they guess incorrectly.
- Award points to the current player when they win a round.
- Listen to signals to update UI or trigger game events.

---

## Notes
- PlayerManager is designed to be autoloaded (singleton) so it can be accessed from anywhere in the game.
- Signals allow for decoupled communication between game logic and UI.
- Turn and state management is handled internally, making it easy to expand or modify player logic.
