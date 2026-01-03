extends Node2D

signal game_init_complete

@onready var players_container = $PlayersContainer
@onready var players_grid = $PlayersContainer/PlayersGrid
@onready var game_settings_container = $GameSettingsContainer
@onready var player_slider = $PlayersContainer/PlayerSlider/Slider
@onready var player_count_label = $PlayersContainer/PlayerSlider/PlayerCount
@onready var add_player_button = $PlayersContainer/AddPlayerButton

@onready var player_picker = preload("res://scenes/components/player_picker.tscn")

var player_count: int = 2

func _ready() -> void:
	print("GameInit scene ready")
	print("Player slider initial value: %d" % int(player_slider.value))
	player_count_label.text = str(int(player_slider.value))
	player_slider.connect("value_changed", Callable(self, "_on_h_slider_value_changed"))

	print("Initializing players...")
	for i in range(player_count):
		var player_name = "Player %d" % (i + 1)
		PlayerManager.add_player(player_name)
		players_grid.add_child(player_picker.instantiate())


	game_init_complete.emit()

func _initialize_players() -> void:
	# print("Initializing players...")
	# for i in range(player_count):
	# 	var player_name = "Player %d" % (i + 1)
	# 	PlayerManager.add_player(player_name)
	print("Players initialized: ")
	for player in PlayerManager.players:
		print("- %s (ID: %s)" % [player.name, player.id])
	# PlayerManager.add_player("Alice")
	# PlayerManager.add_player("Bob")
	# PlayerManager.add_player("Charlie")
	# for player in PlayerManager.players:
	# 	print("- %s (ID: %s)" % [player.name, player.id])



func _on_h_slider_value_changed(value: float) -> void:
	print("Number of Players selected: %d" % int(value))
	player_count_label.text = str(int(player_slider.value))
