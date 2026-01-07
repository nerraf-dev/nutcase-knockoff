class_name Game
extends Resource


# Unique game ID
var id: String = ""
# Number of players
var num_players: int = 0
# Current round number
var current_round: int = 0
# Total rounds in the game
var total_rounds: int = 0
# Game mode/type
var game_type: String = ""
# Game target score
var game_target: int = 1000
# Is the game currently active
var is_active: bool = false
# List of round types (e.g., ["QnA", "Puzzle", "Speed"])
var rounds: Array[String] = []

# --- Game state and player tracking ---
# Player IDs for all players in this session
var player_ids: Array[String] = []
# Player IDs who are currently frozen (cannot act this round)
var frozen_players: Array[String] = []
# Player IDs who are eliminated (if applicable)
var eliminated_players: Array[String] = []

# --- Round/question/result history ---
# Array of dictionaries: {round: int, question: Question, result: Dictionary}
var round_history: Array = []
# Current question (if any)
var current_question: Resource = null

# --- Methods ---

# Freeze a player by ID
func freeze_player(player_id: String) -> void:
	if not frozen_players.has(player_id):
		frozen_players.append(player_id)

# Unfreeze all players
func unfreeze_all_players() -> void:
	frozen_players.clear()

# Eliminate a player by ID
func eliminate_player(player_id: String) -> void:
	if not eliminated_players.has(player_id):
		eliminated_players.append(player_id)
		# Also freeze them
		freeze_player(player_id)

# Check if only one active (not frozen or eliminated) player remains
func is_last_active_player() -> bool:
	var active = []
	for pid in player_ids:
		if not frozen_players.has(pid) and not eliminated_players.has(pid):
			active.append(pid)
	return active.size() == 1

# Get all active (not frozen/eliminated) player IDs
func get_active_players() -> Array[String]:
	var active = []
	for pid in player_ids:
		if not frozen_players.has(pid) and not eliminated_players.has(pid):
			active.append(pid)
	return active

# Record round result
func record_round_result(round_num: int, question: Resource, result: Dictionary) -> void:
	round_history.append({"round": round_num, "question": question, "result": result})

# Set the current question
func set_current_question(q: Resource) -> void:
	current_question = q

# Clear all state for a new game
func reset() -> void:
	current_round = 0
	is_active = false
	round_history.clear()
	frozen_players.clear()
	eliminated_players.clear()
	current_question = null

# Returns an array of winning player IDs (empty if no winner yet, one if a single winner, or multiple in case of a tie)
func get_winners() -> Array[String]:
	var winners: Array[String] = []
	var active_players = get_active_players()

	# If only one active player remains, they win
	if active_players.size() == 1:
		winners.append(active_players[0])
		return winners

	# Check for players who reached or exceeded the target score
	var max_score = -INF
	for pid in active_players:
		var player = PlayerManager.get_player_by_id(pid)
		if player != null:
			if player.score > max_score:
				max_score = player.score

	# If any player(s) meet or exceed the target, collect all with max_score >= game_target
	if max_score >= game_target:
		for pid in active_players:
			var player = PlayerManager.get_player_by_id(pid)
			if player != null and player.score == max_score:
				winners.append(pid)

	return winners

