extends Control

# GameBoard - game_board.gd
# This script manages the main game board scene, including HUD and round area.
# The RoundArea will host the 'game play'. That scene handles the game play logic.
# Teh GameBoard HUD shows the player list & details, main controls, etc.


@onready var controls = $HUD/Controls
@onready var options_btn = $HUD/Controls/OptionsBtn
@onready var exit_btn = $HUD/Controls/ExitBtn
@onready var players_container = $HUD/PlayersContainer


@onready var round_area = $RoundArea


func _ready() -> void:
	print("Game Board scene ready")
