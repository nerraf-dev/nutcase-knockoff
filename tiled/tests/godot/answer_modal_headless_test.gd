extends SceneTree

# Headless test runner for AnswerModal
# Run with: `godot --headless -s res://tests/godot/answer_modal_headless_test.gd`
# It will instantiate the modal scene, simulate submit + cancel, print outputs, and quit.

var modal_scene = preload("res://scenes/components/answer_modal.tscn")

func _ready() -> void:
	# Kept for compatibility if attached to a scene in editor.
	pass

func _initialize() -> void:
	print("Headless AnswerModal test starting")
	# Run tests asynchronously so timers/frames can process
	await _task_run()

func _task_run() -> void:
	# Test 1: submit a non-empty answer
	var modal = modal_scene.instantiate()
	root.add_child(modal)
	modal.connect("answer_submitted", Callable(self , "_on_answer_submitted"))
	modal.connect("cancelled", Callable(self , "_on_cancelled"))
	# Let the engine process one frame so nodes initialize
	await create_timer(0.05).timeout
	var answer_input = modal.get_node_or_null("AnswerInput")
	if answer_input == null:
		print("Modal missing AnswerInput node")
		quit(1)
		return
	answer_input.text = "Headless Test Answer"
	if modal.has_method("_on_submit_pressed"):
		modal.call("_on_submit_pressed")
	else:
		print("Modal missing _on_submit_pressed")

	# Wait briefly then run cancel test
	await create_timer(0.05).timeout
	var modal2 = modal_scene.instantiate()
	root.add_child(modal2)
	modal2.connect("answer_submitted", Callable(self , "_on_answer_submitted"))
	modal2.connect("cancelled", Callable(self , "_on_cancelled"))
	await create_timer(0.05).timeout
	if modal2.has_method("_on_cancel_pressed"):
		modal2.call("_on_cancel_pressed")
	else:
		print("Modal missing _on_cancel_pressed")

	# Final wait to ensure signals printed
	await create_timer(0.05).timeout
	print("Headless AnswerModal test finished")
	quit()

func _on_answer_submitted(text: String) -> void:
	print("Signal (headless): answer_submitted -> %s" % text)

func _on_cancelled() -> void:
	print("Signal (headless): cancelled")
