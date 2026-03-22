extends Control

"""
player_badge_small.gd
Role: Small UI badge that displays player name, score, avatar, and simple indicators.
Owns: Local UI elements (name label, score label, icon image, leader/current flags).
Does not own: Player data lifecycle (PlayerManager/GameManager), nor asset loading policies.

Public API:
 - `setup(player: Player)` — initialize the badge for a Player resource (name, score, random icon).
 - `update_score(new_score: int)` — update displayed score text.
 - `set_current_player(is_current: bool)` — show/hide current-player indicator.
 - `set_current_leader(is_leader: bool)` — show/hide current-leader indicator.

Notes:
 - Icon texture is chosen randomly from `GameConfig.PLR_BADGE_ICONS`; consider injecting a deterministic
   selection if you want stable visuals across runs.
 - Visual styling (e.g., `icon.modulate = player.color`) is intentionally commented out — enable if desired.
 - Keep this script lightweight; complex badge logic (animations, polling) should live elsewhere.
"""

@onready var player_name = $Name
@onready var player_score = $Score
@onready var icon = $Icon
@onready var current_leader = $Icon/CurrentLeader
@onready var current_player = $Icon/CurrentPlayer
@onready var player_img = $Image


func _ready() -> void:
	# No runtime initialization required by default — badge is configured by `setup()`.
	pass


## Initialize the badge UI for the provided `Player` resource.
## - Sets display name and score.
## - Picks a random badge icon from GameConfig.PLR_BADGE_ICONS and loads it.
## - Hides leader/current indicators by default.
func setup(player: Player) -> void:
	player_name.text = player.name
	player_score.text = str(player.score)
	# Choose a random icon path from config and load the texture resource.
	var rnd_img = GameConfig.PLR_BADGE_ICONS.pick_random()
	player_img.texture = ResourceLoader.load(rnd_img)
	# Optional: tint icon to player's color
	# icon.modulate = player.color

	# Initially hide current leader/player indicators
	current_player.visible = false
	current_leader.visible = false


## Update the displayed score (keeps badge UI in sync with model).
func update_score(new_score: int) -> void:
	player_score.text = str(new_score)


## Toggle the 'current player' indicator on the badge.
func set_current_player(is_current: bool) -> void:
	current_player.visible = is_current


## Toggle the 'current leader' indicator on the badge.
func set_current_leader(is_leader: bool) -> void:
	current_leader.visible = is_leader
