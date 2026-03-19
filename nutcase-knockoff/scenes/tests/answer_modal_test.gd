extends Node

# answer_modal_test.gd
# Small test script to programmatically instantiate `answer_modal.tscn`,
# simulate a submit and a cancel, and log emitted signals.
# Usage: create a simple test scene with a Node, attach this script, and run from Godot.

var modal_scene = preload("res://scenes/components/answer_modal.tscn")

func _ready() -> void:
	print("AnswerModal test starting")

	# Instantiate modal
	var modal = modal_scene.instantiate()
	add_child(modal)

	# Connect signals
	modal.connect("answer_submitted", Callable(self, "_on_answer_submitted"))
	modal.connect("cancelled", Callable(self, "_on_cancelled"))

	# Test 1: simulate submit with non-empty text
	print("-- Test: submit non-empty answer --")
	modal.answer_text.text = "Test Answer"
	# Call the public submit handler (works even if underscore-prefixed)
	if modal.has_method("_on_submit_pressed"):
		modal.call("_on_submit_pressed")
	else:
		print("Modal missing _on_submit_pressed method")

	# Wait a bit then re-open modal for cancel test
	await get_tree().create_timer(0.2).timeout

	# Re-instantiate for cancel test
	var modal2 = modal_scene.instantiate()
	add_child(modal2)
	modal2.connect("answer_submitted", Callable(self, "_on_answer_submitted"))
	modal2.connect("cancelled", Callable(self, "_on_cancelled"))

	print("-- Test: cancel --")
	if modal2.has_method("_on_cancel_pressed"):
		modal2.call("_on_cancel_pressed")
	else:
		print("Modal missing _on_cancel_pressed method")

	print("AnswerModal test finished")

func _on_answer_submitted(text: String) -> void:
	print("Signal: answer_submitted -> %s" % text)

func _on_cancelled() -> void:
	print("Signal: cancelled")
