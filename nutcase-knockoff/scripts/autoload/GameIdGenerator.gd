extends Node

var _adjectives: Array = []
var _nouns: Array = []
var is_ready: bool = false

func _ready() -> void:
	_load_words()

func _load_words() -> void:
	var file_path = "res://data/words/words.json"
	if not FileAccess.file_exists(file_path):
		printerr("ID Generator: words.json not found!")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error == OK:
		_adjectives = json.data["adjectives"]
		_nouns = json.data["nouns"]
		is_ready = true
	else:
		printerr("ID Generator: JSON Error on line ", json.get_error_line())

func get_random_id() -> String:
	if not is_ready:
		return "Connecting..."
		
	var adj1 = _adjectives.pick_random()
	var adj2 = _adjectives.pick_random()
	var noun = _nouns.pick_random()
	
	# Keep picking adj2 until it's different from adj1
	while adj2 == adj1:
		adj2 = _adjectives.pick_random()
		
	return "%s%s%s" % [adj1, adj2, noun]