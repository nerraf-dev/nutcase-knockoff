extends Node

# GameManager — scripts/autoload/GameManager.gd
# Autoload singleton. Owns the game state machine, scoring rules, and question pool.
#
# STATE MACHINE NOTES:
#   LOBBY   — defined but never entered; needed for multiplayer player-join phase.
#   ROUND_END — defined but never entered; the game jumps directly back to IN_PROGRESS.
#             Use this state if you want a pause/summary between rounds.
#
# MULTIPLAYER TODO:
#   - start_game() currently creates players from a count. For MP, players are already
#     in PlayerManager from the lobby. start_game() should only initialise questions/state.
#   - question deduplication uses question_text as a key — fragile. Add an id field
#     to Question and use that instead. See code review doc § 2.6.

enum GameState {
	NONE,           # No game active
	MENU,           # Main menu
	SETUP,          # Configuring game settings
	LOBBY,          # Waiting for players to connect (future — needed for multiplayer)
	IN_PROGRESS,    # Game active
	ROUND_END,      # Between rounds (defined but currently unused — see header note)
	GAME_OVER       # Winner declared
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

func _ready() -> void:
	print("GameManager initialized")
	game_ended.connect(_on_game_ended)

# Start a new game with given settings
func start_game(settings: Dictionary) -> bool:
	print("Starting new game with settings: %s" % settings)
	game = Game.new()
	game.id = GameIdGenerator.get_random_id()
	game.game_type = settings.get("game_type", "qna")
	game.game_mode = settings.get("game_mode", "single")
	game.game_target = settings.get("game_target", 1000)
	game.fuzzy_enabled = settings.get("fuzzy_enabled", GameConfig.FUZZY_ENABLED_DEFAULT)
	game.current_round = 1
	game.is_active = true
	
	# single or multi
	if settings.get("game_mode", "multi") == "single":
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
		elif PlayerManager.players.size() < 2 and settings.get("game_mode", "multi") == "multi":
			push_warning("Warning: Less than 2 players in PlayerManager for multiplayer mode!")
			return false
		
	# Load questions
	const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")
	available_questions = QuestionLoaderResource.load_questions_from_file("res://data/questions.json")
	used_question_ids.clear()
	
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
	var winners: Array[Player] = []
	for player in PlayerManager.get_active_players():
		if player.score >= game.game_target:
			winners.append(player)
	return winners

# Handle wrong answer with frozen player logic
func handle_wrong_answer(player: Player, base_prize: int) -> Dictionary:
	var result = {
		"player": player,
		"penalty": 0,
		"is_frozen": false,
		"is_last_standing": false,
		"is_lps_wrong": false,  # NEW: Last player standing guessed wrong
		"last_standing_player": null,
		"correct_answer": "",
		"message": ""
	}
	
	var active_players = PlayerManager.get_active_players()
	
	# If multiple players active, apply penalty and freeze
	if active_players.size() > 1:
		var penalty = int(base_prize * GameConfig.PENALTY_MULTIPLIER)
		PlayerManager.award_points(player, -penalty)
		PlayerManager.freeze_player(player)
		result["penalty"] = penalty
		result["is_frozen"] = true
		result["message"] = "Incorrect %s!\nYou lose %d points!" % [player.name, penalty]
		print("Player %s is now frozen for this question." % player.name)
		# PlayerManager.next_turn()
		
		# Check if now last player standing
		active_players = PlayerManager.get_active_players()
		if active_players.size() == 1:
			result["is_last_standing"] = true
			result["last_standing_player"] = active_players[0]
			result["message"] = "Last player standing!\n%s gets a free guess!" % active_players[0].name
			print("Free guess for %s - no penalty applied" % active_players[0].name)
			# PlayerManager.next_turn()  # Advance to last player
	
	# If only 1 player active (LPS got it wrong), end the round
	elif active_players.size() == 1:
		result["is_lps_wrong"] = true
		result["correct_answer"] = game.current_question.answer if game.current_question else ""
		result["message"] = "Wrong!\nThe answer was: %s" % result["correct_answer"]
		print("Last player standing got it wrong. Round ends.")
	return result

# Handle correct answer with winner checking
func handle_correct_answer(player: Player, prize: int, type: SubmissionResult) -> Dictionary:
	var result = {
		"player": player,
		"prize": prize,
		"was_frozen": player.is_frozen,
		"has_winner": false,
		"winner": null,
		"message": ""
	}
	
	print("Player %s answered correctly!" % player.name)
	PlayerManager.award_points(player, prize)
	player.is_frozen = false  # Unfreeze if they were frozen
	
	if type == SubmissionResult.AUTO_ACCEPT:
		result["message"] = "Close enough, %s!\nYou get %d points!" % [player.name, prize]
	else:
		result["message"] = "Correct %s!\nYou get %d points!" % [player.name, prize]
	
	# Check for winners
	var winners = check_for_winner()
	if not winners.is_empty():
		result["has_winner"] = true
		result["winner"] = winners[0]
		print("We have a winner: %s!" % winners[0].name)
	else:
		print("No winner yet, continuing to next round.")
	
	return result


# Handle vote rejection: no-voters split half the prize.
# On a tie no_voters is empty and nobody is awarded anything.
func handle_vote_rejection(prize: int, no_voters: Array[Player]) -> void:
	if no_voters.is_empty():
		return
	var each_share = int((prize / 2.0) / no_voters.size())
	for voter in no_voters:
		PlayerManager.award_points(voter, each_share)
		print("Vote rejection: %s awarded %d points" % [voter.name, each_share])

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
