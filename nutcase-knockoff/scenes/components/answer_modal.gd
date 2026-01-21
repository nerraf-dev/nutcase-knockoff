extends Node2D

@onready var answer_text = $AnswerInput
@onready var submit_button = $Submit
@onready var cancel = $Cancel

signal answer_submitted(answer_text: String)
signal cancelled

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	cancel.pressed.connect(_on_cancel_pressed)
	
	# Enable Enter key in LineEdit to submit
	answer_text.text_submitted.connect(func(_text): _on_submit_pressed())
	
	# Setup focus navigation for controller
	_setup_focus()
	
	# Disable background controls
	_disable_background_focus()
	
	# Start with input focused
	answer_text.grab_focus()

func _setup_focus() -> void:
	# Create focus loop: Cancel <-> Submit
	cancel.focus_neighbor_right = submit_button.get_path()
	submit_button.focus_neighbor_left = cancel.get_path()
	
	# Allow Tab to move from input to buttons
	answer_text.focus_next = cancel.get_path()
	
	# Lock vertical navigation to stay on modal
	cancel.focus_neighbor_top = cancel.get_path()
	cancel.focus_neighbor_bottom = cancel.get_path()
	submit_button.focus_neighbor_top = submit_button.get_path()
	submit_button.focus_neighbor_bottom = submit_button.get_path()

func _disable_background_focus() -> void:
	# Find parent scene and disable its focusable controls
	var parent_scene = get_parent()
	if parent_scene:
		_recursive_disable_focus(parent_scene, self)

func _recursive_disable_focus(node: Node, exclude: Node) -> void:
	if node == exclude:
		return
	
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		node.set_meta("original_focus_mode", node.focus_mode)
		node.focus_mode = Control.FOCUS_NONE
	
	for child in node.get_children():
		_recursive_disable_focus(child, exclude)

func _on_submit_pressed() -> void:
	var answer = answer_text.text.strip_edges()
	if answer != "":
		print("Answer submitted: %s" % answer)
		_restore_background_focus()
		answer_submitted.emit(answer)
		queue_free()
		return
	print("No answer entered; submission ignored.")

func _on_cancel_pressed() -> void:
	print("Answer submission canceled.")
	_restore_background_focus()
	cancelled.emit()
	queue_free()

func _restore_background_focus() -> void:
	# Restore focus to background controls
	var parent_scene = get_parent()
	if parent_scene:
		_recursive_restore_focus(parent_scene)

func _recursive_restore_focus(node: Node) -> void:
	if node is Control and node.has_meta("original_focus_mode"):
		node.focus_mode = node.get_meta("original_focus_mode")
		node.remove_meta("original_focus_mode")
	
	for child in node.get_children():
		_recursive_restore_focus(child)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not answer_text.has_focus():
		# Only trigger on controller A when LineEdit doesn't have focus
		# (prevents conflict with text entry)
		_on_submit_pressed()
		get_viewport().set_input_as_handled()
