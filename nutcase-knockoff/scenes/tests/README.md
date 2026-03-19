AnswerModal test

This folder contains a small Godot test helper to exercise the AnswerModal UI.

How to run:
1. Open the project in Godot.
2. Create a new scene with a single `Node` root.
3. Attach the script `res://scenes/tests/answer_modal_test.gd` to the root node.
4. Run the scene. The script will instantiate the modal, simulate a submit and a cancel,
   and print the emitted signals to the Output.

Notes:
- The test calls modal methods directly (e.g. `_on_submit_pressed`) for simplicity.
  This mirrors a user action but does not simulate low-level input events.
- If you prefer a visual test, you can add the test node to the main scene instead.
