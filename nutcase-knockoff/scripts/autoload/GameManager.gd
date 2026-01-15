extends Node

enum GameState {
    NONE,           # No game active
    MENU,           # Main menu
    SETUP,          # Configuring game settings
    LOBBY,          # Waiting for players to connect (future)
    IN_PROGRESS,    # Game active
    ROUND_END,      # Between rounds
    GAME_OVER       # Winner declared
}

signal game_started
signal game_ended(winner: Player)
signal state_changed(old_state: GameState, new_state: GameState)

var current_state: GameState = GameState.NONE
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
    
    change_state(GameState.IN_PROGRESS)
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

# Handle wrong answer with frozen player logic
func handle_wrong_answer(player: Player, base_prize: int) -> Dictionary:
    var result = {
        "player": player,
        "penalty": 0,
        "is_frozen": false,
        "is_last_standing": false,
        "last_standing_player": null,
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
        PlayerManager.next_turn()
        
        # Check if now last player standing
        active_players = PlayerManager.get_active_players()
        if active_players.size() == 1:
            result["is_last_standing"] = true
            result["last_standing_player"] = active_players[0]
            result["message"] = "Last player standing!\n%s gets a free guess!" % active_players[0].name
            print("Free guess for %s - no penalty applied" % active_players[0].name)
            PlayerManager.next_turn()  # Advance to last player
    
    return result

# Handle correct answer with winner checking
func handle_correct_answer(player: Player, prize: int) -> Dictionary:
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