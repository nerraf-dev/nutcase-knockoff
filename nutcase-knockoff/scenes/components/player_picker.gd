extends Control

@onready var name_label = $NameLabel

var player_name: String = ""

func set_player_name(p_name: String) -> void:
	player_name = p_name
	$NameLabel.text = p_name  # Assuming you have a label named NameLabel
