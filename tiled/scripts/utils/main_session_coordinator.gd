## MainSessionCoordinator
##
## Manages session state transitions and cleanup workflows.
## Encapsulates player, game, and network state resets to prevent inconsistencies.
##
## Usage:
##   var coordinator = MainSessionCoordinator.new()
##   coordinator.reset_for_home()      # Full session cleanup before returning to menu
##   coordinator.prepare_lobby_session() # Reset player roster before lobby
##   coordinator.reset_for_replay()     # Prepare for replay with same settings
##
## Design:
## Each method represents a named cleanup profile used in specific transitions.
## This prevents scattered state resets across the codebase and makes transitions clear.

class_name MainSessionCoordinator
extends RefCounted

## Resets all players, stops network server, and sets mode to local.
## Called when returning to home from any game state.
func reset_for_home() -> void:
	PlayerManager.clear_all_players()
	if not NetworkManager.is_local:
		NetworkManager.stop_server()
	NetworkManager.is_local = true

## Clears player roster before entering lobby.
## Ensures a clean slate for new multiplayer session.
func prepare_lobby_session() -> void:
	if not PlayerManager.players.is_empty():
		PlayerManager.clear_all_players()

## Resets players and network when leaving lobby back to setup.
## Only acts if currently in LOBBY state (safety check).
func reset_for_setup_from_lobby() -> void:
	if GameManager.current_state == GameManager.GameState.LOBBY:
		PlayerManager.clear_all_players()
		NetworkManager.stop_server()

## Resets game state for instant replay.
## Clears GameManager.game but preserves players (they're still connected).
## Transitions state back to SETUP for new game start.
## New GameManager.start_game() call will transition to IN_PROGRESS.
func reset_for_replay() -> void:
	GameManager.game = null
	# Preserve players for replay — they're still connected via WebSocket
	# and don't need to rejoin; they just need a fresh game state
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager.change_state(GameManager.GameState.SETUP)
