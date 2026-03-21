# Manager Reference

## PlayerManager (Autoload)
**Location**: `scripts/autoload/PlayerManager.gd`  
**Purpose**: Single source of truth for all player data

### Responsibilities
- Maintain player roster
- Track current turn
- Handle scoring
- Manage freeze/unfreeze state
- Emit player-related signals

### Key Properties
```gdscript
var players: Array[Player] = []         # All players in session
var current_turn_index: int = 0         # Index of current player
```

### Core Methods

#### add_player(player_name: String, device_id: String = "") -> Player
Adds a new player to the game.
```gdscript
# Usage
var player = PlayerManager.add_player("Alice")
```
- Creates Player with unique ID
- Appends to players array
- Emits player_added signal
- Returns the created Player

#### remove_player(player_id: String) -> void
Removes a player from the game.
```gdscript
# Usage
PlayerManager.remove_player("player_1")
```
- Finds player by ID
- Removes from array
- Adjusts turn index if needed
- Emits player_removed signal

#### get_current_player() -> Player
Gets the player whose turn it is.
```gdscript
# Usage
var player = PlayerManager.get_current_player()
if player:
    print("Current turn: %s" % player.name)
```
- Returns null if no players
- Returns players[current_turn_index]

#### next_turn() -> void
Advances to next non-frozen player.
```gdscript
# Usage
PlayerManager.next_turn()
```
- Increments turn index (wraps around)
- Skips frozen players
- Emits turn_changed signal
- Prints warning if all frozen

#### award_points(player: Player, points: int) -> void
Adds points to a player's score (can be negative).
```gdscript
# Usage
PlayerManager.award_points(player, 100)      # Add 100 points
PlayerManager.award_points(player, -50)      # Subtract 50 points
```
- Calls player.add_score(points)
- Emits player_scored signal

#### freeze_player(player: Player) -> void
Freezes a player (wrong guess penalty).
```gdscript
# Usage
PlayerManager.freeze_player(player)
```
- Sets player.is_frozen = true
- If their turn, advances to next player

#### unfreeze_all_players() -> void
Unfreezes all players (start of new round).
```gdscript
# Usage
PlayerManager.unfreeze_all_players()
```
- Loops through all players
- Sets is_frozen = false on each

#### get_active_players() -> Array[Player]
Returns non-frozen players.
```gdscript
# Usage
var active = PlayerManager.get_active_players()
```
- Filters players where is_frozen == false

#### get_player_by_id(player_id: String) -> Player
Finds player by their unique ID.
```gdscript
# Usage
var player = PlayerManager.get_player_by_id("player_1")
```
- Returns null if not found

#### get_scoreboard() -> Array[Player]
Returns players sorted by score (highest first).
```gdscript
# Usage
var leaderboard = PlayerManager.get_scoreboard()
```
- Does not modify original array
- Useful for end-game display

#### reset_game() -> void
Resets all players for new game.
```gdscript
# Usage
PlayerManager.reset_game()
```
- Sets all scores to 0
- Unfreezes all players
- Resets turn index to 0

#### clear_all_players() -> void
Removes all players.
```gdscript
# Usage
PlayerManager.clear_all_players()
```
- Clears players array
- Resets turn index

---

## GameManager (Autoload)
**Location**: `scripts/autoload/GameManager.gd`  
**Purpose**: Orchestrates game sessions and manages question pool

### Responsibilities
- Create and manage Game sessions
- Load and distribute questions
- Track used questions
- Check win conditions
- Emit game-level signals

### Key Properties
```gdscript
var game: Game = null                           # Current game session
var available_questions: Array[Question] = []   # All questions
var used_question_ids: Array[String] = []       # Already used
```

### Core Methods

#### start_game(settings: Dictionary) -> void
Initializes a new game session.
```gdscript
# Usage
GameManager.start_game({
    "game_type": "qna",
    "game_target": 1000,
    "player_count": 2
})
```
- Creates new Game instance
- Generates unique game ID
- Loads questions from JSON
- Clears used_question_ids
- Emits game_started signal
- **Note**: Does NOT clear PlayerManager.players (already set up)

#### get_next_question() -> Question
Returns an unused question.
```gdscript
# Usage
var question = GameManager.get_next_question()
if question:
    qna_instance.start_new_question(question)
```
- Filters available_questions by used_question_ids
- Returns random unused question
- Adds question_text to used_question_ids
- Returns null if no unused questions

#### check_for_winner() -> Array[Player]
Checks if any player has reached target score.
```gdscript
# Usage
var winners = GameManager.check_for_winner()
if winners.is_empty():
    # Continue game
else:
    # End game, show winner
```
- Queries PlayerManager.get_active_players()
- Returns players with score >= game.game_target
- Returns empty array if no winner yet

### Typical Session Flow
```gdscript
# 1. Start game
GameManager.start_game(settings)

# 2. Get questions
var q1 = GameManager.get_next_question()
var q2 = GameManager.get_next_question()

# 3. Check for winner after each round
var winners = GameManager.check_for_winner()

# 4. End game when winner found
if not winners.is_empty():
    GameManager.game_ended.emit(winners[0])
```

---

## QuestionLoader (Static Class)
**Location**: `scripts/logic/QuestionLoader.gd`  
**Purpose**: Load and filter questions from JSON

### Methods

#### load_questions_from_file(file_path: String) -> Array[Question]
Loads all questions from JSON file.
```gdscript
# Usage
var questions = QuestionLoader.load_questions_from_file("res://data/questions.json")
```
- Opens and parses JSON
- Creates Question resources
- Returns empty array on error

#### get_random_question(questions: Array[Question]) -> Question
Picks a random question from array.
```gdscript
# Usage
var q = QuestionLoader.get_random_question(questions)
```
- Returns null if array empty

#### filter_by_difficulty(questions: Array[Question], difficulty: String) -> Array[Question]
Filters questions by difficulty.
```gdscript
# Usage
var easy_questions = QuestionLoader.filter_by_difficulty(questions, "easy")
```

#### filter_by_category(questions: Array[Question], category: String) -> Array[Question]
Filters questions by category.
```gdscript
# Usage
var science_questions = QuestionLoader.filter_by_category(questions, "Science")
```

---

## Manager Interaction Rules

### ✅ Allowed
- GameBoard → PlayerManager.get_current_player()
- GameBoard → GameManager.check_for_winner()
- GameManager → PlayerManager.get_active_players()
- QnA → PlayerManager.next_turn()

### ❌ Not Allowed
- PlayerManager → GameManager (managers don't depend on each other)
- Game → PlayerManager (Game is data only)
- QnA → PlayerManager.award_points() (GameBoard handles scoring)
