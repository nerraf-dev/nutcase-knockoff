extends Control

@onready var title_label: Label = $Title
@onready var body_label: Label = $Body
@onready var countdown_label: Label = $Countdown
@onready var next_btn: Button = $NextBtn

var _dismissed: bool = false
var _countdown_token: int = 0


func _ready() -> void:
	visible = false
	next_btn.visible = false
	countdown_label.visible = false


func show_message(title: String, body: String, auto_dismiss_seconds: float = 0.0, show_next_button: bool = false) -> void:
	_set_copy(title, body)
	visible = true
	_dismissed = false

	countdown_label.visible = false
	next_btn.visible = show_next_button
	if show_next_button:
		next_btn.grab_focus()
		next_btn.pressed.connect(_on_next_pressed, CONNECT_ONE_SHOT)

	if auto_dismiss_seconds > 0.0:
		var timer = get_tree().create_timer(auto_dismiss_seconds)
		while not _dismissed and timer.time_left > 0.0:
			await get_tree().process_frame
	elif not show_next_button:
		# If no auto-dismiss and no button, default to one frame visibility.
		await get_tree().process_frame

	_cleanup_button_signal()
	visible = false


func show_countdown(title: String, body: String, seconds: float) -> void:
	_countdown_token += 1
	var token := _countdown_token

	_set_copy(title, body)
	visible = true
	_dismissed = false
	next_btn.visible = false
	countdown_label.visible = true

	var total: float = max(seconds, 0.0)
	var timer = get_tree().create_timer(total)
	while visible and not _dismissed and timer.time_left > 0.0 and token == _countdown_token:
		countdown_label.text = "%ds" % int(ceil(timer.time_left))
		await get_tree().process_frame

	if token == _countdown_token and not _dismissed:
		countdown_label.text = "0s"


func dismiss() -> void:
	_dismissed = true
	visible = false
	countdown_label.visible = false
	next_btn.visible = false
	_cleanup_button_signal()


func is_showing() -> bool:
	return visible


func _set_copy(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body


func _cleanup_button_signal() -> void:
	if next_btn.pressed.is_connected(_on_next_pressed):
		next_btn.pressed.disconnect(_on_next_pressed)


func _on_next_pressed() -> void:
	_dismissed = true
