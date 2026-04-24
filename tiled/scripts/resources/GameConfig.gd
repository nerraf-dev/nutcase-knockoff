extends Node

const WEBSOCKET_PORT: int = 9080
const CONTROLLER_HTTP_PORT: int = 8000

# Scoring
const BASE_POT: float = 100.0
const MINIMUM_POT_PERCENT: float = 0.1
const PENALTY_MULTIPLIER: float = 0.5

# Difficulty multipliers
const DIFFICULTY_MULTIPLIERS: Dictionary = {
    "easy": 1.0,
    "medium": 1.5,
    "hard": 2.0
}

# Player limits
const MIN_PLAYERS: int = 2
const MAX_PLAYERS: int = 6

# Game modes
const GAME_MODES: Array[String] = ["qna"]
const GAME_TARGETS: Array[int] = [200, 350, 500]

# Game Options
const FUZZY_ENABLED_DEFAULT: bool = true
const FUZZY_MIN_LENGTH: int = 5 # Only apply fuzzy matching to answers of this length or more
const MESSAGE_STYLE_DEFAULT: String = "default" # Supported: default, funny, serious

# Timing
const SPLASH_DURATION: float = 2.0
const RESULT_DISPLAY_DURATION: float = 2.0

const PLR_BADGE_ICONS: Array[String] = [
    "res://assets/images/player_badges/mine/duck.png",
    "res://assets/images/player_badges/mine/mr_box.png",
    "res://assets/images/player_badges/mine/purps.png",
    "res://assets/images/player_badges/mine/square-head-zombie.png",
    "res://assets/images/player_badges/mine/flower_c.png"
]