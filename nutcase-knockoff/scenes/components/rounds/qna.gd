extends Control

# QnA Round Scene — qna.gd
# Manages a single QnA round: displays the slider grid, handles reveal events,
# and processes the Guess button / answer submission.
#
# CURRENT STATE (single-screen local play):
#   All input (slider clicks, guess button) is handled directly via _gui_input
#   and Button.pressed signals on this scene.
#
# MULTIPLAYER TODO:
#   This scene needs to be decoupled from direct input. Slider reveals and guesses
#   should arrive as signals from a NetworkManager rather than from local UI events.
#   The on-screen slider grid becomes display-only; the player's phone sends actions.
#   See 04-sprint/2026-03-04-code-review.md § Step 3 for the refactor plan.

signal round_result(player: Player, is_correct: bool, points: int)

const SliderScene = preload("res://scenes/components/Slider.tscn")
const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")

@onready var grid = $CenterContainer/GridContainer
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
	
	# Add spacing between sliders
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 40)
	
	# Connect to turn changes so label updates when turn advances
	PlayerManager.turn_changed.connect(_on_turn_changed)
	
	var current_player = PlayerManager.get_current_player()
	if current_player:
		current_player_label.text = "It's %s's turn" % current_player.name
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
	current_player_label.text = "It's %s's turn" % player.name

 
func start_new_question(question: Question) -> void:
	# Clear old sliders
	for child in grid.get_children():
		child.queue_free()
	
	# Set new question
	current_question = question
	print("Starting new question: %s" % question.question_text)
	print("Answer is: %s" % question.answer)
	
	# Recalculate pot - only actual words reduce prize
	var words = question.question_text.split(" ")
	var difficulty_mult = DIFFICULTY_MULTIPLIERS.get(question.difficulty, 1.0)
	current_prize = BASE_POT * difficulty_mult
	minimum_prize = current_prize * MINIMUM_POT_PERCENT
	var reducible_prize = current_prize - minimum_prize
	prize_per_word = reducible_prize / words.size()  # Only count real words
	update_pot_display()
	
	var current_player = PlayerManager.get_current_player()
	if current_player:
		current_player_label.text = "It's %s's turn" % current_player.name
	print("Difficulty: %s | Starting pot: %d | Minimum guaranteed: %d" % [question.difficulty, int(current_prize), int(minimum_prize)])
	
	var sliders = []
	# Always create exactly 9 tiles for a 3x3 grid
	for i in range(9):
		var s = SliderScene.instantiate()
		grid.add_child(s)
		
		# Set fixed size for all sliders
		s.custom_minimum_size = Vector2(280, 100)
		s.size_flags_horizontal = Control.SIZE_FILL
		s.size_flags_vertical = Control.SIZE_FILL
		
		# If we have a word for this position, use it; otherwise blank
		if i < words.size():
			s.set_word(words[i], i + 1)
		else:
			s.set_word("", i + 1)  # Blank tile
		
		s.clicked.connect(_on_slider_clicked)
		sliders.append(s)
	
	# Setup focus navigation in grid order (left-right, top-bottom)
	await get_tree().process_frame
	_setup_slider_navigation(sliders, 3)  # 3 columns
	
	# Focus first slider for controller navigation
	if sliders.size() > 0:
		sliders[0].grab_focus()

func _setup_slider_navigation(sliders: Array, columns: int) -> void:
	var rows = ceil(float(sliders.size()) / columns)
	
	for i in range(sliders.size()):
		var slider = sliders[i]
		var row = i / columns
		var col = i % columns
		
		# Left neighbor
		if col > 0:
			slider.focus_neighbor_left = sliders[i - 1].get_path()
		
		# Right neighbor
		if col < columns - 1 and i + 1 < sliders.size():
			slider.focus_neighbor_right = sliders[i + 1].get_path()
		
		# Up neighbor
		if row > 0:
			var up_index = i - columns
			if up_index >= 0:
				slider.focus_neighbor_top = sliders[up_index].get_path()
		
		# Down neighbor
		if row < rows - 1:
			var down_index = i + columns
			if down_index < sliders.size():
				slider.focus_neighbor_bottom = sliders[down_index].get_path()
		
		# Tab to next slider, or to guess button at end
		if i + 1 < sliders.size():
			slider.focus_next = sliders[i + 1].get_path()
		else:
			slider.focus_next = guess_btn.get_path()

