class_name VoteModal
extends Control

# VoteModal — scenes/components/vote_modal.gd
# Shown when a FUZZY answer is submitted. Eligible voters (active, non-guesser players)
# each press Accept or Reject. Once all votes are in, the correct answer is revealed
# alongside the vote result. The guesser does not vote.
#
# Vote resolution rules:
#   - Majority of no-votes wins → rejected
#   - Tie → nobody wins (prize lost)
#   - Accept win → guesser keeps prize via handle_correct_answer
#   - Reject win → no-voters split half the prize via handle_vote_rejection

signal vote_resolved(result: Dictionary)
# result keys: "accepted" (bool), "yes_voters" (Array[Player]), "no_voters" (Array[Player])

var _guesser: Player
var _submitted_answer: String
var _correct_answer: String
var _eligible_voters: Array[Player]
var _votes: Dictionary = {} # voter.id -> bool (true = accept)
var _vote_result: Dictionary = {}

var _voters_container: VBoxContainer
var _result_container: VBoxContainer
var _continue_btn: Button

func setup(guesser: Player, submitted: String, correct: String, voters: Array[Player]) -> void:
	_guesser = guesser
	_submitted_answer = submitted
	_correct_answer = correct
	_eligible_voters = voters

func _ready() -> void:
	# Fill screen and block input to background
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark overlay
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centre the panel
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# --- Submitted answer ---
	var guesser_lbl = Label.new()
	guesser_lbl.text = "%s guessed:" % _guesser.name
	guesser_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(guesser_lbl)

	var answer_lbl = Label.new()
	answer_lbl.text = '"%s"' % _submitted_answer
	answer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(answer_lbl)

	vbox.add_child(HSeparator.new())

	var instruct = Label.new()
	instruct.text = "Do you accept this answer?"
	instruct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruct)

	# --- Voter rows ---
	_voters_container = VBoxContainer.new()
	_voters_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_voters_container)

	for voter in _eligible_voters:
		_add_voter_row(voter)

	vbox.add_child(HSeparator.new())

	# --- Result area (hidden until all votes are in) ---
	_result_container = VBoxContainer.new()
	_result_container.add_theme_constant_override("separation", 8)
	_result_container.visible = false
	vbox.add_child(_result_container)

	var correct_lbl = Label.new()
	correct_lbl.name = "CorrectAnswerLabel"
	correct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_container.add_child(correct_lbl)

	var result_lbl = Label.new()
	result_lbl.name = "VoteResultLabel"
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 20)
	_result_container.add_child(result_lbl)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

func _add_voter_row(voter: Player) -> void:
	var row = HBoxContainer.new()
	row.name = "VoterRow_" + voter.id
	row.add_theme_constant_override("separation", 8)
	_voters_container.add_child(row)

	var name_lbl = Label.new()
	name_lbl.text = voter.name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var yes_btn = Button.new()
	yes_btn.text = "Accept"
	yes_btn.pressed.connect(func(): UISfx.play_ui_click(); _on_vote(voter, true, row))
	row.add_child(yes_btn)

	var no_btn = Button.new()
	no_btn.text = "Reject"
	no_btn.pressed.connect(func(): UISfx.play_ui_click(); _on_vote(voter, false, row))
	row.add_child(no_btn)

func _on_vote(voter: Player, accept: bool, row: HBoxContainer) -> void:
	if _votes.has(voter.id):
		return # Already voted

	_votes[voter.id] = accept

	# Disable both buttons and show what was voted
	for child in row.get_children():
		if child is Button:
			child.disabled = true
	var voted_lbl = Label.new()
	voted_lbl.text = "✓ Accepted" if accept else "✗ Rejected"
	row.add_child(voted_lbl)

	if _votes.size() == _eligible_voters.size():
		_reveal_result()

func _reveal_result() -> void:
	_voters_container.visible = false

	var yes_voters: Array[Player] = []
	var no_voters: Array[Player] = []
	for voter in _eligible_voters:
		if _votes.get(voter.id, true):
			yes_voters.append(voter)
		else:
			no_voters.append(voter)

	var tied = yes_voters.size() == no_voters.size()
	var accepted = not tied and yes_voters.size() > no_voters.size()

	var correct_lbl = _result_container.get_node("CorrectAnswerLabel")
	correct_lbl.text = "The correct answer was: \"%s\"" % _correct_answer

	var result_lbl = _result_container.get_node("VoteResultLabel")
	if tied:
		result_lbl.text = "It's a tie — nobody wins the prize!"
	elif accepted:
		result_lbl.text = "Accepted! %s wins the prize!" % _guesser.name
	else:
		result_lbl.text = "Rejected! The prize is shared among those who voted no."

	_result_container.visible = true
	_continue_btn.visible = true
	_continue_btn.grab_focus()

	_vote_result = {
		"accepted": accepted,
		"yes_voters": yes_voters,
		"no_voters": no_voters,
	}

func _on_continue_pressed() -> void:
	UISfx.play_ui_click()
	vote_resolved.emit(_vote_result)
	queue_free()
