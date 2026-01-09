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

var qna_instance = null

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
		qna_instance = round_scene.instantiate()
		round_area.add_child(qna_instance)
		qna_instance.connect("round_result", Callable(self, "_on_round_result"))
	else:
		push_error("Failed to load round scene at path: %s" % round_scene_path)

func _on_round_result(player: Player, is_correct: bool, prize: int) -> void:
	if is_correct:
		print("Player %s answered correctly!" % player.name)
		PlayerManager.award_points(player, prize)
	else:
		print("Player %s answered incorrectly!" % player.name)
		var penalty = int(player.score * 0.5)  # Half their current score
		PlayerManager.award_points(player, -penalty)  # Negative points
	
	_update_all_badges()
	
	# TODO: Fix the logic for no winners yet. The round should continue
	
	var winners = GameManager.check_for_winner()
	if winners.is_empty():
		print("No winner yet, continuing to next round.")
		# TODO: Show round summary overlay
		await get_tree().create_timer(1.0).timeout  # Placeholder delay
		_start_next_round()
	else:
		print("We have a winner: %s!" % winners[0].name)
		GameManager.game_ended.emit(winners[0])
		round_area.set_process_input(false)

func _update_all_badges() -> void:
	var badges = players_container.get_children()
	var current_player = PlayerManager.get_current_player()
	for i in range(badges.size()):
		if i < PlayerManager.players.size():
			var player = PlayerManager.players[i]
			badges[i].update_score(player.score)
			badges[i].set_current_player(player == current_player)

func _start_next_round() -> void:
	var next_question = GameManager.get_next_question()
	if next_question:
		PlayerManager.unfreeze_all_players()
		GameManager.game.current_round += 1
		qna_instance.start_new_question(next_question)
	else:
		print("No more questions available!")

# Signal handlers for buttons
func _on_options_btn_pressed() -> void:
	print("Options button pressed")

func _on_exit_btn_pressed() -> void:
	print("Exit button pressed")
