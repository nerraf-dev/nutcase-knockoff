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

signal round_result(player: Player, is_correct: int, points: int, submitted_answer: String, meta: Dictionary) # Emitted when a guess is submitted and validated, with the result and points to award
signal slider_reveal_requested(index: int)
signal guess_submitted(answer: String)

const SliderScene = preload("res://scenes/components/Slider.tscn")
const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")

@onready var grid = $GridContainer
@onready var guess_btn = $GuessBtn
@onready var current_player_label = $CurrentPlayer
@onready var prize_label = $Prize

const FIXED_BASE_POINTS = 50.0
const USE_DIFFICULTY_MULTIPLIER = true
const BONUS_EARLY_MAX_REVEAL_RATIO = 0.4
const BONUS_MID_MAX_REVEAL_RATIO = 0.7
const BONUS_EARLY_POINTS = 6
const BONUS_MID_POINTS = 3
const GRID_COLUMNS = 3
const GRID_ROWS = 3
const DIFFICULTY_MULTIPLIERS = {
	"easy": 1.0,
	"medium": 1.5,
	"hard": 2.0
}

@export var auto_start_first_question: bool = true

var current_prize = 0.0
var _question_word_count: int = 0
var _revealed_word_count: int = 0
var _revealed_word_indices: Dictionary = {}
var all_questions: Array[Question] = []
var current_question: Question = null
var _sliders: Array = [] # slider instances by position, for programmatic reveal in multiplayer

func _ready() -> void:
	print("QnA scene ready")
	guess_btn.pressed.connect(_on_guess_btn_pressed)
	slider_reveal_requested.connect(_handle_slider_reveal)
	guess_submitted.connect(_on_answer_submitted) # NetworkManager will emit this with answer text in multiplayer
	
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

	if auto_start_first_question:
		# Backward compatible fallback for contexts that still instantiate QnA directly.
		var first_question = GameManager.get_next_question()
		if first_question:
			start_new_question(first_question)
		else:
			push_error("No questions available!")
			return
	if GameManager.game.game_mode == "multi":
		guess_btn.visible = false # Guesses come from players' phones in multiplayer, so hide local guess button

# Update the score on the screen
func update_pot_display() -> void:
	prize_label.text = str(int(current_prize))

func _on_turn_changed(player: Player) -> void:
	current_player_label.text = "It's %s's turn" % player.name


func begin_guessing(player_name: String) -> void:
	current_player_label.text = "%s is guessing..." % player_name

func _get_question_base_points() -> float:
	if current_question == null:
		return FIXED_BASE_POINTS
	var difficulty_mult = 1.0
	if USE_DIFFICULTY_MULTIPLIER:
		difficulty_mult = DIFFICULTY_MULTIPLIERS.get(current_question.difficulty, 1.0)
	return FIXED_BASE_POINTS * difficulty_mult

func _calculate_bonus_points(total_word_count: int, revealed_word_count: int) -> int:
	if total_word_count <= 0:
		return 0
	var early_threshold = int(floor(float(total_word_count) * BONUS_EARLY_MAX_REVEAL_RATIO))
	var mid_threshold = int(floor(float(total_word_count) * BONUS_MID_MAX_REVEAL_RATIO))
	if revealed_word_count <= early_threshold:
		return BONUS_EARLY_POINTS
	if revealed_word_count <= mid_threshold:
		return BONUS_MID_POINTS
	return 0

func _calculate_points_for_state(base_points: float, total_word_count: int, revealed_word_count: int) -> float:
	return base_points + float(_calculate_bonus_points(total_word_count, revealed_word_count))

func get_current_score_breakdown() -> Dictionary:
	var base_points = int(_get_question_base_points())
	var bonus_points = _calculate_bonus_points(_question_word_count, _revealed_word_count)
	return {
		"base_points": base_points,
		"bonus_points": bonus_points,
		"total_points": base_points + bonus_points,
		"revealed_word_count": _revealed_word_count,
		"question_word_count": _question_word_count
	}

func _get_uniform_slider_size() -> Vector2:
	# Keep all 9 tiles identical regardless of word length.
	var h_sep = float(grid.get_theme_constant("h_separation"))
	var v_sep = float(grid.get_theme_constant("v_separation"))
	var grid_size = grid.size
	if grid_size.x <= 0.0 or grid_size.y <= 0.0:
		grid_size = grid.custom_minimum_size

	var usable_width = max(grid_size.x - (GRID_COLUMNS - 1) * h_sep, 1.0)
	var usable_height = max(grid_size.y - (GRID_ROWS - 1) * v_sep, 1.0)
	return Vector2(usable_width / GRID_COLUMNS, usable_height / GRID_ROWS)

 
