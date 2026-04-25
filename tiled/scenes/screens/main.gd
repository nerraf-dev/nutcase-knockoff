## Main scene controller orchestrating game flow and screen transitions.
##
## Responsibilities:
## - Manage transitions between splash, home, setup, lobby, board, and end screens.
## - Delegate scene instantiation to MainSceneLoader helper.
## - Delegate session/network cleanup to MainSessionCoordinator helper.
## - Make game flow decisions based on settings (single vs multiplayer).
##
## Flow Overview:
## splash → home → init → [lobby (multi) | board (single)] → end → [replay | home]
##
## All direct mutations (GameManager, PlayerManager, NetworkManager) are delegated
## to helpers where possible, keeping this file focused on orchestration only.

extends Control

const MainSessionCoordinatorScript = preload("res://scripts/utils/main_session_coordinator.gd")

# Game mode constants
const GAME_MODE_SINGLE = "single"
const GAME_MODE_MULTI = "multi"

@onready var scene_container = $SceneContainer
var scene_loader: MainSceneLoader
var session_coordinator

func _ready() -> void:
	print("Main scene ready, loading SplashScreen")
	scene_loader = MainSceneLoader.new(scene_container)
	session_coordinator = MainSessionCoordinatorScript.new()
	# Initialize game state
	GameManager.current_state = GameManager.GameState.NONE
	# var a = GameIdGenerator.get_random_id()
	# print("Generated Game ID: %s" % a)
	load_splash_screen()

func load_splash_screen() -> void:
	scene_loader.show_splash(_on_splash_complete)

func _on_splash_complete() -> void:
	print("Splash screen complete, loading GameHome")
	cleanup_current_scene()
	load_game_home()

## Load the home/menu screen.
func load_game_home() -> void:
	if GameManager.current_state != GameManager.GameState.MENU:
		GameManager.change_state(GameManager.GameState.MENU)
	MusicManager.play_menu_music()
	scene_loader.show_game_home(_on_start_game, _on_open_options, _on_exit_game)

func _on_start_game() -> void:
	print("New game started, loading Game Init (setup)")
	cleanup_current_scene()
	load_game_init()

func _on_exit_game() -> void:
	print("Exit game signal received, quitting application")
	get_tree().quit()


func _on_open_options() -> void:
	print("Opening options screen")
	cleanup_current_scene()
	load_options()


func load_options() -> void:
	MusicManager.play_menu_music()
	scene_loader.show_options(_on_return_to_home)

func _on_return_to_home() -> void:
	print("Returning to home screen")
	session_coordinator.reset_for_home()
	cleanup_current_scene()
	load_game_home()

# LOAD GAME INIT
## Load the game setup/init screen (config: type, target, mode, etc).
func load_game_init() -> void:
	GameManager.change_state(GameManager.GameState.SETUP)
	MusicManager.play_menu_music()
	scene_loader.show_game_init(_on_game_init_complete, _on_return_to_home)

func _on_game_init_complete(settings: Dictionary) -> void:
	print("Game Init complete with settings: %s, loading Game Board" % settings)
	
	# Validate settings before proceeding
	if not settings or not settings.has("game_mode"):
		push_error("Invalid settings dictionary passed from game init: %s" % settings)
		return
	
	cleanup_current_scene()

	if settings["game_mode"] == GAME_MODE_MULTI:
		# Load lobby here, pass settings. Emit signal when ready
		print("Multiplayer mode selected, loading lobby")
		NetworkManager.is_local = false
		load_lobby(settings)

	#  TODO: dump single player code if possible. Need to identify the rest.
	elif settings["game_mode"] == GAME_MODE_SINGLE:
		# Single player selected, start game directly
		print("Single-player mode selected, starting game directly")
		NetworkManager.is_local = true
		# setup new game in game manager
		if not GameManager.start_game(settings):
			push_error("Failed to start single-player game with settings: %s" % settings)
			return
		load_game_board()
	else:
		push_error("Unknown game mode: %s" % settings["game_mode"])
		return

