class_name Player
extends Resource

var id: String = ""              # Unique ID (e.g., "player_1")
var name: String = ""            # Display name ("Alice")
var score: int = 0               # Current points
var is_frozen: bool = false      # Locked out after wrong guess
var device_id: String = ""       # WebSocket connection ID (for multiplayer)
var color: Color = Color.WHITE   # Visual identifier

func _init(p_id: String = "", p_name: String = "Player") -> void:
	id = p_id
	name = p_name
	# Assign random color if not set
	color = Color(randf(), randf(), randf())

func add_score(points: int) -> void:
	score += points
	print("%s scored %d points! Total: %d" % [name, points, score])

func freeze() -> void:
	is_frozen = true
	print("%s has been frozen!" % name)

func unfreeze() -> void:
	is_frozen = false
	print("%s is back in the game!" % name)

func reset_for_new_round() -> void:
	is_frozen = false
