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
var available_questions: Array[Question] = []
var used_question_ids: Array[String] = []

func _ready() -> void:
    print("GameManager initialized")
    game_ended.connect(_on_game_ended)

# Start a new game with given settings
func start_game(settings: Dictionary) -> void:
    print("Starting new game with settings: %s" % settings)
    game = Game.new()
    game.id = GameIdGenerator.get_random_id()
    game.game_type = settings.get("game_type", "qna")
    game.game_target = settings.get("game_target", 1000)
    game.current_round = 1
    game.is_active = true
    
    # Load players
    for i in range(settings.get("player_count", 2)):
        var player_name = "Player %d" % (i + 1)
        PlayerManager.add_player(player_name)

    # Load questions
    const QuestionLoaderResource = preload("res://scripts/logic/QuestionLoader.gd")
    available_questions = QuestionLoaderResource.load_questions_from_file("res://data/questions.json")
    used_question_ids.clear()
    
    print("Game started with %d players" % PlayerManager.players.size())
    game_started.emit()

# Get next unused question
func get_next_question() -> Question:
    var unused = available_questions.filter(func(q): 
        return not used_question_ids.has(q.question_text)
    )
    if unused.is_empty():
        print("No more unused questions!")
        return null
    var next_q = unused.pick_random()
    used_question_ids.append(next_q.question_text)
    return next_q

# Check for winner by score
func check_for_winner() -> Array[Player]:
    var winners: Array[Player] = []
    for player in PlayerManager.get_active_players():
        if player.score >= game.game_target:
            winners.append(player)
    return winners

func round_res_handler() -> void:
    var winners = check_for_winner()
    if winners.is_empty():
        PlayerManager.unfreeze_all_players()
        PlayerManager.next_turn()
    else:
        game_ended.emit(winners[0])

func _on_game_ended(winner: Player) -> void:
    print("Game ended! Winner: %s" % winner.name)
    game.is_active = false
    
    # On game end:
        # - Show winner/results
        # - provide option to play with same settings or back to home
        # - clean up the game state and scenes if needed

    