# Data Structures Reference

## Player Class
**Location**: `scripts/classes/Player.gd`  
**Type**: Resource

### Properties
```gdscript
var id: String              # Unique player ID (e.g., "player_1")
var name: String            # Display name (e.g., "Alice")
var score: int              # Current points
var is_frozen: bool         # Locked out after wrong guess
var device_id: String       # WebSocket connection ID (for multiplayer)
var color: Color            # Visual identifier
```

### Methods
```gdscript
func _init(p_id: String, p_name: String) -> void
    # Constructor - creates player with ID and name
    # Assigns random color automatically

func add_score(points: int) -> void
    # Adds points to player's score
    # Prints update to console

func freeze() -> void
    # Sets is_frozen to true
    # Player cannot act until unfrozen

func unfreeze() -> void
    # Sets is_frozen to false
    # Player can act again

func reset_for_new_round() -> void
    # Unfreezes player for new round
```

---

## Game Class
**Location**: `scripts/classes/Game.gd`  
**Type**: Resource

### Properties
```gdscript
var id: String              # Unique game session ID
var current_round: int      # Current round number (1-indexed)
var game_type: String       # Game mode (e.g., "qna")
var game_target: int        # Target score to win (default: 1000)
var is_active: bool         # Is the game currently running

var round_history: Array    # Array of {round: int, question: Question, result: Dictionary}
var current_question: Resource  # Currently active Question
```

### Methods
```gdscript
func record_round_result(round_num: int, question: Resource, result: Dictionary) -> void
    # Stores result in round_history

func set_current_question(q: Resource) -> void
    # Sets the active question

func reset() -> void
    # Clears all state for new game
    # Resets round counter, history, active status
```

### Notes
- Game does NOT store player data (PlayerManager owns that)
- Game does NOT track frozen/eliminated players (Player objects do)
- Game is purely session metadata and history

---

## Question Class
**Location**: `scripts/resources/Question.gd`  
**Type**: Resource

### Properties
```gdscript
@export var question_text: String   # The question to display
@export var answer: String          # Correct answer
@export var difficulty: String      # "easy", "medium", or "hard"
@export var category: String        # Category (e.g., "Science")
@export var tags: Array[String]     # Tags for filtering
```

### Notes
- Questions are loaded from `data/questions.json`
- Used by QuestionLoader to populate question pool
- No methods - pure data

---

## Settings Dictionary
**Used in**: GameInit → Main → GameManager

### Structure
```gdscript
{
    "game_type": String,        # e.g., "qna"
    "game_target": int,         # e.g., 1000 (winning score)
    "player_count": int,        # Number of players
    "round_count": int          # Total rounds (currently unused)
}
```

### Flow
1. GameInit collects settings from UI
2. Emits `game_init_complete(settings)`
3. Main passes to `GameManager.start_game(settings)`
4. GameManager creates Game with these values

---

## Round Result Dictionary
**Used in**: QnA → GameBoard signal

### Structure
```gdscript
{
    "player": Player,           # Player who answered
    "is_correct": bool,         # Was answer correct?
    "points": int              # Points at stake (prize or penalty base)
}
```

### Usage
Emitted by QnA as signal parameter:
```gdscript
round_result.emit(current_player, is_correct, int(current_prize))
```

Handled by GameBoard:
```gdscript
func _on_round_result(player: Player, is_correct: bool, prize: int)
```

---

## Constants

### Difficulty Multipliers
**Location**: `qna.gd`
```gdscript
const DIFFICULTY_MULTIPLIERS = {
    "easy": 1.0,
    "medium": 1.5,
    "hard": 2.0
}
```

### Base Pot
**Location**: `qna.gd`
```gdscript
const BASE_POT = 100.0              # Starting points for a question
const MINIMUM_POT_PERCENT = 0.1     # 10% always reserved
```

### Game Modes
**Location**: `game_init.gd`
```gdscript
const GAME_MODES = ["qna"]          # Available game types
const GAME_TARGETS = [200, 1000, 2000, 3000]  # Score targets
```

---

## Array Types

### PlayerManager.players
```gdscript
var players: Array[Player] = []
```
- Ordered list of all players in session
- Used for turn order (current_turn_index)

### GameManager.available_questions
```gdscript
var available_questions: Array[Question] = []
```
- All questions loaded from JSON
- Filtered to get unused questions

### GameManager.used_question_ids
```gdscript
var used_question_ids: Array[String] = []
```
- Tracks question_text of used questions
- Prevents repeats in same session
