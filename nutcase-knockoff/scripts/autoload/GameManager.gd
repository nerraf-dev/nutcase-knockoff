extends Node

# --- GameManager Data Fields ---
# id: String                # Unique game ID
# num_players: int          # Number of players
# current_round: int        # Current round number
# total_rounds: int         # Total rounds in the game
# game_type: String         # Game mode/type
# game_length: int          # Game length
# is_active: bool           # Is the game currently active
# rounds: Array[String]     # List of round types (e.g., ["QnA", "Puzzle", "Speed"])
#
# player_ids: Array[String]         # Player IDs for all players in this session
# frozen_players: Array[String]     # Player IDs who are currently frozen
# eliminated_players: Array[String] # Player IDs who are eliminated
#
# round_history: Array              # Array of {round: int, question: Question, result: Dictionary}
# current_question: Resource        # Current question (if any)

signal game_started
signal game_ended(winner: Player)

var game: Game = null

func _ready() -> void:
    print("GameManager initialized")

# Start a new game with given settings
func start_game(settings: Dictionary) -> void:
    print("Starting new game with settings: %s" % settings)
    game = Game.new()
    game.id = GameIdGenerator.get_random_id() 
    game.num_players = settings.get("player_count", 2)
    game.game_type = settings.get("game_type", "")

    # Initialize game state here
    game_started.emit()