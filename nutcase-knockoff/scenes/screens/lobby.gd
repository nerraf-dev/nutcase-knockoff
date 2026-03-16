extends Node2D

@onready var room_code_label = $RoomInfoContainer/Code
@onready var players_list= $PlayersContainer/Players
@onready var game_code_label = $RoomInfoContainer/Code
@onready var instructions_label = $JoinContainer/instructions
@onready var start_button = $StartBtn
@onready var home_button = $HomeBtn

signal lobby_start_requested(settings: Dictionary)
signal lobby_back_to_home
signal lobby_back_to_setup


