extends Node2D

@onready var scene_container = $SceneContainer

# LOAD SPLASH SCREEN
func _ready() -> void:
	print("Main scene ready, loading SplashScreen")
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
	var home_scene = preload("res://scenes/screens/game_home.tscn")
	var home_instance = home_scene.instantiate()
	scene_container.add_child(home_instance)
	home_instance.new_game.connect(_on_new_game)

func _on_new_game() -> void:
	print("New game started, loading Game Init (setup)")
	cleanup_current_scene()
	load_game_init()

# LOAD GAME INIT
func load_game_init() -> void:
	var init_scene = preload("res://scenes/screens/game_init.tscn")
	var init_instance = init_scene.instantiate()
	init_instance.game_init_complete.connect(_on_game_init_complete)
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
	

	load_game_board(settings)

# LOAD GAME BOARD
func load_game_board(settings: Dictionary) -> void:
	var board_scene = preload("res://scenes/screens/game_board.tscn")
	var board_instance = board_scene.instantiate()
	scene_container.add_child(board_instance)
	# pass settings to game board if needed
	# board_instance.setup_game(settings)  # Uncomment if setup_game method is implemented

# Cleanup current scene
func cleanup_current_scene() -> void:
	for child in scene_container.get_children():
		child.queue_free()

