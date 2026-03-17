extends Control

@onready var scene_container = $SceneContainer

func _ready() -> void:
	print("Main scene ready, loading SplashScreen")
	# Initialize game state
	GameManager.current_state = GameManager.GameState.NONE
	# var a = GameIdGenerator.get_random_id()
	# print("Generated Game ID: %s" % a)
	load_splash_screen()

func load_splash_screen() -> void:
	var splash_scene = preload("res://scenes/screens/splash_screen.tscn")
	var splash_instance = splash_scene.instantiate()    
	scene_container.add_child(splash_instance)
	splash_instance.splash_complete.connect(_on_splash_complete)

func _on_splash_complete() -> void:
	print("Splash screen complete, loading GameHome")
	cleanup_current_scene()
	load_game_home()

func load_game_home() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	var home_scene = preload("res://scenes/screens/game_home.tscn")
	var home_instance = home_scene.instantiate()
	scene_container.add_child(home_instance)
	home_instance.start_game.connect(_on_start_game)
	home_instance.exit_game.connect(_on_exit_game)

func _on_start_game() -> void:
	print("New game started, loading Game Init (setup)")
	cleanup_current_scene()
	load_game_init()

func _on_exit_game() -> void:
	print("Exit game signal received, quitting application")
	get_tree().quit()

func _on_return_to_home() -> void:
	print("Returning to home screen")
	if GameManager.current_state == GameManager.GameState.LOBBY:
		PlayerManager.clear_all_players()
		NetworkManager.stop_server()
	cleanup_current_scene()
	load_game_home()

# LOAD GAME INIT
func load_game_init() -> void:
	GameManager.change_state(GameManager.GameState.SETUP)
	var init_scene = preload("res://scenes/screens/game_init.tscn")
	var init_instance = init_scene.instantiate()
	init_instance.game_init_complete.connect(_on_game_init_complete)
	init_instance.back_to_home.connect(_on_return_to_home) 
	scene_container.add_child(init_instance)

func _on_game_init_complete(settings: Dictionary) -> void:
	print("Game Init complete with settings: %s, loading Game Board" % settings)
	# remove node, return to main to then load game board
	cleanup_current_scene()

	if settings["game_mode"] == "multi":
		# Load lobby here, pass settings. Emit signal when ready
		print("Multiplayer mode selected, loading lobby")
		NetworkManager.is_local = false
		load_lobby(settings)

	else:
		# single player selected, start game directly
		print("Single-player mode selected, starting game directly")
		# setup new game in game manger
		GameManager.start_game(settings)
		load_game_board()

#  LOAD LOBBY
func load_lobby(settings: Dictionary) -> void:
	# LOBBY: show room code, instructions, player list, start button (disabled until 2+ players), back to home button
	#   Waiting for players to connect - as players connect need to update PlayerManager.players + update ui
	#  start is only active if at least 2 players connected

	# Always start each lobby session with a clean roster.
	if not PlayerManager.players.is_empty():
		PlayerManager.clear_all_players()

	GameManager.change_state(GameManager.GameState.LOBBY)
	var lobby_scene = preload("res://scenes/screens/lobby.tscn")
	var lobby_instance = lobby_scene.instantiate()
	lobby_instance.configure(settings)
	scene_container.add_child(lobby_instance)
	lobby_instance.lobby_start_requested.connect(_on_lobby_start_requested)
	lobby_instance.lobby_back_to_home.connect(_on_return_to_home)
	lobby_instance.lobby_back_to_setup.connect(_on_return_to_setup_from_lobby)    # Return to setup with lobby cleanup

func _on_return_to_setup_from_lobby() -> void:
	if GameManager.current_state == GameManager.GameState.LOBBY:
		PlayerManager.clear_all_players()
		NetworkManager.stop_server()
	cleanup_current_scene()
	load_game_init()

func _on_lobby_start_requested(settings: Dictionary) -> void:
	print("Lobby start requested with settings: %s, loading Game Board" % settings)
	if not GameManager.start_game(settings):
		print("Failed to start game.")
		return
	cleanup_current_scene()
	load_game_board()

# LOAD GAME BOARD
func load_game_board() -> void:
	var board_scene = preload("res://scenes/screens/game_board.tscn")
	var board_instance = board_scene.instantiate()
	scene_container.add_child(board_instance)
	board_instance.return_to_home.connect(_on_return_to_home)
	board_instance.game_ended.connect(_on_game_ended)

# LOAD GAME END
func load_game_end(winner: Player) -> void:
	print("Loading game end screen, winner: %s" % winner.name)
	var end_scene = preload("res://scenes/screens/GameEnd.tscn")
	var end_instance = end_scene.instantiate()
	scene_container.add_child(end_instance)
	
	# Force the Control to fill the viewport (needed when parent is Node2D)
	end_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_instance.set_size(get_viewport().get_visible_rect().size)
	
	# Pass game data to end screen
	end_instance.setup(winner, PlayerManager.players, {
		"game_type": GameManager.game.game_type,
		"game_target": GameManager.game.game_target,
		"player_count": PlayerManager.players.size()
	})
	
	# Connect signals
	end_instance.play_again_requested.connect(_on_play_again_requested)
	end_instance.return_to_home.connect(_on_return_to_home)

func _on_game_ended(winner: Player) -> void:
	print("Game ended, winner: %s" % winner.name)
	cleanup_current_scene()
	load_game_end(winner)

func _on_play_again_requested() -> void:
	print("Play again with same settings")
	cleanup_current_scene()
	
	# Store settings before reset
	var settings = {
		"game_type": GameManager.game.game_type,
		"game_mode": GameManager.game.game_mode,
		"game_target": GameManager.game.game_target,
		"player_count": PlayerManager.players.size(),
		"fuzzy_enabled": GameManager.game.fuzzy_enabled
	}
	
	# Reset game data
	GameManager.game = null
	PlayerManager.clear_all_players()
	
	# Transition: GAME_OVER → MENU → SETUP → IN_PROGRESS
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager.change_state(GameManager.GameState.SETUP)
	
	# Start new game with same settings (this will transition to IN_PROGRESS)
	GameManager.start_game(settings)
	load_game_board()

# Cleanup current scene
func cleanup_current_scene() -> void:
	for child in scene_container.get_children():
		child.queue_free()
