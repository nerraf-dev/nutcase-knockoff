extends Node

signal game_started
signal game_ended(winner: Player)

func _ready() -> void:
    print("GameManager initialized")

# Start a new game with given settings
func start_game(settings: Dictionary) -> void:
    print("Starting new game with settings: %s" % settings)
    # Initialize game state here
    game_started.emit()