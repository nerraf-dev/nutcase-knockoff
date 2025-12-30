extends Node2D

const SliderScene = preload("res://scenes/components/Slider.tscn")
const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")

@onready var grid = $GridContainer
@onready var pot_label = $HUD/PotLabel

const BASE_POT = 100.0
const DIFFICULTY_MULTIPLIERS = {
	"easy": 1.0,
	"medium": 1.5,
	"hard": 2.0
}

var current_pot = 100.0
var pot_per_word = 0.0
var all_questions: Array[Question] = []

func _ready() -> void:
	# Load questions from JSON
	all_questions = QuestionLoaderResource.load_questions_from_file("res://data/questions.json")
	
	# Get a random question and spawn it
	var random_question = QuestionLoaderResource.get_random_question(all_questions)
	if random_question:
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
	
	# Calculate pot reduction per word
	pot_per_word = current_pot / words.size()
	print("Difficulty: %s | Starting pot: %d" % [question.difficulty, int(current_pot)])

	# Spawns a slider for each word in the `words` array, adds it to the grid, and connects its click signal.
	# Each slider is given a minimum size and is numbered (1-indexed) when set up.
	# After all sliders are added, prints the first word for debugging purposes.
	for i in range(words.size()):
		var s = SliderScene.instantiate()
		s.custom_minimum_size = Vector2(250, 80)  # Match the size from the scene
		grid.columns = 5
		grid.add_child(s)
		s.set_word(words[i], i + 1)  # Pass word and number (1-indexed)
		s.clicked.connect(_on_slider_clicked)
	print("Finished spawning question. First word is %s" % words[0])


# Handles the event when the slider is clicked.
# Decreases the current pot by the value of pot_per_word.
# Ensures the current pot does not go below zero.
# Updates the pot display and prints the new pot value to the output.
func _on_slider_clicked():
	current_pot -= pot_per_word
	if current_pot < 0:
		current_pot = 0
	update_pot_display()
	print("Word revealed! Pot now: %d" % current_pot)

# Update teh score on the screen
func update_pot_display():
	pot_label.text = str(int(current_pot))