func start_new_question(question: Question) -> void:
	# Clear old sliders
	_sliders.clear()
	for child in grid.get_children():
		child.queue_free()
	
	# Set new question
	current_question = question
	print("Starting new question: %s" % question.question_text)
	print("Answer is: %s" % question.answer)
	
	# Reset scoring state for this question.
	var words = question.question_text.split(" ")
	_question_word_count = min(words.size(), GRID_COLUMNS * GRID_ROWS)
	_revealed_word_count = 0
	_revealed_word_indices.clear()
	var base_points = _get_question_base_points()
	current_prize = _calculate_points_for_state(base_points, _question_word_count, _revealed_word_count)
	update_pot_display()
	
	var current_player = PlayerManager.get_current_player()
	if current_player:
		current_player_label.text = "It's %s's turn" % current_player.name
	print("Difficulty: %s | Base points: %d | Starting award with bonus: %d" % [question.difficulty, int(base_points), int(current_prize)])
	
	var tile_size = _get_uniform_slider_size()
	var sliders = []
	# Always create exactly 9 tiles for a 3x3 grid
	for i in range(9):
		var s = SliderScene.instantiate()
		grid.add_child(s)
		
		# Force a uniform tile size so one long word cannot stretch a column.
		s.custom_minimum_size = tile_size
		s.size_flags_horizontal = Control.SIZE_FILL
		s.size_flags_vertical = Control.SIZE_FILL
		
		# If we have a word for this position, use it; otherwise blank
		if i < words.size():
			s.set_word(words[i], i + 1)
		else:
			s.set_word("", i + 1) # Blank tile
		
		var idx = i
		s.clicked.connect(func(_w, _b): slider_reveal_requested.emit(idx))
		sliders.append(s)
		_sliders.append(s)
	
	# Setup focus navigation in grid order (left-right, top-bottom)
	await get_tree().process_frame
	_setup_slider_navigation(sliders, GRID_COLUMNS)
	
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

# Handle a slider reveal — triggered via slider_reveal_requested signal.
# In local play the signal is emitted by the slider's own click callback.
# In multiplayer it will be emitted by NetworkManager on receiving a click_slider message.
func _handle_slider_reveal(index: int) -> void:
	var words = current_question.question_text.split(" ")
	var is_blank = index >= words.size()
	var revealer = PlayerManager.get_current_player()
	if index < 0 or index >= _sliders.size():
		push_error("Invalid slider index revealed: %d" % index)
		return
	_sliders[index].reveal()
	print("Slider reveal - index: %d, blank: %s" % [index, is_blank])

	# Notify controllers which tile was revealed.
	if not NetworkManager.is_local:
		var revealed_word = ""
		if not is_blank:
			revealed_word = words[index]
		var revealer_id = revealer.id if revealer != null else ""
		NetworkManager.broadcast_slider_revealed(index, revealed_word, revealer_id)
	
	# Turn advancement — two separate call sites, mutually exclusive:
	#   1. Slider reveal (here): next_turn() called after a word tile is clicked.
	#   2. Wrong guess: freeze_player() in PlayerManager calls next_turn() internally.
	# These can't both fire in the same interaction, so there is no double-advance.
	
	# Only apply mechanics for non-blank (word-containing) tiles
	if not is_blank:
		if not _revealed_word_indices.has(index):
			_revealed_word_indices[index] = true
			_revealed_word_count += 1
		# Score bonus shrinks as more clue words are revealed.
		current_prize = _calculate_points_for_state(_get_question_base_points(), _question_word_count, _revealed_word_count)
		update_pot_display()
		PlayerManager.next_turn()
	var next_player = PlayerManager.get_current_player()
	if next_player:
		print("Next turn: %s" % next_player.name)
		current_player_label.text = "It's %s's turn" % next_player.name
	# hook for multiplayer: emit signal to send reveal event to clients so they can update their displays

# Guess Button
func _on_guess_btn_pressed() -> void:
	UISfx.play_ui_click()
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
	var validation = InputValidator.validate_answer(answer_text, current_question, GameManager.game.fuzzy_enabled)
	if validation["result"] == InputValidator.ValidationResult.INCORRECT:
		print("Incorrect answer submitted: '%s'" % answer_text)
		round_result.emit(current_player, GameManager.SubmissionResult.INCORRECT, int(current_prize), answer_text, {})
	elif validation["result"] == InputValidator.ValidationResult.FUZZY:
		print("Fuzzy answer submitted: '%s'" % answer_text)
		round_result.emit(current_player, GameManager.SubmissionResult.FUZZY, int(current_prize), answer_text, {"distance": validation["distance"]})
	elif validation["result"] == InputValidator.ValidationResult.AUTO_ACCEPT:
		print("Auto-accept candidate: '%s' (distance %s)" % [answer_text, validation["distance"]])
		round_result.emit(current_player, GameManager.SubmissionResult.AUTO_ACCEPT, int(current_prize), answer_text, {"distance": validation["distance"]})
	elif validation["result"] == InputValidator.ValidationResult.EXACT:
		print("Exact answer submitted: '%s'" % answer_text)
		round_result.emit(current_player, GameManager.SubmissionResult.EXACT, int(current_prize), answer_text, {})
	else:
		print("Unexpected validation result for answer '%s': %s" % [answer_text, validation["result"]])
		round_result.emit(current_player, GameManager.SubmissionResult.INVALID, int(current_prize), answer_text, {})
