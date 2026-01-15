extends Resource

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
const MAX_PLAYERS: int = 8

# Game modes
const GAME_MODES: Array[String] = ["qna"]
const GAME_TARGETS: Array[int] = [200, 1000, 2000, 3000]

# Timing
const SPLASH_DURATION: float = 2.0
const RESULT_DISPLAY_DURATION: float = 2.0