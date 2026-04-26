extends Control

signal play_again_requested
signal return_to_home

const SCORE_LABEL_FONT_SIZE = 32
const MEDAL_ICON_SIZE := Vector2(32, 32)
const MEDAL_GOLD := preload("res://assets/images/components/medal-gold.png")
const MEDAL_SILVER := preload("res://assets/images/components/medal-silver.png")
const MEDAL_BRONZE := preload("res://assets/images/components/medal-bronze.png")

@onready var title = $Content/Title
@onready var winner_label = $Content/WinnerLabel
@onready var scores_container = $Content/Scores
@onready var play_again_btn = $Content/Buttons/PlayAgainBtn
@onready var home_btn = $Content/Buttons/HomeBtn

var game_settings: Dictionary = {}

func _ready() -> void:
	print("Game End scene ready")
	play_again_btn.pressed.connect(_on_play_again_pressed)
	home_btn.pressed.connect(_on_home_pressed)

	play_again_btn.focus_mode = Control.FOCUS_ALL
	home_btn.focus_mode = Control.FOCUS_ALL
	play_again_btn.grab_focus()

	play_again_btn.focus_neighbor_right = home_btn.get_path()
	home_btn.focus_neighbor_left = play_again_btn.get_path()


# Called from main.gd when loading this scene
func setup(winning_player: Player, players: Array[Player], settings: Dictionary) -> void:
	game_settings = settings
	
	# Update winner display
	winner_label.text = "%s Wins!" % winning_player.name
	
	# Build and display scoreboard
	_populate_scoreboard(players)

func _populate_scoreboard(players: Array[Player]) -> void:
	# Clear any existing children
	for child in scores_container.get_children():
		child.queue_free()
	
	# Sort players by score (highest first)
	var sorted_players = players.duplicate()
	sorted_players.sort_custom(func(a, b): return a.score > b.score)
	
	# Add each player's score row with medal icon + text
	for i in range(sorted_players.size()):
		var player = sorted_players[i]
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var medal_icon = TextureRect.new()
		medal_icon.custom_minimum_size = MEDAL_ICON_SIZE
		medal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal_icon.texture = _get_medal_texture_for_rank(i)

		var label = Label.new()
		label.text = "%s: %d points" % [player.name, player.score]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", SCORE_LABEL_FONT_SIZE)

		row.add_child(medal_icon)
		row.add_child(label)
		scores_container.add_child(row)


func _get_medal_texture_for_rank(rank_index: int) -> Texture2D:
	if rank_index == 0:
		return MEDAL_GOLD
	if rank_index == 1:
		return MEDAL_SILVER
	if rank_index == 2:
		return MEDAL_BRONZE
	return null

func _on_play_again_pressed() -> void:
	print("Play again requested with settings: %s" % game_settings)
	play_again_requested.emit()

func _on_home_pressed() -> void:
	print("Returning to home menu")
	return_to_home.emit()