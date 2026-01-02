extends Node2D

signal new_game

@onready var new_game_btn = $NewGame


func _ready() -> void:
    print("GameHome scene ready")
    new_game_btn.pressed.connect(_on_new_game_btn_pressed)

func _on_new_game_btn_pressed() -> void:
    print("New Game button pressed, emitting new_game signal")
    new_game.emit()

