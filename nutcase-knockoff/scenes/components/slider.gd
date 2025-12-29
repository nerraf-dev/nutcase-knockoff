extends PanelContainer

signal clicked

@onready var cover = $Cover
@onready var word_label = $WordLabel
@onready var number_label = $Cover/NumberLabel
var is_revealed = false
var word_number = 0

func _gui_input(event: InputEvent):
    # Mouse click
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not is_revealed:
            clicked.emit()
            reveal()
            
    # Touch input (mobile)
    elif event is InputEventScreenTouch and event.pressed:
        if not is_revealed:
            clicked.emit()
            reveal()
    
    # Keyboard/Controller (when this slider has focus)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
        if not is_revealed:
            clicked.emit()
            reveal()
    elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
        if not is_revealed:
            clicked.emit()
            reveal()

func set_word(text: String, number: int = 0):
    word_label.text = text
    word_number = number
    if number_label:
        number_label.text = str(number)

func reveal():
    is_revealed = true
    var tween = create_tween()
    #  slide to the right
    tween.tween_property(cover, "position:x", size.x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    # fade out
    tween.parallel().tween_property(cover, "modulate:a", 0, 0.3)

    