# Advance to next player
func _on_slider_clicked(word: String, is_blank: bool):
	print("Slider clicked - Word: '%s', Blank: %s" % [word, is_blank])
	
	# Turn advancement — two separate call sites, mutually exclusive:
	#   1. Slider reveal (here): next_turn() called after a word tile is clicked.
	#   2. Wrong guess: freeze_player() in PlayerManager calls next_turn() internally.
	# These can't both fire in the same interaction, so there is no double-advance.
	# Note: handle_wrong_answer() in GameManager has a commented-out next_turn() call —
	# that was correctly removed since freeze_player() already handles it.
	
	# Only apply mechanics for non-blank (word-containing) tiles
	if not is_blank:
		# Pot reduces with each word revealed — core mechanic. Re-enabled 2026-03-04.
		current_prize = max(current_prize - prize_per_word, minimum_prize)
		update_pot_display()
		PlayerManager.next_turn()	
	var next_player = PlayerManager.get_current_player()
	if next_player:
		print("Next turn: %s" % next_player.name)
		current_player_label.text = "It's %s's turn" % next_player.name

# Guess Button
func _on_guess_btn_pressed() -> void:
	print("Guess button pressed. Current pot: %d" % int(current_prize))
	var answer_modal = preload("res://scenes/components/answer_modal.tscn").instantiate()
	add_child(answer_modal)
	answer_modal.answer_submitted.connect(_on_answer_submitted)

func show_answer_modal_for_free_guess() -> void:
	# Automatically show answer modal for free guess
	var answer_modal = preload("res://scenes/components/answer_modal.tscn").instantiate()
	add_child(answer_modal)
	answer_modal.answer_submitted.connect(_on_answer_submitted)

# Answer submitted signal
func _on_answer_submitted(answer_text: String) -> void:
	var current_player = PlayerManager.get_current_player()
	if not current_player:
		print("No current player to award points to.")
		return
	
	# Empty answers are already blocked by answer_modal before this signal fires,
	# but validate here as a safety net and to keep validation logic centralised.
	# TODO: Add fuzzy matching to InputValidator.validate_answer() — e.g. Levenshtein
	#   distance ≤ 1-2 — so minor typos don't count as wrong on mobile. See review § 2.5.
	var validation = InputValidator.validate_answer(answer_text, current_question)
	# Note: the validation result can be INVALID, FUZZY, AUTO_ACCEPT, or VALID.

	# INCORRECT ANSWER - INVALID
	if validation["result"] == InputValidator.ValidationResult.INVALID:
		print("Invalid answer submitted: '%s'" % answer_text)
		round_result.emit(current_player, false, int(current_prize))
	# FUZZY MATCH - lauch confirm flow.
	elif validation["result"] == InputValidator.ValidationResult.FUZZY:
		print("Fuzzy answer submitted: '%s'" % answer_text)
		# Treat fuzzy as correct for now.
		#  Fuzzy should begin the player confirmation and possible vote scenario.
		round_result.emit(current_player, true, int(current_prize))
	# AUTO_ACCEPT - minor issues but close enough to count as correct. No confirm needed.
	elif validation["result"] == InputValidator.ValidationResult.AUTO_ACCEPT:
		print("Answer submitted with minor issues: '%s'" % answer_text)
		print("Levenshtein distance from correct answer: %s" % validation["distance"])
		round_result.emit(current_player, true, int(current_prize))
	# EXACT MATCH - straightforward correct answer.
	elif validation["result"] == InputValidator.ValidationResult.EXACT:
		print("Exact answer submitted: '%s'" % answer_text)
		round_result.emit(current_player, true, int(current_prize))
	else:
		print("Unexpected validation result for answer '%s': %s" % [answer_text, validation["result"]])
		round_result.emit(current_player, false, int(current_prize))

	# var is_correct = answer_text.strip_edges().to_lower() == current_question.answer.strip_edges().to_lower()
	# if is_correct:
	# 	print("CORRECT ANSWER!")
	# 	round_result.emit(current_player, true, int(current_prize))
	# else:
	# 	print("WRONG ANSWER. The correct answer was: %s" % current_question.answer)
	# 	round_result.emit(current_player, false, int(current_prize))
