extends Node

signal turn_changed(player: Player)
signal player_added(player: Player)
signal player_removed(player: Player)
signal player_scored(player: Player, points: int)

var players: Array[Player] = []
var current_turn_index: int = 0

func _ready() -> void:
	print("PlayerManager initialized")

# Add a new player to the game
func add_player(player_name: String, device_id: String = "") -> Player:
	var player = Player.new("player_%d" % (players.size() + 1), player_name)
	player.device_id = device_id
	players.append(player)
	player_added.emit(player)
	print("Added player: %s (ID: %s)" % [player.name, player.id])
	return player

# Remove a player (e.g., disconnection)
func remove_player(player_id: String) -> void:
	for i in range(players.size()):
		if players[i].id == player_id:
			var removed_player = players[i]
			players.remove_at(i)
			player_removed.emit(removed_player)
			print("Removed player: %s" % removed_player.name)
			# Adjust turn index if needed
			if current_turn_index >= players.size() and players.size() > 0:
				current_turn_index = 0
			return

# Get the player whose turn it is
func get_current_player() -> Player:
	if players.is_empty():
		return null
	return players[current_turn_index]

# Get all active (non-frozen) players
func get_active_players() -> Array[Player]:
	var active: Array[Player] = []
	for player in players:
		if not player.is_frozen:
			active.append(player)
	return active

# Advance to the next player's turn
func next_turn() -> void:
	if players.is_empty():
		return
	
	var attempts = 0
	var max_attempts = players.size()
	
	# Find next non-frozen player
	while attempts < max_attempts:
		current_turn_index = (current_turn_index + 1) % players.size()
		var current = get_current_player()
		
		if not current.is_frozen:
			turn_changed.emit(current)
			print("Turn changed to: %s" % current.name)
			return
		
		attempts += 1
	
	# All players frozen (shouldn't happen in normal gameplay)
	print("Warning: All players are frozen!")

# Award points to a player
func award_points(player: Player, points: int) -> void:
	player.add_score(points)
	player_scored.emit(player, points)

# Freeze a player (wrong guess)
func freeze_player(player: Player) -> void:
	player.freeze()
	
	# If it was their turn, move to next player
	if get_current_player() == player:
		next_turn()

# Unfreeze all players (e.g., new round)
func unfreeze_all_players() -> void:
	for player in players:
		player.unfreeze()
	print("All players unfrozen")

# Get player by ID
func get_player_by_id(player_id: String) -> Player:
	for player in players:
		if player.id == player_id:
			return player
	return null

# Get scoreboard (sorted by score)
func get_scoreboard() -> Array[Player]:
	var sorted_players = players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	return sorted_players

# Reset for new game
func reset_game() -> void:
	for player in players:
		player.score = 0
		player.is_frozen = false
	current_turn_index = 0
	print("Game reset")

# Clear all players
func clear_all_players() -> void:
	players.clear()
	current_turn_index = 0
	print("All players cleared")
