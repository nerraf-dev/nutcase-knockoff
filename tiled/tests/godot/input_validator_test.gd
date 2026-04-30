extends SceneTree

# Headless test runner for InputValidator.
# Run with: godot --headless -s res://tests/godot/input_validator_test.gd
#
# Covers:
#   validate_player_name  — empty, whitespace, too long, invalid chars, edge chars
#   validate_answer       — exact, case, article/prefix stripping, whitespace trim,
#                           empty/whitespace, numeric exact, numeric near-miss,
#                           short-answer no-fuzzy, auto-accept, fuzzy, incorrect,
#                           alt_answers hit, fuzzy_enabled=false
#
# Exit code: 0 = all pass, 1 = one or more fail.

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	print("\n=== InputValidator headless tests ===\n")
	_run_player_name_tests()
	_run_answer_tests()
	var status := "OK" if _fail_count == 0 else "FAIL"
	print("\n[%s] %d passed, %d failed\n" % [status, _pass_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _check(label: String, expected, got) -> void:
	if expected == got:
		_pass_count += 1
		print("  PASS  %s" % label)
	else:
		_fail_count += 1
		print("  FAIL  %s  [expected=%s  got=%s]" % [label, str(expected), str(got)])


func _make_q(answer: String, alts: Array = []) -> Question:
	var q := Question.new()
	q.answer = answer
	var typed_alts: Array[String] = []
	for a in alts:
		typed_alts.append(str(a))
	q.alt_answers = typed_alts
	return q


# ---------------------------------------------------------------------------
# validate_player_name
# ---------------------------------------------------------------------------

func _run_player_name_tests() -> void:
	print("-- validate_player_name --")
	var r: Dictionary

	r = InputValidator.validate_player_name("Alice")
	_check("simple name valid", true, r["valid"])

	r = InputValidator.validate_player_name("  Bob  ")
	_check("surrounding spaces stripped, then valid", true, r["valid"])

	r = InputValidator.validate_player_name("Player-1")
	_check("hyphen allowed", true, r["valid"])

	r = InputValidator.validate_player_name("O'Brien")
	_check("apostrophe allowed", true, r["valid"])

	r = InputValidator.validate_player_name("Dr. Watson")
	_check("dot and space allowed", true, r["valid"])

	r = InputValidator.validate_player_name("A".repeat(20))
	_check("exactly 20 chars is valid", true, r["valid"])

	r = InputValidator.validate_player_name("")
	_check("empty string invalid", false, r["valid"])

	r = InputValidator.validate_player_name("   ")
	_check("whitespace-only invalid", false, r["valid"])

	r = InputValidator.validate_player_name("A".repeat(21))
	_check("21 chars invalid (over limit)", false, r["valid"])

	r = InputValidator.validate_player_name("Player@1")
	_check("@ symbol invalid", false, r["valid"])

	r = InputValidator.validate_player_name("name<script>")
	_check("angle brackets invalid", false, r["valid"])

	r = InputValidator.validate_player_name("name;DROP")
	_check("semicolon invalid", false, r["valid"])


# ---------------------------------------------------------------------------
# validate_answer
# ---------------------------------------------------------------------------

func _run_answer_tests() -> void:
	print("\n-- validate_answer --")
	var r: Dictionary
	var R := InputValidator.ValidationResult

	# --- Exact match ---
	var q_photo := _make_q("Photosynthesis")

	r = InputValidator.validate_answer("Photosynthesis", q_photo)
	_check("exact match -> EXACT", R.EXACT, r["result"])

	r = InputValidator.validate_answer("photosynthesis", q_photo)
	_check("lowercase exact -> EXACT (case insensitive)", R.EXACT, r["result"])

	r = InputValidator.validate_answer("  Photosynthesis  ", q_photo)
	_check("padded whitespace exact -> EXACT", R.EXACT, r["result"])

	# --- Article stripping ---
	# answer "Beatles", submitted "The Beatles" — both normalise to "beatles"
	var q_beatles := _make_q("Beatles")
	r = InputValidator.validate_answer("The Beatles", q_beatles)
	_check("'The' stripped on submission -> EXACT", R.EXACT, r["result"])

	# answer "Sahara", submitted "The Sahara"
	var q_sahara := _make_q("Sahara")
	r = InputValidator.validate_answer("The Sahara", q_sahara)
	_check("'The' stripped on submission (geo) -> EXACT", R.EXACT, r["result"])

	# --- Geographic prefix stripping ---
	# answer "Everest", submitted "Mount Everest" — both strip to "everest"
	var q_everest := _make_q("Everest")
	r = InputValidator.validate_answer("Mount Everest", q_everest)
	_check("'Mount' stripped on submission -> EXACT", R.EXACT, r["result"])

	# answer "Mount Everest", submitted "Everest" — answer strips to "everest" too
	var q_meverest := _make_q("Mount Everest")
	r = InputValidator.validate_answer("Everest", q_meverest)
	_check("'Mount' stripped from answer side -> EXACT", R.EXACT, r["result"])

	# --- Invalid (empty / whitespace) ---
	r = InputValidator.validate_answer("", q_photo)
	_check("empty answer -> INVALID", R.INVALID, r["result"])

	r = InputValidator.validate_answer("   ", q_photo)
	_check("whitespace-only answer -> INVALID", R.INVALID, r["result"])

	# --- Numeric: exact vs near-miss ---
	# Numeric answers must be exact; distance-1 should NOT trigger fuzzy
	var q_year := _make_q("1969")
	r = InputValidator.validate_answer("1969", q_year)
	_check("numeric exact -> EXACT", R.EXACT, r["result"])

	r = InputValidator.validate_answer("1968", q_year)
	_check("numeric 1-off -> INCORRECT (numeric guard, no fuzzy)", R.INCORRECT, r["result"])

	# --- Short answer (len <= FUZZY_MIN_LENGTH, fuzzy disabled by guard) ---
	# "Paris" normalises to "paris" = 5 chars = FUZZY_MIN_LENGTH, no fuzzy eligible
	var q_paris := _make_q("Paris")
	r = InputValidator.validate_answer("Paris", q_paris)
	_check("short exact -> EXACT", R.EXACT, r["result"])

	r = InputValidator.validate_answer("Parix", q_paris)
	_check("short 1-off -> INCORRECT (too short for fuzzy)", R.INCORRECT, r["result"])

	# --- Auto-accept: 1-char off on a 6-char word ---
	# "London" (6 chars > FUZZY_MIN_LENGTH=5)
	# auto_accept = max(1, 6/8) = 1   fuzzy = max(2, 6/6) = 2
	# "Londan": 'o'(pos4) -> 'a'  distance=1 -> AUTO_ACCEPT
	var q_london := _make_q("London")
	r = InputValidator.validate_answer("London", q_london)
	_check("6-char exact -> EXACT", R.EXACT, r["result"])

	r = InputValidator.validate_answer("Londan", q_london)
	_check("6-char 1-off -> AUTO_ACCEPT", R.AUTO_ACCEPT, r["result"])

	# --- Fuzzy: 2-char off on same 6-char word ---
	# "Landan": 'o'(pos1)->'a', 'o'(pos4)->'a'  distance=2 -> FUZZY
	r = InputValidator.validate_answer("Landan", q_london)
	_check("6-char 2-off -> FUZZY", R.FUZZY, r["result"])

	# --- Incorrect: too many edits ---
	r = InputValidator.validate_answer("Paris", q_london)
	_check("completely different answer -> INCORRECT", R.INCORRECT, r["result"])

	# --- Alt answers ---
	# Main: "United Kingdom", alts: ["UK", "Great Britain"]
	# "Great Britain" (13 chars) submitted exactly -> EXACT via alt
	var q_uk := _make_q("United Kingdom", ["UK", "Great Britain"])
	r = InputValidator.validate_answer("United Kingdom", q_uk)
	_check("main answer -> EXACT", R.EXACT, r["result"])

	r = InputValidator.validate_answer("Great Britain", q_uk)
	_check("alt answer exact -> EXACT", R.EXACT, r["result"])

	# --- fuzzy_enabled = false ---
	# Same 1-off submission that would be AUTO_ACCEPT should be INCORRECT when fuzzy off
	r = InputValidator.validate_answer("Londan", q_london, false)
	_check("fuzzy disabled: 1-off -> INCORRECT", R.INCORRECT, r["result"])


	# --- Fuzzy: 2-char off on same 6-char word ---
	# "octogan" vs "octagon" distance=2 -> FUZZY 
	var q_oct := _make_q("octagon")
	r = InputValidator.validate_answer("octogan", q_oct)
	_check("6-char 2-off -> FUZZY", R.FUZZY, r["result"])