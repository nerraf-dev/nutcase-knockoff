class_name RoundScoringRules
extends RefCounted

const SHOW_SCORING_BREAKDOWN_DETAILS := false # Set to true to enable detailed scoring breakdowns in messages (for debugging/demo purposes)
const DEFAULT_STYLE := "casual"

# RoundScoringRules — scripts/logic/round_scoring_rules.gd
# Role: Stateless rules helper for round resolution and scoring outcomes.
# Owns: Winner detection, wrong/correct answer outcome shaping, vote-rejection payout logic.
# Does not own: Game state transitions (GameManager), player storage/turn index (PlayerManager).
#
# Public API:
# - check_for_winner(game_target)
# - handle_wrong_answer(player, base_prize, current_question)
# - handle_correct_answer(player, prize, is_auto_accept, game_target, submitted_answer, scoring_breakdown = {})
# - handle_vote_rejection(prize, no_voters)
#
# Output contract:
# - Returns plain dictionaries consumed by GameManager/UI flow.
# - Mutates player score/freeze state only through PlayerManager/player fields.

const MESSAGE_TEMPLATE_SETS: Dictionary = {
	"casual": {
		"wrong_frozen": [
			"%s is wrong!\nYou lose %d points and are frozen out of the round.",
			"Not this time, %s.\n-%d points and you're frozen for this round.",
			"%s misses the mark!\nYou lose %d points and sit this round out.",
			"Nope, %s!\nYou drop %d points and are benched for this round.",
			"Swing and a miss, %s.\n-%d points and you're iced."
		],
		"last_standing": [
			"Last player standing!\n%s gets a free guess!",
			"Everyone else is frozen.\n%s gets the free guess.",
			"%s stands alone!\nTake the free guess.",
			"All eyes on %s.\nYou've got a free guess.",
			"%s survives the chaos!\nGrab your free guess."
		],
		"wrong_lps": [
			"%s is wrong!\nThe answer was: %s",
			"%s was close, but no.\nThe correct answer was: %s.",
			"Nope, %s.\nCorrect answer: %s",
			"%s misses!\nCorrect answer: %s",
			"Oof, %s.\nThe right answer was %s."
		],
		"correct_exact": [
			"%s nailed it!\nHere's %d points!",
			"Exact match!\n%s earns %d points.",
			"Bullseye, %s!\n+%d points.",
			"%s is bang on!\nPocket +%d points.",
			"Chef's kiss, %s.\nTake +%d points."
		],
		"correct_fuzzy": [
			"%s is close enough, %s!\nYou get %d points!",
			"Judges allow it for %s!\n%s gets %d points.",
			"We'll take that, %s.\n%s gets +%d points.",
			"It's janky but it works, %s.\n%s gets %d points.",
			"The crowd shrugs and allows it.\n%s gets +%d points for %s."
		]
	}
}

var _rng := RandomNumberGenerator.new()
var _last_variant_index_by_key: Dictionary = {}


func _init() -> void:
	_rng.randomize()

func _active_message_style() -> String:
	var style_key := GameConfig.MESSAGE_STYLE_DEFAULT.to_lower()
	if MESSAGE_TEMPLATE_SETS.has(style_key):
		return style_key
	return DEFAULT_STYLE


func _choose_template_variant(templates: Dictionary, template_key: String, style_key: String) -> String:
	var template_entry = templates.get(template_key, template_key)
	if template_entry is String:
		return template_entry
	if not (template_entry is Array):
		return str(template_entry)

	var variants: Array = template_entry
	if variants.is_empty():
		return template_key

	var chosen_index := 0
	if variants.size() == 1:
		chosen_index = 0
	else:
		chosen_index = _rng.randi_range(0, variants.size() - 1)
		var memory_key := "%s:%s" % [style_key, template_key]
		var last_index := int(_last_variant_index_by_key.get(memory_key, -1))
		if chosen_index == last_index:
			chosen_index = (chosen_index + 1) % variants.size()
		_last_variant_index_by_key[memory_key] = chosen_index

	return str(variants[chosen_index])

