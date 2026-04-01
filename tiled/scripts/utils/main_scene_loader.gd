## MainSceneLoader
## 
## Responsible for scene instantiation, initialization, and lifecycle management.
## Encapsulates all preload-instantiate-connect patterns for game screens.
## 
## Usage:
##   var loader = MainSceneLoader.new(scene_container)
##   loader.show_splash(on_splash_complete)
##   # or
##   loader.show_game_home(on_start_game, on_exit_game)
##
## Scenes Managed:
##  - Splash screen (intro animation)
##  - Game home (main menu)
##  - Game init (setup/config)
##  - Lobby (multiplayer waiting area)
##  - Game board (active gameplay)
##  - Game end (results screen)
##
## All methods handle signal connections with validity checks to prevent errors.

class_name MainSceneLoader
extends RefCounted

var _scene_container: Node

func _init(scene_container: Node) -> void:
	_scene_container = scene_container

## Show splash screen and connect completion signal.
## on_splash_complete: Callback when splash animation finishes
func show_splash(on_splash_complete: Callable) -> void:
	var splash_scene = preload("res://scenes/screens/splash_screen.tscn")
	var splash_instance = splash_scene.instantiate()
	_scene_container.add_child(splash_instance)
	if on_splash_complete.is_valid():
		splash_instance.splash_complete.connect(on_splash_complete)

## Show main menu home screen and connect user action signals.
## on_start_game: Callback when user initiates new game
## on_open_options: Callback when user opens options
## on_exit_game: Callback when user requests to quit
func show_game_home(on_start_game: Callable, on_open_options: Callable, on_exit_game: Callable) -> void:
	var home_scene = preload("res://scenes/screens/game_home.tscn")
	var home_instance = home_scene.instantiate()
	_scene_container.add_child(home_instance)
	if on_start_game.is_valid():
		home_instance.start_game.connect(on_start_game)
	if on_open_options.is_valid():
		home_instance.open_options.connect(on_open_options)
	if on_exit_game.is_valid():
		home_instance.exit_game.connect(on_exit_game)

## Show options screen.
## on_back_to_home: Callback when user closes options.
func show_options(on_back_to_home: Callable) -> void:
	var options_scene = preload("res://scenes/screens/options.tscn")
	var options_instance = options_scene.instantiate()
	_scene_container.add_child(options_instance)
	if on_back_to_home.is_valid():
		options_instance.back_to_home.connect(on_back_to_home)

## Show game setup/init screen (game type, target, player count, etc).
## on_game_init_complete: Callback when user finishes setup (receives settings Dict)
## on_back_to_home: Callback when user cancels setup
func show_game_init(on_game_init_complete: Callable, on_back_to_home: Callable) -> void:
	var init_scene = preload("res://scenes/screens/game_init.tscn")
	var init_instance = init_scene.instantiate()
	if on_game_init_complete.is_valid():
		init_instance.game_init_complete.connect(on_game_init_complete)
	if on_back_to_home.is_valid():
		init_instance.back_to_home.connect(on_back_to_home)
	_scene_container.add_child(init_instance)

## Show lobby screen (multiplayer waiting area with room code and player list).
## settings: Game configuration from init screen
## on_start_requested: Callback when host starts game (receives settings Dict)
## on_back_to_home: Callback when user chooses to exit lobby
## on_back_to_setup: Callback when user chooses to return to setup
func show_lobby(settings: Dictionary, on_start_requested: Callable, on_back_to_home: Callable, on_back_to_setup: Callable) -> void:
	var lobby_scene = preload("res://scenes/screens/lobby.tscn")
	var lobby_instance = lobby_scene.instantiate()
	lobby_instance.configure(settings)
	_scene_container.add_child(lobby_instance)
	if on_start_requested.is_valid():
		lobby_instance.lobby_start_requested.connect(on_start_requested)
	if on_back_to_home.is_valid():
		lobby_instance.lobby_back_to_home.connect(on_back_to_home)
	if on_back_to_setup.is_valid():
		lobby_instance.lobby_back_to_setup.connect(on_back_to_setup)

## Show active gameplay board.
## on_return_to_home: Callback when user exits/gives up during game
## on_game_ended: Callback when game finishes (receives winner Player object)
func show_game_board(on_return_to_home: Callable, on_game_ended: Callable) -> void:
	var board_scene = preload("res://scenes/screens/game_board.tscn")
	var board_instance = board_scene.instantiate()
	_scene_container.add_child(board_instance)
	if on_return_to_home.is_valid():
		board_instance.return_to_home.connect(on_return_to_home)
	if on_game_ended.is_valid():
		board_instance.game_ended.connect(on_game_ended)

## Show game end/results screen.
## winner: The Player object who won the game
## players: Array of all Player objects that participated
## game_data: Dict with game_type, game_target, player_count
## on_play_again_requested: Callback when user chooses to replay with same settings
## on_return_to_home: Callback when user chooses to return to home
func show_game_end(winner, players: Array, game_data: Dictionary, on_play_again_requested: Callable, on_return_to_home: Callable) -> void:
	var end_scene = preload("res://scenes/screens/GameEnd.tscn")
	var end_instance = end_scene.instantiate()
	_scene_container.add_child(end_instance)

	if end_instance is Control:
		var end_control := end_instance as Control
		end_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		end_control.set_size(_scene_container.get_viewport().get_visible_rect().size)

	end_instance.setup(winner, players, game_data)

	if on_play_again_requested.is_valid():
		end_instance.play_again_requested.connect(on_play_again_requested)
	if on_return_to_home.is_valid():
		end_instance.return_to_home.connect(on_return_to_home)

## Remove all child scenes from container (deferred cleanup).
func cleanup_current_scene() -> void:
	for child in _scene_container.get_children():
		child.queue_free()
