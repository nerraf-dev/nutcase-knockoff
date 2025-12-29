extends Node2D

const SliderScene = preload("res://scenes/components/Slider.tscn")
const QuestionResource = preload("res://scripts/resources/Question.gd")
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

func _ready() -> void:
	# Test call - create a test question
	var test_question = QuestionResource.new()
	test_question.question_text = "How many hours are in a day?"
	test_question.answer = "24"
	test_question.difficulty = "medium"
	test_question.category = "General Knowledge"
	
	spawn_question(test_question)
	update_pot_display()

func spawn_question(question: Question) -> void:
	print("Spawning question: %s" % question.question_text)
	var words = question.question_text.split(" ")
	
	# Calculate pot based on difficulty
	var difficulty_mult = DIFFICULTY_MULTIPLIERS.get(question.difficulty, 1.0)
	current_pot = BASE_POT * difficulty_mult
	
	# Calculate pot reduction per word
	pot_per_word = current_pot / words.size()
	print("Difficulty: %s | Starting pot: %d" % [question.difficulty, int(current_pot)])

	for word in words:
		var s = SliderScene.instantiate()
		s.custom_minimum_size = Vector2(250, 80)  # Match the size from the scene
		grid.columns = 5
		grid.add_child(s)
		s.set_word(word)
		s.clicked.connect(_on_slider_clicked)
	print("Finished spawning question. First word is %s" % words[0])

func _on_slider_clicked():
	current_pot -= pot_per_word
	if current_pot < 0:
		current_pot = 0
	update_pot_display()
	print("Word revealed! Pot now: %d" % current_pot)

func update_pot_display():
	pot_label.text = str(int(current_pot))
