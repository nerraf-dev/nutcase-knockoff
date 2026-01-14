extends Node2D

signal new_game
signal exit_game

@onready var new_game_btn = $NewGame
@onready var exit_btn = $Exit
@onready var accept_dialog = $AcceptDialog



func _ready() -> void:
	print("GameHome scene ready")
	new_game_btn.pressed.connect(_on_new_game_btn_pressed)
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	accept_dialog.confirmed.connect(_on_AcceptDialog_confirmed)

func _on_new_game_btn_pressed() -> void:
	print("New Game button pressed, emitting new_game signal")
	new_game.emit()

func _on_exit_btn_pressed() -> void:
	$AcceptDialog.popup_centered()


func _on_AcceptDialog_confirmed() -> void:
	print("Exit button pressed, quitting application")
	exit_game.emit()
