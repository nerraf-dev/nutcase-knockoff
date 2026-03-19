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


Multiplayer vote test matrix

Priority cases to validate host-authoritative fuzzy voting:

1. Eligible voters only
- Setup: 3 players, P1 is guesser, P2 and P3 active.
- Action: P2 votes, P3 votes, any non-eligible/unknown device votes.
- Expect: only P2/P3 counted; invalid vote ignored.

2. Duplicate vote ignored
- Setup: active vote session with P2 eligible.
- Action: P2 sends accept twice.
- Expect: first vote recorded; second ignored.

3. Guesser cannot vote
- Setup: P1 guessed fuzzy answer.
- Action: P1 sends vote packet.
- Expect: ignored as ineligible.

4. Timeout finalization
- Setup: 3 eligible voters.
- Action: only 1 or 2 submit before timeout.
- Expect: session finalizes after timeout without hanging round flow.

5. Tie handling
- Setup: 2 eligible voters.
- Action: one accept, one reject.
- Expect: tie -> rejected branch message with no payout.

6. Reject payout split
- Setup: reject majority with 2+ no-voters.
- Action: finalize vote.
- Expect: half prize split among no-voters exactly once.

7. Session reset on transitions
- Setup: vote in progress.
- Action: start next round or exit to home.
- Expect: vote session cleared; no stale votes carry over.

Quick manual run checklist

1. Start multiplayer game with 2+ controller clients.
2. Trigger fuzzy answer from current player.
3. Confirm non-guesser clients receive vote prompt and can send vote.
4. Confirm host resolves accepted/rejected and advances round.
5. Repeat with tie and timeout scenarios.

Headless scaffold

- Script: `res://scenes/tests/vote_multiplayer_headless_scaffold.gd`
- Run: `godot --headless -s res://scenes/tests/vote_multiplayer_headless_scaffold.gd`
- Purpose: tracks planned cases and gives a structured place to add assertions incrementally.

Windows shortcut runner

- From repo root you can run:
  - `./run-godot-headless.ps1`
- To run a specific test script:
  - `./run-godot-headless.ps1 -TestScript res://scenes/tests/answer_modal_headless_test.gd`
- If `godot` is not on PATH, set once per shell:
  - `$env:GODOT_EXE = "C:\path\to\Godot.exe"`

Smoke suite runner

- Run both headless tests from repo root:
  - `./run-godot-smoke.ps1`
- Optional explicit executable override:
  - `./run-godot-smoke.ps1 -GodotExe "D:/Godot/Editors/4.6.1-stable/Godot_v4.6.1-stable_win64_console.exe"`
