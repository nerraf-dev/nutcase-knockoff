extends Node2D

signal start_game
signal exit_game

@onready var start_game_btn = $StartGame
@onready var options_btn = $Options
@onready var exit_btn = $Exit
@onready var accept_dialog = $AcceptDialog



func _ready() -> void:
	print("GameHome scene ready")
	start_game_btn.pressed.connect(_on_start_game_btn_pressed)
	options_btn.pressed.connect(_on_options_btn_pressed)
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	accept_dialog.confirmed.connect(_on_AcceptDialog_confirmed)

	start_game_btn.grab_focus()
	start_game_btn.focus_mode = Control.FOCUS_ALL
	options_btn.focus_mode = Control.FOCUS_ALL
	exit_btn.focus_mode = Control.FOCUS_ALL


func _on_start_game_btn_pressed() -> void:
	print("Start Game button pressed, emitting start_game signal")
	start_game.emit()

func _on_options_btn_pressed() -> void:
	print("Options button pressed - no options implemented yet")

func _on_exit_btn_pressed() -> void:
	$AcceptDialog.popup_centered()
	await get_tree().process_frame  # Wait one frame
	$AcceptDialog.get_ok_button().grab_focus()  # Focus the OK button

func _on_AcceptDialog_confirmed() -> void:
	print("Exit button pressed, quitting application")
	exit_game.emit()
