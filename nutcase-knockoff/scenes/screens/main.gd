extends Node2D

# load splash screen scene - nutcase-knockoff/scenes/screens/SplashScreen.tscn

# timeout to gameHome scene - nutcase-knockoff/scenes/screens/GameHome.tscn
# on game home play - load gameInit scene - nutcase-knockoff/scenes/screens/game_init.tscn
# get player names - enter 1 x 1 or send to remotes when implemented (will use hardcoded for now)
# load main game board scene with player and game values initialized. setup game data
# main game board scene - nutcase-knockoff/scenes/screens/GameBoard.tscn

# board scene will load question data and player data from autoloads
# board scene will manage game rounds and player turns
# board scene will update player scores and game state and rounds

# when game ends display game end scene (to be made)
# game end scene will display player scores and winner
# game end scene will have option to restart game or exit to home

# game should track individual player coorrect and incorrect answers, numer of guesses etc. 
# this data can be used for stats at end of game or for future game modes

@onready var scene_container = $SceneContainer

# LOAD SPLASH SCREEN
func _ready() -> void:
	print("Main scene ready, loading SplashScreen")
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
	scene_container.add_child(init_instance)


# Cleanup current scene
func cleanup_current_scene() -> void:
	for child in scene_container.get_children():
		child.queue_free()

