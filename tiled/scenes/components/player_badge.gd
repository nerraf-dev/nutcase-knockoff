extends Control

"""
player_badge.gd
Role: Full-size player badge UI showing name, score, avatar, and indicators.
Owns: Local UI controls (name, score, avatar texture, leader/current overlays).
Does not own: Player lifecycle or persistence.

Public API:
 - `setup(player: Player)` — initialize visuals from a Player resource.
 - `update_score(new_score: int)` — update the score label.
 - `set_current_player(is_current: bool)` — toggle current-player marker.
 - `set_current_leader(is_leader: bool)` — toggle current-leader marker.

Notes:
 - Avatar texture is selected by `player.avatar_index` from `GameConfig.PLR_BADGE_ICONS`.
 - Keep visuals simple here; animations should be implemented in a separate controller if needed.
"""

@onready var player_name = $Name
@onready var player_score = $Score
@onready var avatar = $Avatar
@onready var icon = $Icon
@onready var current_leader = $Icon/CurrentLeader
@onready var current_player = $Icon/CurrentPlayer


func _ready() -> void:
	# No-op initialization; use `setup()` to configure the badge.
	pass


## Initialize the badge from a `Player` resource.
## Sets the displayed name, score, and avatar image.
func setup(player: Player) -> void:
	update_identity(player.name, player.avatar_index)
	player_score.text = str(player.score)

	# Initially hide current leader/player indicators
	current_player.visible = false
	current_leader.visible = false


## Update the displayed score value.
func update_score(new_score: int) -> void:
	player_score.text = str(new_score)


## Update displayed name and avatar image when a player edits profile.
func update_identity(new_name: String, avatar_index: int) -> void:
	player_name.text = new_name
	if avatar_index >= 0 and avatar_index < GameConfig.PLR_BADGE_ICONS.size():
		var avatar_texture = GameConfig.PLR_BADGE_ICONS[avatar_index]
		avatar.texture = ResourceLoader.load(avatar_texture)


## Toggle the current-player marker visibility.
func set_current_player(is_current: bool) -> void:
	current_player.visible = is_current


## Toggle the current-leader marker visibility.
func set_current_leader(is_leader: bool) -> void:
	current_leader.visible = is_leader

