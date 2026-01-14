extends Control

signal round_result(player: Player, is_correct: bool, points: int)

const SliderScene = preload("res://scenes/components/Slider.tscn")
const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")

@onready var grid = $GridContainer
@onready var guess_btn = $GuessBtn
@onready var current_player_label = $CurrentPlayer
@onready var prize_label = $Prize

const BASE_POT = 100.0
const MINIMUM_POT_PERCENT = 0.1  # Always reserve 10% as minimum pot
const DIFFICULTY_MULTIPLIERS = {
	"easy": 1.0,
	"medium": 1.5,
	"hard": 2.0
}

var current_prize = 100.0
var minimum_prize = 10.0
var prize_per_word = 0.0
var all_questions: Array[Question] = []
var current_question: Question = null

func _ready() -> void:
	print("QnA scene ready")
	guess_btn.pressed.connect(_on_guess_btn_pressed)
	
	# Connect to turn changes so label updates when turn advances
	PlayerManager.turn_changed.connect(_on_turn_changed)
	
	var current_player = PlayerManager.get_current_player()
	if current_player:
		current_player_label.text = current_player.name
	else:
		push_error("No current player available!")
		return
	
	# Get first question from GameManager
	var first_question = GameManager.get_next_question()
	if first_question:
		start_new_question(first_question)
	else:
		push_error("No questions available!")

# Update the score on the screen
func update_pot_display() -> void:
	prize_label.text = str(int(current_prize))

func _on_turn_changed(player: Player) -> void:
	current_player_label.text = player.name

func show_answer_modal_for_free_guess() -> void:
	# Automatically show answer modal for free guess
	var answer_modal = preload("res://scenes/components/answer_modal.tscn").instantiate()
	add_child(answer_modal)
	answer_modal.answer_submitted.connect(_on_answer_submitted)
 
func start_new_question(question: Question) -> void:
	# Clear old sliders
	for child in grid.get_children():
		child.queue_free()
	
	# Set new question
	current_question = question
	print("Starting new question: %s" % question.question_text)
	print("Answer is: %s" % question.answer)
	
	# Recalculate pot and spawn sliders
	var words = question.question_text.split(" ")
	var difficulty_mult = DIFFICULTY_MULTIPLIERS.get(question.difficulty, 1.0)
	current_prize = BASE_POT * difficulty_mult
	minimum_prize = current_prize * MINIMUM_POT_PERCENT
	var reducible_prize = current_prize - minimum_prize
	prize_per_word = reducible_prize / words.size()
	update_pot_display()
	
	var current_player = PlayerManager.get_current_player()
	if current_player:
		current_player_label.text = current_player.name
	
	print("Difficulty: %s | Starting pot: %d | Minimum guaranteed: %d" % [question.difficulty, int(current_prize), int(minimum_prize)])
	
	for i in range(words.size()):
		var s = SliderScene.instantiate()
		s.custom_minimum_size = Vector2(250, 80)
		grid.columns = 3
		grid.add_child(s)
		s.set_word(words[i], i + 1)
		s.clicked.connect(_on_slider_clicked)

# Handles the event when the slider is clicked.
# Decreases the current pot by the value of pot_per_word.
# Ensures the current pot does not go below zero.
# Updates the pot display and prints the new pot value to the output.
func _on_slider_clicked():
	# TODO: Uncomment and reapply reducing prize if needed
	# current_prize -= prize_per_word
	# if current_prize < minimum_prize:
	# 	current_prize = minimum_prize
	# update_pot_display()

	# Advance to next player
	PlayerManager.next_turn()	
	var next_player = PlayerManager.get_current_player()
	if next_player:
		print("Next turn: %s" % next_player.name)
		current_player_label.text = next_player.name

# Guess Button
func _on_guess_btn_pressed() -> void:
	print("Guess button pressed. Current pot: %d" % int(current_prize))
	var answer_modal = preload("res://scenes/components/answer_modal.tscn").instantiate()
	add_child(answer_modal)
	answer_modal.answer_submitted.connect(_on_answer_submitted)

# Answer submitted signal
func _on_answer_submitted(answer_text: String) -> void:
	var current_player = PlayerManager.get_current_player()
	if not current_player:
		print("No current player to award points to.")
		return
	var is_correct = answer_text.strip_edges().to_lower() == current_question.answer.strip_edges().to_lower()
	if is_correct:
		print("CORRECT ANSWER!")
		round_result.emit(current_player, true, int(current_prize))
	else:
		print("WRONG ANSWER. The correct answer was: %s" % current_question.answer)
		round_result.emit(current_player, false, int(current_prize))



