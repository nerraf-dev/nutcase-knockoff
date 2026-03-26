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
const MAX_PLAYERS: int = 8

# Game modes
const GAME_MODES: Array[String] = ["qna"]
const GAME_TARGETS: Array[int] = [200, 1000, 2000, 3000]

# Game Options
const FUZZY_ENABLED_DEFAULT: bool = true
const FUZZY_MIN_LENGTH: int = 5 # Only apply fuzzy matching to answers of this length or more

# Timing
const SPLASH_DURATION: float = 2.0
const RESULT_DISPLAY_DURATION: float = 2.0

const PLR_BADGE_ICONS: Array[String] = [
    "res://assets/images/player_badges/mine/duck.png",
    "res://assets/images/player_badges/mine/mr-box.png",
    "res://assets/images/player_badges/mine/purps.png",
    "res://assets/images/player_badges/mine/square-head-zombie.png",
    "res://assets/images/player_badges/mine/flower.png",
    "res://assets/images/player_badges/mine/flower_c.png"
    # "res://assets/images/player_badges/person_1.svg",
    # "res://assets/images/player_badges/person_2.svg",
    # "res://assets/images/player_badges/person_3.svg",
    # "res://assets/images/player_badges/person_4.svg",
    # "res://assets/images/player_badges/robot.svg",
    # "res://assets/images/player_badges/zombie.svg",
    # "res://assets/images/player_badges/animals/bear.svg",
    # "res://assets/images/player_badges/animals/buffalo.svg",
    # "res://assets/images/player_badges/animals/chick.svg",
    # "res://assets/images/player_badges/animals/chicken.svg",
    # "res://assets/images/player_badges/animals/elephant.svg",
    # "res://assets/images/player_badges/animals/frog.svg",
    # "res://assets/images/player_badges/animals/giraffe.svg",
    # "res://assets/images/player_badges/animals/hippo.svg",
    # "res://assets/images/player_badges/animals/horse.svg",
    # "res://assets/images/player_badges/animals/monkey.svg",
    # "res://assets/images/player_badges/animals/moose.svg",
    # "res://assets/images/player_badges/animals/nawhal.svg",
    # "res://assets/images/player_badges/animals/panda.svg",
    # "res://assets/images/player_badges/animals/parrot.svg",
    # "res://assets/images/player_badges/animals/penguin.svg",
    # "res://assets/images/player_badges/animals/pig.svg",
    # "res://assets/images/player_badges/animals/rabbit.svg",
    # "res://assets/images/player_badges/animals/snake.svg",
    # "res://assets/images/player_badges/animals/walrus.svg",
    # "res://assets/images/player_badges/animals/whale.svg"
]