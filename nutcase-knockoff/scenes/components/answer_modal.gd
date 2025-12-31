extends Node2D

@onready var answer_text = $AnswerInput
@onready var submit_button = $Submit
@onready var cancel = $Cancel

signal answer_submitted(answer_text: String)
signal cancelled

func _ready() -> void:
    submit_button.pressed.connect(_on_submit_pressed)
    cancel.pressed.connect(_on_cancel_pressed)

func _on_submit_pressed() -> void:
    var answer = answer_text.text.strip_edges()
    if answer != "":
        print("Answer submitted: %s" % answer)
        answer_submitted.emit(answer)

func _on_cancel_pressed() -> void:
    print("Answer submission canceled.")
    cancelled.emit()
    queue_free()

func _input(event):
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _on_cancel_pressed()
