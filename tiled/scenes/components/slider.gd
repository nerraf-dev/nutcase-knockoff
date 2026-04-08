extends PanelContainer

signal clicked(word: String, is_blank: bool)

const BASE_WORD_FONT_SIZE := 72
const LONG_WORD_FONT_SIZE := 60
const LONGER_WORD_FONT_SIZE := 50
const MAX_LENGTH_FOR_BASE_FONT := 10
const MAX_LENGTH_FOR_LONG_FONT := 14

var slider_covers = [
	'res://assets/images/sliders/slider_blue_1.svg',
	'res://assets/images/sliders/slider_blue_2.svg',
	'res://assets/images/sliders/slider_blue_3.svg',
] # To keep track of covers for all sliders, if needed for future enhancements

@onready var cover = $Cover
@onready var word_label = $Margin/WordLabel
@onready var number_label = $Cover/NumberLabel
var is_revealed = false
var word_number = 0

# Store original style for focus/unfocus
var original_modulate: Color

func _ready() -> void:
	# Enable focus for controller navigation
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	original_modulate = modulate
	word_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	word_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	word_label.clip_text = true
	
	# Connect focus signals for visual feedback
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	cover.visible = true

func _on_focus_entered() -> void:
	# Bright yellow border/highlight when focused
	# modulate = Color(1.5, 1.5, 0.5)
	modulate = original_modulate
	print("Slider %d focused" % word_number)

func _on_focus_exited() -> void:
	# Return to normal appearance
	modulate = original_modulate

func _gui_input(event: InputEvent):
	# Mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_revealed:
			var word = word_label.text.strip_edges()
			var is_blank = word == ""
			clicked.emit(word, is_blank)
			# reveal() is called by qna._handle_slider_reveal, not here
			
	# Touch input (mobile)
	elif event is InputEventScreenTouch and event.pressed:
		if not is_revealed:
			var word = word_label.text.strip_edges()
			var is_blank = word == ""
			clicked.emit(word, is_blank)
			# reveal() is called by qna._handle_slider_reveal, not here

func _input(event: InputEvent):
	# Only process if this slider has focus
	if not has_focus():
		return
	
	# Controller A button or Space key
	if event.is_action_pressed("ui_accept"):
		if not is_revealed:
			var word = word_label.text.strip_edges()
			var is_blank = word == ""
			print("Slider %d revealed via controller - Word: '%s', Blank: %s" % [word_number, word, is_blank])
			clicked.emit(word, is_blank)
			# reveal() is called by qna._handle_slider_reveal, not here
			get_viewport().set_input_as_handled()
	
	# Debug: show focus movement
	elif event.is_action_pressed("ui_up"):
		print("Moving UP from slider %d" % word_number)
	elif event.is_action_pressed("ui_down"):
		print("Moving DOWN from slider %d" % word_number)
	elif event.is_action_pressed("ui_left"):
		print("Moving LEFT from slider %d" % word_number)
	elif event.is_action_pressed("ui_right"):
		print("Moving RIGHT from slider %d" % word_number)

func set_word(text: String, number: int = 0):
	word_label.text = text
	word_number = number
	_apply_word_font_size(text)
	# Always show the number on the cover
	if number_label:
		number_label.text = str(number)

func _apply_word_font_size(text: String) -> void:
	var font_size = BASE_WORD_FONT_SIZE
	var text_length = text.strip_edges().length()
	if text_length > MAX_LENGTH_FOR_LONG_FONT:
		font_size = LONGER_WORD_FONT_SIZE
	elif text_length > MAX_LENGTH_FOR_BASE_FONT:
		font_size = LONG_WORD_FONT_SIZE

	var settings: LabelSettings = word_label.label_settings.duplicate() if word_label.label_settings else LabelSettings.new()
	settings.font_size = font_size
	word_label.label_settings = settings
	
func reveal():
	is_revealed = true
	var tween = create_tween()
	#  slide to the right
	tween.tween_property(cover, "position:x", size.x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# fade out
	tween.parallel().tween_property(cover, "modulate:a", 0, 0.3)


func _set_random_cover() -> void:
	var random_cover = slider_covers[randi() % slider_covers.size()]
	cover.texture = load(random_cover)
	