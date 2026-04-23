extends RefCounted

class_name GameBoardVoteSession

var board: Node = null
const NETWORK_VOTE_TIMEOUT_SECONDS := 25.0
var _vote_session_active: bool = false
var _vote_session_guesser: Player = null
var _vote_session_correct_answer: String = ""
var _vote_session_eligible_by_device: Dictionary = {} # device_id -> Player
var _vote_session_votes_by_device: Dictionary = {} # device_id -> bool


func _init(p_board: Node = null) -> void:
	board = p_board


func handle_fuzzy_answer(player: Player, prize: int, submitted_answer: String, scoring_breakdown: Dictionary = {}) -> void:
	if board == null:
		return

	# Find eligible voters: active (unfrozen) players who are not the guesser.
	var eligible_voters: Array[Player] = []
	for p in PlayerManager.get_active_players():
		if p != player:
			eligible_voters.append(p)

	# No voters: auto-accept the answer.
	if eligible_voters.is_empty():
		var result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY, submitted_answer, scoring_breakdown)
		await board._handle_correct_result(result)
		return

	# If multiplayer call to broadcast vote request and wait for result.
	# Else local: keep current path.
	if not NetworkManager.is_local:
		var network_voters: Array[Player] = []
		for voter in eligible_voters:
			if voter.device_id != "":
				network_voters.append(voter)
		if network_voters.is_empty():
			# Safety fallback in case no eligible voter has a mapped device.
			var no_device_result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY, submitted_answer, scoring_breakdown)
			await board._handle_correct_result(no_device_result)
			return

		_start_network_vote_session(player, submitted_answer, network_voters)
		var network_vote_result: Dictionary = await board.network_vote_resolved
		await _apply_fuzzy_vote_result(player, prize, submitted_answer, network_vote_result, scoring_breakdown)
	else:
		var vote_modal = VoteModal.new()
		vote_modal.setup(player, submitted_answer, board.round_instance.current_question.answer, eligible_voters)
		board.add_child(vote_modal)
		var vote_result: Dictionary = await vote_modal.vote_resolved
		await _apply_fuzzy_vote_result(player, prize, submitted_answer, vote_result, scoring_breakdown)


func reset_vote_session() -> void:
	_vote_session_active = false
	_vote_session_guesser = null
	_vote_session_correct_answer = ""
	_vote_session_eligible_by_device.clear()
	_vote_session_votes_by_device.clear()


func handle_network_vote_cast(device_id: String, accept: bool) -> void:
	if not _vote_session_active:
		return
	if not _vote_session_eligible_by_device.has(device_id):
		push_warning("Ignoring vote from ineligible device %s" % device_id)
		return
	if _vote_session_votes_by_device.has(device_id):
		push_warning("Ignoring duplicate vote from device %s" % device_id)
		return

	var sender = PlayerManager.get_player_by_device_id(device_id)
	if sender == null:
		print("Received vote from unknown device %s" % device_id)
		return

	_vote_session_votes_by_device[device_id] = accept
	print("Vote received from %s: %s (%d/%d)" % [sender.name, "accept" if accept else "reject", _vote_session_votes_by_device.size(), _vote_session_eligible_by_device.size()])

	if _vote_session_votes_by_device.size() >= _vote_session_eligible_by_device.size():
		_finalize_network_vote_session()


func handle_network_vote_timeout() -> void:
	if not _vote_session_active:
		return
	print("Network vote timed out after %.1f seconds, finalizing with received votes" % NETWORK_VOTE_TIMEOUT_SECONDS)
	_finalize_network_vote_session()


func _start_network_vote_session(guesser: Player, submitted_answer: String, eligible_voters: Array[Player]) -> void:
	reset_vote_session()
	_vote_session_active = true
	_vote_session_guesser = guesser
	_vote_session_correct_answer = ""
	if board.round_instance and board.round_instance.get("current_question") != null:
		_vote_session_correct_answer = str(board.round_instance.current_question.answer)

	for voter in eligible_voters:
		_vote_session_eligible_by_device[voter.device_id] = voter

	if board.has_method("show_vote_preparing_overlay"):
		var guesser_name := guesser.name if guesser != null else ""
		await board.show_vote_preparing_overlay(submitted_answer, guesser_name)

	print("Broadcasting vote request to controllers for fuzzy answer: '%s'" % submitted_answer)
	NetworkManager.broadcast_vote_request(guesser.id, submitted_answer)
	if board.has_method("show_vote_active_overlay"):
		board.show_vote_active_overlay(NETWORK_VOTE_TIMEOUT_SECONDS)

	var timeout = board.get_tree().create_timer(NETWORK_VOTE_TIMEOUT_SECONDS)
	timeout.timeout.connect(handle_network_vote_timeout)


func _finalize_network_vote_session() -> void:
	if not _vote_session_active:
		return

	var yes_voters: Array[Player] = []
	var no_voters: Array[Player] = []
	for device_id in _vote_session_eligible_by_device.keys():
		var voter: Player = _vote_session_eligible_by_device[device_id]
		if _vote_session_votes_by_device.get(device_id, true):
			yes_voters.append(voter)
		else:
			no_voters.append(voter)

	var tied = yes_voters.size() == no_voters.size()
	var accepted = not tied and yes_voters.size() > no_voters.size()
	var vote_result = {
		"accepted": accepted,
		"yes_voters": yes_voters,
		"no_voters": no_voters
	}

	if not NetworkManager.is_local:
		NetworkManager.broadcast_vote_result(accepted, _vote_session_correct_answer)
	if board.has_method("hide_vote_overlay"):
		board.hide_vote_overlay()

	reset_vote_session()
	board.network_vote_resolved.emit(vote_result)


func _apply_fuzzy_vote_result(player: Player, prize: int, submitted_answer: String, vote_result: Dictionary, scoring_breakdown: Dictionary = {}) -> void:
	var accepted: bool = vote_result.get("accepted", false)
	var no_voters: Array[Player] = vote_result.get("no_voters", [])
	if board.has_method("show_vote_result_overlay"):
		await board.show_vote_result_overlay(accepted, no_voters.is_empty())

	if vote_result.get("accepted", false):
		var result = GameManager.handle_correct_answer(player, prize, GameManager.SubmissionResult.FUZZY, submitted_answer, scoring_breakdown)
		await board._handle_correct_result(result)
		return

	# Vote rejected: distribute prize to "no" voters and continue.
	GameManager.handle_vote_rejection(prize, no_voters)
	board._update_all_badges()

	if no_voters.is_empty():
		await board._update_overlay("It's a tie!\nNobody wins the prize.")
	else:
		await board._update_overlay("Rejected!\nThe prize was shared among those who voted no.")
	board._start_next_round()