func _message(template_key: String, values: Array = [], style_override: String = "") -> String:
	var style_key := style_override.to_lower() if style_override != "" else _active_message_style()
	if not MESSAGE_TEMPLATE_SETS.has(style_key):
		style_key = DEFAULT_STYLE

	var templates: Dictionary = MESSAGE_TEMPLATE_SETS[style_key]
	if not templates.has(template_key):
		templates = MESSAGE_TEMPLATE_SETS[DEFAULT_STYLE]
		style_key = DEFAULT_STYLE

	var template: String = _choose_template_variant(templates, template_key, style_key)
	if values.is_empty():
		return template
	return template % values

func _format_points_breakdown_suffix(prize: int, scoring_breakdown: Dictionary) -> String:
	if not SHOW_SCORING_BREAKDOWN_DETAILS:
		return ""
	if scoring_breakdown.is_empty():
		return ""
	var base_points = int(scoring_breakdown.get("base_points", prize))
	var bonus_points = int(scoring_breakdown.get("bonus_points", 0))
	if bonus_points <= 0:
		return ""
	return "\n(+ %d + %d bonus for guessing early!)" % [base_points, bonus_points]
	

func check_for_winner(game_target: int) -> Array[Player]:
	var winners: Array[Player] = []
	for player in PlayerManager.get_active_players():
		if player.score >= game_target:
			winners.append(player)
	return winners

func handle_wrong_answer(player: Player, base_prize: int, current_question: Resource, submitted_answer: String) -> Dictionary:
	var result = {
		"player": player,
		"penalty": 0,
		"is_frozen": false,
		"is_last_standing": false,
		"is_lps_wrong": false,
		"last_standing_player": null,
		"correct_answer": "",
		"submitted_answer": submitted_answer,
		"message": ""
	}

	var active_players = PlayerManager.get_active_players()

	if active_players.size() > 1:
		var penalty = int(base_prize * GameConfig.PENALTY_MULTIPLIER)
		PlayerManager.award_points(player, -penalty)
		PlayerManager.freeze_player(player)
		result["penalty"] = penalty
		result["is_frozen"] = true
		result["message"] = _message("wrong_frozen", [result["submitted_answer"], penalty])
		print("Player %s is now frozen for this question." % player.name)

		active_players = PlayerManager.get_active_players()
		if active_players.size() == 1:
			result["is_last_standing"] = true
			result["last_standing_player"] = active_players[0]
			result["message"] = _message("last_standing", [active_players[0].name])
			print("Free guess for %s - no penalty applied" % active_players[0].name)
	elif active_players.size() == 1:
		result["is_lps_wrong"] = true
		result["correct_answer"] = current_question.answer if current_question else ""
		result["message"] = _message("wrong_lps", [result["submitted_answer"], result["correct_answer"]])
		print("Last player standing got it wrong. Round ends.")

	return result

func handle_correct_answer(player: Player, prize: int, is_auto_accept: bool, game_target: int, submitted_answer: String, scoring_breakdown: Dictionary = {}) -> Dictionary:
	var result = {
		"player": player,
		"prize": prize,
		"scoring_breakdown": scoring_breakdown,
		"was_frozen": player.is_frozen,
		"has_winner": false,
		"winner": null,
		"submitted_answer": submitted_answer,
		"message": ""
	}

	print("Player %s answered correctly!" % player.name)
	PlayerManager.award_points(player, prize)
	player.is_frozen = false

	if is_auto_accept:
		result["message"] = _message("correct_fuzzy", [result["submitted_answer"], result["player"].name, prize])
	else:
		result["message"] = _message("correct_exact", [result["submitted_answer"].to_upper(), prize])
	result["message"] += _format_points_breakdown_suffix(prize, scoring_breakdown)

	var winners = check_for_winner(game_target)
	if not winners.is_empty():
		result["has_winner"] = true
		result["winner"] = winners[0]
		print("We have a winner: %s!" % winners[0].name)
	else:
		print("No winner yet, continuing to next round.")

	return result

func handle_vote_rejection(prize: int, no_voters: Array[Player]) -> void:
	if no_voters.is_empty():
		return
	var each_share = int((prize / 2.0) / no_voters.size())
	for voter in no_voters:
		PlayerManager.award_points(voter, each_share)
		print("Vote rejection: %s awarded %d points" % [voter.name, each_share])
