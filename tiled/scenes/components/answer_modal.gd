extends Control

# AnswerModal — scenes/components/answer_modal.gd
# Role: Modal dialog for player answer submission and simple focus-managed input.
# Owns: Local input UI (LineEdit), submit/cancel buttons, and transient focus management.
# Does not own: Game rules/state (GameManager), player storage (PlayerManager), or networking (NetworkManager).
#
# Public API (signals):
# - `answer_submitted(answer_text: String)` — emitted when the user confirms a non-empty answer.
# - `cancelled()` — emitted when the user cancels the modal.
#
# Focus behavior (summary):
# - On open: modal grabs focus, sets a tight focus loop between Cancel <-> Submit,
#   disables background controls' focus to avoid accidental navigation, and gives text input focus.
# - On close (submit/cancel): restores the previous focus modes, emits the relevant signal, and frees the modal.
#
# Implementation notes and edge cases:
# - `_disable_background_focus()` walks the parent scene and temporarily stores each Control's `focus_mode`.
# - `_restore_background_focus()` restores those modes; stored entries are cleared after restoration.
# - This modal intentionally does not make assumptions about the surrounding scene's node structure; it
#   operates by walking the node tree and excluding itself from modifications.
# - Keyboard/gamepad: `ui_accept` and `ui_cancel` are handled; `ui_accept` only triggers submit when the
#   text input does not have focus to avoid interrupting typing.
#
# Example usage:
#   var modal = preload("res://scenes/components/answer_modal.tscn").instantiate()
#   modal.connect("answer_submitted", self, "_on_answer")
#   add_child(modal)

@onready var answer_text = $AnswerInput
@onready var submit_button = $Submit
@onready var cancel = $Cancel

signal answer_submitted(answer_text: String)
signal cancelled

var _stored_focus_modes: Dictionary = {} # node path -> previous focus mode

func _ready() -> void:
	# Hook up UI events. Use explicit connections so external scenes can still re-bind if desired.
	submit_button.pressed.connect(_on_submit_pressed)
	cancel.pressed.connect(_on_cancel_pressed)
	# When the user presses Enter in the LineEdit, treat it as submit.
	answer_text.text_submitted.connect(func(_text): _on_submit_pressed())

	# Configure and apply focus isolation for modal UX.
	_setup_focus()
	_disable_background_focus()
	answer_text.grab_focus()

# Focus management functions to create a seamless modal experience for keyboard/gamepad users.
# We set up a focus loop between the Cancel and Submit buttons, and disable focus on all other controls in the parent scene to prevent accidental navigation. When the modal is closed, we restore the original focus
# modes to re-enable background navigation. This ensures a smooth experience for both keyboard and gamepad users.
## Sets up a tight focus loop between the modal controls.
## Ensures Tab/arrow navigation stays within the modal and that input -> buttons flow is natural.
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

## Walks the parent scene and disables `focus_mode` for all Controls except this modal.
## Previous focus modes are stored in `_stored_focus_modes` so they can be restored later.
func _disable_background_focus() -> void:
	# Find parent scene and disable its focusable controls
	var parent_scene = get_parent()
	if parent_scene:
		_recursive_disable_focus(parent_scene, self )

## Recursively disables focus on Controls, skipping `exclude` node.
## Uses node.get_path() as a stable key for storing/restoring focus mode.
func _recursive_disable_focus(node: Node, exclude: Node) -> void:
	if node == exclude:
		return
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		_stored_focus_modes[node.get_path()] = node.focus_mode
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_recursive_disable_focus(child, exclude)

## Called when the user confirms their input (Submit button or LineEdit Enter).
## Emits `answer_submitted` only for non-empty trimmed input, restores focus, then frees modal.
func _on_submit_pressed() -> void:
	_play_ui_click_safe()
	var answer = answer_text.text.strip_edges()
	if answer != "":
		print("Answer submitted: %s" % answer)
		_restore_background_focus()
		answer_submitted.emit(answer)
		queue_free()
		return
	print("No answer entered; submission ignored.")

## Called when the user cancels the modal. Restores focus, emits `cancelled`, and frees the modal.
func _on_cancel_pressed() -> void:
	_play_ui_click_safe()
	print("Answer submission canceled.")
	_restore_background_focus()
	cancelled.emit()
	queue_free()

func _play_ui_click_safe() -> void:
	# Keep answer submission functional even if UI SFX singleton is missing.
	var ui_sfx := get_node_or_null("/root/UISfx")
	if ui_sfx and ui_sfx.has_method("play_ui_click"):
		ui_sfx.call("play_ui_click")

## Restores previously stored focus modes on background controls.
## Safe to call multiple times; entries are removed from storage as they're restored.
func _restore_background_focus() -> void:
	# Restore focus to background controls
	var parent_scene = get_parent()
	if parent_scene:
		_recursive_restore_focus(parent_scene)

## Reverse of `_recursive_disable_focus` — restores focus_mode from `_stored_focus_modes` when present.
func _recursive_restore_focus(node: Node) -> void:
	if node is Control:
		var key = node.get_path()
		if _stored_focus_modes.has(key):
			node.focus_mode = _stored_focus_modes[key]
			_stored_focus_modes.erase(key)
	for child in node.get_children():
		_recursive_restore_focus(child)

## Input routing for modal-level actions. Respect LineEdit focus to avoid intercepting typed characters.
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not answer_text.has_focus():
		# Only trigger on controller A when LineEdit doesn't have focus
		# (prevents conflict with text entry)
		_on_submit_pressed()
		get_viewport().set_input_as_handled()
