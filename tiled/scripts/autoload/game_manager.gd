extends Node

# GameManager — scripts/autoload/game_manager.gd
# Role: Autoload singleton that orchestrates game lifecycle and state transitions.
# Owns: Current Game instance, state machine, question pool usage tracking.
# Does not own: Player collection/turn logic (PlayerManager), network transport (NetworkManager).
#
# Public API:
# - start_game(settings)
# - get_next_question()
# - check_for_winner()
# - handle_wrong_answer(...), handle_correct_answer(...), handle_vote_rejection(...)
# - change_state(new_state)
#
# Dependencies:
# - Game, Player, Question
# - PlayerManager, GameIdGenerator, GameConfig
# - RoundScoringRules, QuestionLoader
#
# State notes:
# - Multiplayer path enters IN_PROGRESS from LOBBY.
# - ROUND_END exists for future inter-round pause flow.

enum GameState {
	NONE, # No game active
	MENU, # Main menu
	SETUP, # Configuring game settings
	LOBBY, # Waiting for players to connect (future — needed for multiplayer)
	IN_PROGRESS, # Game active
	ROUND_END, # Between rounds (defined but currently unused — see header note)
	GAME_OVER # Winner declared
}

enum SubmissionResult {
	EXACT,
	AUTO_ACCEPT,
	FUZZY,
	INCORRECT,
	INVALID
}

signal game_started
signal game_ended(winner: Player)
signal state_changed(old_state: GameState, new_state: GameState)

var current_state: GameState = GameState.NONE
var game: Game = null
var available_questions: Array[Question] = []
var used_question_ids: Array[int] = []
const RoundScoringRulesResource = preload("res://scripts/logic/round_scoring_rules.gd")
var _round_resolution = RoundScoringRulesResource.new()

func _ready() -> void:
	print("GameManager initialized")
	game_ended.connect(_on_game_ended)

# Start a new game with given settings
func start_game(settings: Dictionary) -> bool:
	print("Starting new game with settings: %s" % settings)
	var game_mode: String = settings.get("game_mode", "single")
	game = Game.new()
	game.id = GameIdGenerator.get_random_id()
	game.game_type = settings.get("game_type", "qna")
	game.game_mode = game_mode
	game.game_target = settings.get("game_target", 1000)
	game.fuzzy_enabled = settings.get("fuzzy_enabled", GameConfig.FUZZY_ENABLED_DEFAULT)
	game.current_round = 1
	game.is_active = true
	
	# single or multi
	if game_mode == "single":
		print("Single-player mode: creating player instances")
		# Clear any existing players
		if not PlayerManager.players.is_empty():
			PlayerManager.clear_all_players()
			print("Cleared existing players from PlayerManager")
		var player_name = "Player 1"
		if not PlayerManager.add_player(player_name):
			push_error("Failed to create player instance for single-player mode!")
			return false
		else:
			print("Created player: %s (Device ID: %s)" % [player_name, "single_player"])
	else:
		print("Multiplayer mode: using existing players from PlayerManager")
		if PlayerManager.players.is_empty():
			push_warning("Warning: No players found in PlayerManager for multiplayer mode!")
			return false
		elif PlayerManager.players.size() < 2 and game_mode == "multi":
			push_warning("Warning: Less than 2 players in PlayerManager for multiplayer mode!")
			return false
		
	# Load questions
	const QuestionLoaderResource = preload("res://scripts/logic/question_loader.gd")
	available_questions = QuestionLoaderResource.load_questions_from_file("res://data/questions.json")
	used_question_ids.clear()

	# Enforce explicit state progression; start_game should not jump NONE -> IN_PROGRESS.
	if current_state == GameState.NONE:
		change_state(GameState.MENU)
	if current_state == GameState.MENU:
		change_state(GameState.SETUP)
	if current_state != GameState.SETUP and current_state != GameState.LOBBY:
		push_error("GameManager: start_game() expected SETUP or LOBBY state, got %s" % GameState.keys()[current_state])
		return false

	change_state(GameState.IN_PROGRESS)
	print("Game started with %d players" % PlayerManager.players.size())
	game_started.emit()
	return true

# Get next unused question
func get_next_question() -> Question:
	var unused = available_questions.filter(func(q):
		return not used_question_ids.has(q.question_id)
	)
	if unused.is_empty():
		print("No more unused questions!")
		return null
	var next_q = unused.pick_random()
	used_question_ids.append(next_q.question_id)
	# TODO: Consider stripping punction from questions
	# Store current question for access in game logic
	if game:
		game.current_question = next_q
	return next_q

# Check for winner by score
func check_for_winner() -> Array[Player]:
	if game == null:
		return []
	return _round_resolution.check_for_winner(game.game_target)

# Handle wrong answer with frozen player logic
func handle_wrong_answer(player: Player, base_prize: int, submitted_answer: String) -> Dictionary:
	var current_question: Resource = game.current_question if game else null
	return _round_resolution.handle_wrong_answer(player, base_prize, current_question, submitted_answer)

# Handle correct answer with winner checking
func handle_correct_answer(player: Player, prize: int, type: SubmissionResult, submitted_answer: String, scoring_breakdown: Dictionary = {}) -> Dictionary:
	var is_auto_accept := type == SubmissionResult.AUTO_ACCEPT
	var target := game.game_target if game else 0
	return _round_resolution.handle_correct_answer(player, prize, is_auto_accept, target, submitted_answer, scoring_breakdown)


# Handle vote rejection: no-voters split half the prize.
# On a tie no_voters is empty and nobody is awarded anything.
func handle_vote_rejection(prize: int, no_voters: Array[Player]) -> void:
	_round_resolution.handle_vote_rejection(prize, no_voters)

func _on_game_ended(winner: Player) -> void:
	print("Game ended! Winner: %s" % winner.name)
	game.is_active = false
	change_state(GameState.GAME_OVER)

	
func change_state(new_state: GameState) -> void:
	if not _is_valid_transition(current_state, new_state):
		push_error("Invalid state transition from %s to %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
		return

	var old_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)
	print("Game state: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])

func _is_valid_transition(from: GameState, to: GameState) -> bool:
	match from:
		GameState.NONE:
			return to == GameState.MENU
		GameState.MENU:
			return to == GameState.SETUP
		GameState.SETUP:
			return to in [GameState.LOBBY, GameState.IN_PROGRESS, GameState.MENU]
		GameState.LOBBY:
			return to in [GameState.IN_PROGRESS, GameState.MENU]
		GameState.IN_PROGRESS:
			return to in [GameState.ROUND_END, GameState.GAME_OVER, GameState.MENU]
		GameState.ROUND_END:
			return to in [GameState.IN_PROGRESS, GameState.GAME_OVER]
		GameState.GAME_OVER:
			return to == GameState.MENU
	return false
