extends Control

@onready var result_label: Label = $ResultLabel
@onready var next_btn: Button = $NextBtn

var _dismissed: bool = false

func show_message(message: String, auto_dismiss_seconds: float = 5.0) -> void:
	result_label.text = message
	visible = true
	_dismissed = false
	next_btn.grab_focus()
	next_btn.pressed.connect(_on_next_pressed, CONNECT_ONE_SHOT)

	var timer = get_tree().create_timer(max(auto_dismiss_seconds, 0.0))
	while not _dismissed and timer.time_left > 0.0:
		await get_tree().process_frame

	if next_btn.pressed.is_connected(_on_next_pressed):
		next_btn.pressed.disconnect(_on_next_pressed)

	visible = false

func dismiss() -> void:
	_dismissed = true

func is_showing() -> bool:
	return visible

func _on_next_pressed() -> void:
	_dismissed = true
