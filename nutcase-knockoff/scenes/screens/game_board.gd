extends Node2D

const SliderScene = preload("res://scenes/components/Slider.tscn")
const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")

@onready var grid = $GridContainer
@onready var pot_label = $HUD/PotLabel
@onready var guess_btn = $HUD/GuessBtn
@onready var player_list = $HUD/PlayerList
@onready var current_player_label = $HUD/PlayerList/Current

const BASE_POT = 100.0
const MINIMUM_POT_PERCENT = 0.1  # Always reserve 10% as minimum pot
const DIFFICULTY_MULTIPLIERS = {
	"easy": 1.0,
	"medium": 1.5,
	"hard": 2.0
}


var current_pot = 100.0
var minimum_pot = 10.0
var pot_per_word = 0.0
var all_questions: Array[Question] = []
var current_question: Question = null

func _ready() -> void:
	print("MainGame scene ready")
	guess_btn.pressed.connect(_on_guess_btn_pressed)
	
	# Load questions from JSON
	all_questions = QuestionLoaderResource.load_questions_from_file("res://data/questions.json")
	
	current_player_label.text = PlayerManager.get_current_player().name
	print("First child of player_list: %s" % current_player_label.text)
	
	# Get a random question and spawn it
	var random_question = QuestionLoaderResource.get_random_question(all_questions)
	if random_question:
		current_question = random_question
		spawn_question(random_question)
		update_pot_display()
	else:
		push_error("No questions loaded!")

func spawn_question(question: Question) -> void:
	print("Spawning question: %s" % question.question_text)
	var words = question.question_text.split(" ")
	
	# Calculate pot based on difficulty
	var difficulty_mult = DIFFICULTY_MULTIPLIERS.get(question.difficulty, 1.0)
	current_pot = BASE_POT * difficulty_mult
	# Reserve minimum pot (e.g., 10% of starting pot)
	minimum_pot = current_pot * MINIMUM_POT_PERCENT
	# Divide only the reducible portion among words
	var reducible_pot = current_pot - minimum_pot
	pot_per_word = reducible_pot / words.size()
	print("Difficulty: %s | Starting pot: %d | Minimum guaranteed: %d" % [question.difficulty, int(current_pot), int(minimum_pot)])

	# Spawns a slider for each word in the `words` array, adds it to the grid, and connects its click signal.
	# Each slider is given a minimum size and is numbered (1-indexed) when set up.
	for i in range(words.size()):
		var s = SliderScene.instantiate()
		s.custom_minimum_size = Vector2(250, 80)  # Match the size from the scene
		grid.columns = 3
		grid.add_child(s)
		s.set_word(words[i], i + 1)  # Pass word and number (1-indexed)
		s.clicked.connect(_on_slider_clicked)


# Handles the event when the slider is clicked.
# Decreases the current pot by the value of pot_per_word.
# Ensures the current pot does not go below zero.
# Updates the pot display and prints the new pot value to the output.
func _on_slider_clicked():
	current_pot -= pot_per_word
	if current_pot < minimum_pot:
		current_pot = minimum_pot
	update_pot_display()
	print("Word revealed! Pot now: %d (min: %d)" % [int(current_pot), int(minimum_pot)])
	# Next player
	PlayerManager.next_turn()
	print("Next turn: %s" % PlayerManager.get_current_player().name)
	# print("First child of player_list: %s" % current_player_label.text)
	current_player_label.text = PlayerManager.get_current_player().name


# Update the score on the screen
func update_pot_display():
	pot_label.text = str(int(current_pot))

func _on_guess_btn_pressed() -> void:
	print("Guess button pressed. Current pot: %d" % int(current_pot))
	# Here you would typically open the answer modal to allow the player to submit their guess
	var answer_modal = preload("res://scenes/components/answer_modal.tscn").instantiate()
	add_child(answer_modal)
	answer_modal.answer_submitted.connect(_on_answer_submitted)
	answer_modal.cancelled.connect(_on_answer_cancelled)

func _on_answer_submitted(answer_text: String) -> void:
	print("Player submitted answer: %s" % answer_text)
	# Here you would check the answer and award points if correct
	if answer_text.strip_edges().to_lower() == current_question.answer.strip_edges().to_lower():
		print("CORRECT ANSWER!")
		# Award points to current player
		var current_player = PlayerManager.get_current_player()
		if current_player:
			PlayerManager.award_points(current_player, int(current_pot))
		else:
			print("No current player to award points to.")
	else:
		print("WRONG ANSWER. The correct answer was: %s" % current_question.answer)

func _on_answer_cancelled() -> void:
	print("Player cancelled the answer submission.")
