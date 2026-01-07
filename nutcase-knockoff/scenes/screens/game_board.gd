extends Control

# GameBoard - game_board.gd
# This script manages the main game board scene, including HUD and round area.
# The RoundArea will host the 'game play'. That scene handles the game play logic.
# Teh GameBoard HUD shows the player list & details, main controls, etc.

const player_badge = preload("res://scenes/components/player_badge.tscn")

@onready var controls = $HUD/Controls
@onready var options_btn = $HUD/Controls/OptionsBtn
@onready var exit_btn = $HUD/Controls/ExitBtn
@onready var players_container = $HUD/PlayersContainer


@onready var round_area = $RoundArea

const ROUND_SCENES = {
	"qna": "res://scenes/components/rounds/qna.tscn"
	# Add other round types here as needed
}



func _ready() -> void:
	
	print("Game Board scene ready")
	_setup_players_hud()
	_setup_round_area()


func  _setup_players_hud() -> void:
	if players_container.get_child_count() > 0:
		for child in players_container.get_children():
			child.queue_free()
	for player in PlayerManager.players:
		var badge_instance = player_badge.instantiate()
		players_container.add_child(badge_instance)
		badge_instance.setup(player)

func _setup_round_area() -> void:
	var game_type = GameManager.game.game_type.to_lower()
	var round_scene_path = ROUND_SCENES.get(game_type, "")
	if round_scene_path == "":
		push_error("No round scene found for game type: %s" % game_type)
		return
	var round_scene = load(round_scene_path)
	if round_scene:
		var round_instance = round_scene.instantiate()
		round_area.add_child(round_instance)
		round_instance.connect("answer_correct", Callable(self, "_on_answer_correct"))
	else:
		push_error("Failed to load round scene at path: %s" % round_scene_path)

func _on_answer_correct(player: Player, points: int) -> void:
	print("main: Player %s answered correctly and scored %d points!" % [player.name, points])
	# Award points via PlayerManager
	PlayerManager.award_points(player, points)
	# update player badges

	# Check for a winner
	var winners = GameManager.game.check_winners()
	if winners.size() > 0:
		print("We have a winner!")
		# For simplicity, take the first winner
		var winner = winners[0]
		GameManager.game_ended.emit(winner)
		round_area.set_process_input(false)  # Disable further input
	else:
		# Answer is correct but score not meeting target:
		print("No winner yet, continuing game.")
		# board needs a reset

	# Start end of round!
	# - Update the player list to reflect new scores. 
	# 

# Signal handlers for buttons
func _on_options_btn_pressed() -> void:
	print("Options button pressed")

func _on_exit_btn_pressed() -> void:
	print("Exit button pressed")
