extends Control

@onready var player_name = $Name
@onready var player_score = $Score
@onready var icon = $Icon
@onready var current_leaader = $Icon/CurrentLeader
@onready var current_player = $Icon/CurrentPlayer


func _ready() -> void:
    pass  # Initialization if needed

# setup badge with player name an init score (0). 
# Current player should be player 1 on first load
func setup(player: Player) -> void:
    player_name.text = player.name
    player_score.text = str(player.score)
    # icon.modulate = player.color
    
    # Initially hide current leader/player indicators
    current_player.visible = false
    current_leaader.visible = false

func update_score(new_score: int) -> void:
    player_score.text = str(new_score)

func set_current_player(is_current: bool) -> void:
    current_player.visible = is_current

func set_current_leader(is_leader: bool) -> void:
    current_leaader.visible = is_leader