## Load the multiplayer lobby screen (room code, player list, waiting area).
func load_lobby(settings: Dictionary) -> void:
	# LOBBY: show room code, instructions, player list, start button (disabled until 2+ players), back to home button
	#   Waiting for players to connect - as players connect need to update PlayerManager.players + update ui
	#  start is only active if at least 2 players connected
	session_coordinator.prepare_lobby_session()
	GameManager.change_state(GameManager.GameState.LOBBY)
	MusicManager.play_menu_music()
	scene_loader.show_lobby(settings, _on_lobby_start_requested, _on_return_to_home, _on_return_to_setup_from_lobby)

func _on_return_to_setup_from_lobby() -> void:
	session_coordinator.reset_for_setup_from_lobby()
	cleanup_current_scene()
	load_game_init()

func _on_lobby_start_requested(settings: Dictionary) -> void:
	print("Lobby start requested with settings: %s, loading Game Board" % settings)
	if not GameManager.start_game(settings):
		print("Failed to start game.")
		return
	if not NetworkManager.is_local:
		NetworkManager.broadcast_game_started()
	cleanup_current_scene()
	load_game_board()

## Load the active game board screen (gameplay).
func load_game_board() -> void:
	MusicManager.play_game_music()
	scene_loader.show_game_board(_on_return_to_home, _on_return_to_lobby_from_game, _on_game_ended)


func _on_return_to_lobby_from_game(settings: Dictionary) -> void:
	print("Returning to lobby from active game with settings: %s" % settings)
	cleanup_current_scene()
	NetworkManager.is_local = false
	_ensure_state_ready_for_lobby()
	load_lobby(settings)


func _ensure_state_ready_for_lobby() -> void:
	match GameManager.current_state:
		GameManager.GameState.IN_PROGRESS:
			GameManager.change_state(GameManager.GameState.MENU)
		GameManager.GameState.GAME_OVER:
			GameManager.change_state(GameManager.GameState.MENU)
		GameManager.GameState.NONE:
			GameManager.change_state(GameManager.GameState.MENU)

	if GameManager.current_state == GameManager.GameState.MENU:
		GameManager.change_state(GameManager.GameState.SETUP)

# LOAD GAME END
func load_game_end(winner: Player) -> void:
	# Guard: Ensure winner is valid
	if not winner:
		push_error("Cannot load game end screen: winner is null")
		return
	
	# Guard: Ensure GameManager.game is still valid
	if not GameManager.game:
		push_error("Cannot load game end screen: GameManager.game is null")
		return
	
	print("Loading game end screen, winner: %s" % winner.name)
	MusicManager.play_menu_music()    # TODO: Need to change to 'game end' music at some point

	var game_data = {
		"game_type": GameManager.game.game_type,
		"game_target": GameManager.game.game_target,
		"player_count": PlayerManager.players.size()
	}
	scene_loader.show_game_end(winner, PlayerManager.players, game_data, _on_play_again_requested, _on_return_to_home)

func _on_game_ended(winner: Player) -> void:
	print("Game ended, winner: %s" % winner.name)
	cleanup_current_scene()
	load_game_end(winner)

func _on_play_again_requested() -> void:
	print("Play again with same settings")
	cleanup_current_scene()

	# Guard: Ensure GameManager.game is still valid before extracting settings
	if not GameManager.game:
		push_error("Cannot replay: GameManager.game is null")
		return
	
	# Store settings before reset
	var settings = {
		"game_type": GameManager.game.game_type,
		"game_mode": GameManager.game.game_mode,
		"game_target": GameManager.game.game_target,
		"player_count": PlayerManager.players.size(),
		"fuzzy_enabled": GameManager.game.fuzzy_enabled
	}

	session_coordinator.reset_for_replay()

	PlayerManager.reset_game()

	# Start new game with same settings (this will transition to IN_PROGRESS)
	if not GameManager.start_game(settings):
		push_error("Failed to start replay with settings: %s" % settings)
		return
	
	load_game_board()

# Cleanup current scene
## Deferred removal of all child scenes from container.
func cleanup_current_scene() -> void:
	scene_loader.cleanup_current_scene()
