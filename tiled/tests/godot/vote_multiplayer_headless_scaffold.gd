extends SceneTree

# Headless scaffold for multiplayer vote-flow coverage.
# Run with:
#   godot --headless -s res://scenes/tests/vote_multiplayer_headless_scaffold.gd
#
# This is intentionally lightweight: it provides a stable harness and case list
# while vote tests are implemented incrementally.

class VoteSessionHarness:
	extends RefCounted

	signal network_vote_resolved(result: Dictionary)

	var _vote_session_active: bool = false
	var _vote_session_eligible_by_device: Dictionary = {}
	var _vote_session_votes_by_device: Dictionary = {}
	var _finalized_count: int = 0
	var _last_vote_result: Dictionary = {}
	var _last_vote_request: Dictionary = {}

	func _reset_vote_session() -> void:
		_vote_session_active = false
		_vote_session_eligible_by_device.clear()
		_vote_session_votes_by_device.clear()

	func _finalize_network_vote_session() -> void:
		if not _vote_session_active:
			return

		var yes_voters: Array = []
		var no_voters: Array = []
		for device_id in _vote_session_eligible_by_device.keys():
			var voter = _vote_session_eligible_by_device[device_id]
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
		_finalized_count += 1
		_last_vote_result = vote_result

		_reset_vote_session()
		network_vote_resolved.emit(vote_result)

	func _on_network_vote_cast(device_id: String, accept: bool) -> void:
		if not _vote_session_active:
			return
		if not _vote_session_eligible_by_device.has(device_id):
			return
		if _vote_session_votes_by_device.has(device_id):
			return

		_vote_session_votes_by_device[device_id] = accept
		if _vote_session_votes_by_device.size() >= _vote_session_eligible_by_device.size():
			_finalize_network_vote_session()

	func _on_network_vote_timeout() -> void:
		_finalize_network_vote_session()

	func start_network_vote_session(guesser: Dictionary, submitted_answer: String, eligible_by_device: Dictionary) -> void:
		_reset_vote_session()
		_vote_session_active = true
		for device_id in eligible_by_device.keys():
			_vote_session_eligible_by_device[device_id] = eligible_by_device[device_id]
		_last_vote_request = {
			"guesser_id": guesser.get("id", ""),
			"answer": submitted_answer
		}

	func calculate_reject_payout(prize: int, no_voters: Array) -> Dictionary:
		if no_voters.is_empty():
			return {"each_share": 0, "awards": {}}

		var each_share = int((prize / 2.0) / no_voters.size())
		var awards: Dictionary = {}
		for voter in no_voters:
			awards[voter["id"]] = each_share
		return {"each_share": each_share, "awards": awards}

const CASES = [
	"fuzzy_vote_session_trigger",
	"eligible_voters_only",
	"duplicate_vote_ignored",
	"guesser_cannot_vote",
	"timeout_finalization",
	"tie_handling",
	"reject_payout_split",
	"session_reset_on_transition"
]

var _passed := 0
var _failed := 0

func _ready() -> void:
	# Kept for compatibility if this script is ever attached to a scene.
	pass

func _initialize() -> void:
	print("Vote multiplayer headless scaffold starting")
	_run()
	print("Vote multiplayer scaffold finished: %d passed, %d failed" % [_passed, _failed])
	quit(_failed)

func _run() -> void:
	for case_name in CASES:
		var ok = _run_case(case_name)
		if ok:
			_passed += 1
			print("[PASS] %s" % case_name)
		else:
			_failed += 1
			print("[FAIL] %s" % case_name)

func _run_case(case_name: String) -> bool:
	match case_name:
		"fuzzy_vote_session_trigger":
			return _test_fuzzy_vote_session_trigger()
		"eligible_voters_only":
			return _test_eligible_voters_only()
		"duplicate_vote_ignored":
			return _test_duplicate_vote_ignored()
		"guesser_cannot_vote":
			return _test_guesser_cannot_vote()
		"timeout_finalization":
			return _test_timeout_finalization()
		"tie_handling":
			return _test_tie_handling()
		"reject_payout_split":
			return _test_reject_payout_split()
		"session_reset_on_transition":
			return _test_session_reset_on_transition()
		_:
			push_warning("Unknown case '%s'" % case_name)
			return false

func _todo_case(case_name: String) -> bool:
	print("TODO: implement %s" % case_name)
	# Keep scaffold green while you replace TODOs with real assertions.
	return true

func _test_fuzzy_vote_session_trigger() -> bool:
	var guesser = {"id": "player_1", "name": "Guesser"}
	var voter_a = {"id": "player_2", "name": "A"}
	var voter_b = {"id": "player_3", "name": "B"}
	var board = VoteSessionHarness.new()
	var eligible = {
		"dev-a": voter_a,
		"dev-b": voter_b
	}

	# Simulates the production start call that should happen on FUZZY answer.
	board.start_network_vote_session(guesser, "octogan", eligible)

	var ok = true
	ok = ok and _assert_true(board._vote_session_active, "fuzzy path should activate vote session")
	ok = ok and _assert_true(board._vote_session_eligible_by_device.size() == 2, "eligible voter map should be populated")
	ok = ok and _assert_true(board._last_vote_request.get("guesser_id", "") == "player_1", "vote request should carry guesser id")
	ok = ok and _assert_true(board._last_vote_request.get("answer", "") == "octogan", "vote request should carry submitted answer")

	return ok

