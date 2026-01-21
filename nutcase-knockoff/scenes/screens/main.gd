extends Control

@onready var scene_container = $SceneContainer

# LOAD SPLASH SCREEN
func _ready() -> void:
	print("Main scene ready, loading SplashScreen")
	# Initialize game state
	GameManager.current_state = GameManager.GameState.NONE
	var a = GameIdGenerator.get_random_id()
	print("Generated Game ID: %s" % a)
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

# LOAD GAME HOME
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
	print("Player settings: %s" % str(settings["player_count"]))
	print("Game type: %s" % settings["game_type"])
	print("Round count: %d" % settings["round_count"])
	# remove node, return to main to then load game board
	cleanup_current_scene()

	# setup new game in game manger
	GameManager.start_game(settings)
	

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
		"game_target": GameManager.game.game_target,
		"player_count": PlayerManager.players.size()
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