func _test_duplicate_vote_ignored() -> bool:
	# Arrange: one eligible voter, active vote session.
	var voter = {"id": "player_voter", "name": "Voter"}

	var board = VoteSessionHarness.new()
	board._vote_session_active = true
	board._vote_session_eligible_by_device = {"dev-voter": voter}
	board._vote_session_votes_by_device = {}

	# Act: first vote should finalize, duplicate should be ignored.
	board._on_network_vote_cast("dev-voter", true)
	board._on_network_vote_cast("dev-voter", true)

	# Assert: exactly one resolution and accepted vote result.
	var ok = true
	ok = ok and _assert_true(board._finalized_count == 1, "duplicate vote should not emit extra resolution")
	ok = ok and _assert_true(board._last_vote_result.get("accepted", false) == true, "single accept vote should resolve accepted")
	var yes_voters: Array = board._last_vote_result.get("yes_voters", [])
	ok = ok and _assert_true(yes_voters.size() == 1, "exactly one yes voter should be recorded")
	return ok

func _test_eligible_voters_only() -> bool:
	var voter = {"id": "player_voter", "name": "Voter"}
	var board = VoteSessionHarness.new()
	board._vote_session_active = true
	board._vote_session_eligible_by_device = {"dev-voter": voter}

	# Ineligible device should be ignored and should not finalize.
	board._on_network_vote_cast("dev-stranger", true)

	var ok = true
	ok = ok and _assert_true(board._vote_session_votes_by_device.size() == 0, "ineligible device vote should not be recorded")
	ok = ok and _assert_true(board._finalized_count == 0, "ineligible vote should not finalize session")

	# Eligible vote should finalize session.
	board._on_network_vote_cast("dev-voter", true)
	ok = ok and _assert_true(board._finalized_count == 1, "eligible vote should finalize one-voter session")
	return ok

func _test_guesser_cannot_vote() -> bool:
	var voter = {"id": "player_voter", "name": "Voter"}
	var board = VoteSessionHarness.new()
	board._vote_session_active = true
	board._vote_session_eligible_by_device = {"dev-voter": voter}

	# Simulate guesser trying to vote (not in eligible list).
	board._on_network_vote_cast("dev-guesser", false)

	var ok = true
	ok = ok and _assert_true(board._vote_session_votes_by_device.size() == 0, "guesser vote should be ignored")
	ok = ok and _assert_true(board._finalized_count == 0, "guesser vote should not finalize session")
	return ok

func _test_timeout_finalization() -> bool:
	var voter_a = {"id": "player_a", "name": "A"}
	var voter_b = {"id": "player_b", "name": "B"}
	var voter_c = {"id": "player_c", "name": "C"}
	var board = VoteSessionHarness.new()
	board._vote_session_active = true
	board._vote_session_eligible_by_device = {
		"dev-a": voter_a,
		"dev-b": voter_b,
		"dev-c": voter_c
	}

	# Only one reject vote arrives, then timeout should finalize.
	board._on_network_vote_cast("dev-a", false)
	board._on_network_vote_timeout()

	var ok = true
	ok = ok and _assert_true(board._finalized_count == 1, "timeout should finalize active vote session")
	ok = ok and _assert_true(board._last_vote_result.get("accepted", false) == true, "missing votes default to accept and should produce accepted result")
	var yes_voters: Array = board._last_vote_result.get("yes_voters", [])
	var no_voters: Array = board._last_vote_result.get("no_voters", [])
	ok = ok and _assert_true(yes_voters.size() == 2 and no_voters.size() == 1, "timeout finalization should preserve cast rejects and default remaining accepts")
	return ok

func _test_tie_handling() -> bool:
	var voter_a = {"id": "player_a", "name": "A"}
	var voter_b = {"id": "player_b", "name": "B"}
	var board = VoteSessionHarness.new()
	board._vote_session_active = true
	board._vote_session_eligible_by_device = {
		"dev-a": voter_a,
		"dev-b": voter_b
	}

	board._on_network_vote_cast("dev-a", true)
	board._on_network_vote_cast("dev-b", false)

	var ok = true
	ok = ok and _assert_true(board._finalized_count == 1, "tie scenario should finalize once all votes are cast")
	ok = ok and _assert_true(board._last_vote_result.get("accepted", true) == false, "tie should not be accepted")
	var yes_voters: Array = board._last_vote_result.get("yes_voters", [])
	var no_voters: Array = board._last_vote_result.get("no_voters", [])
	ok = ok and _assert_true(yes_voters.size() == 1 and no_voters.size() == 1, "tie should include one yes and one no voter")
	return ok

func _test_reject_payout_split() -> bool:
	var voter_a = {"id": "player_a", "name": "A"}
	var voter_b = {"id": "player_b", "name": "B"}
	var board = VoteSessionHarness.new()
	var payout = board.calculate_reject_payout(101, [voter_a, voter_b])

	var awards: Dictionary = payout.get("awards", {})
	var ok = true
	ok = ok and _assert_true(payout.get("each_share", -1) == 25, "each voter should receive floored half-prize split")
	ok = ok and _assert_true(awards.get("player_a", -1) == 25 and awards.get("player_b", -1) == 25, "all no-voters should receive equal payout")
	ok = ok and _assert_true(awards.size() == 2, "payout should include only no-voters")
	return ok

func _test_session_reset_on_transition() -> bool:
	var voter = {"id": "player_voter", "name": "Voter"}
	var board = VoteSessionHarness.new()
	board._vote_session_active = true
	board._vote_session_eligible_by_device = {"dev-voter": voter}
	board._vote_session_votes_by_device = {"dev-voter": true}

	board._reset_vote_session()

	var ok = true
	ok = ok and _assert_true(board._vote_session_active == false, "session reset should clear active flag")
	ok = ok and _assert_true(board._vote_session_eligible_by_device.is_empty(), "session reset should clear eligible voters")
	ok = ok and _assert_true(board._vote_session_votes_by_device.is_empty(), "session reset should clear recorded votes")
	return ok

func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("Assertion failed: %s" % message)
	return false
