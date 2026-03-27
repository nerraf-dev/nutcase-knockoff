class_name RoundResolutionHelper
extends RefCounted

# RoundResolutionHelper — scripts/logic/RoundResolutionHelper.gd
# Role: Stateless rules helper for round resolution and scoring outcomes.
# Owns: Winner detection, wrong/correct answer outcome shaping, vote-rejection payout logic.
# Does not own: Game state transitions (GameManager), player storage/turn index (PlayerManager).
#
# Public API:
# - check_for_winner(game_target)
# - handle_wrong_answer(player, base_prize, current_question)
# - handle_correct_answer(player, prize, is_auto_accept, game_target)
# - handle_vote_rejection(prize, no_voters)
#
# Output contract:
# - Returns plain dictionaries consumed by GameManager/UI flow.
# - Mutates player score/freeze state only through PlayerManager/player fields.

const MESSAGE_TEMPLATE_SETS: Dictionary = {
	"default": {
		"wrong_frozen": "%s is wrong!\nYou lose %d points and are frozen out of the round.",
		"last_standing": "Last player standing!\n%s gets a free guess!",
		"wrong_lps": "%s is wrong!\nThe answer was: %s",
		"correct_exact": "%s is correct!\nYou get %d points!",
		"correct_fuzzy": "%s is close enough, %s!\nYou get %d points!"
	},
	"funny": {
		"wrong_frozen": "Nope, %s!\nYou drop %d points and are benched for this round.",
		"last_standing": "%s is the last walnut standing!\nFree guess time.",
		"wrong_lps": "%s misses!\nCorrect answer: %s",
		"correct_exact": "%s is bang on!\nPocket +%d points.",
		"correct_fuzzy": "%s is close enough, %s!\nTake +%d points."
	},
	"serious": {
		"wrong_frozen": "%s is incorrect.\n-%d points; player is frozen for this round.",
		"last_standing": "%s remains active.\nA free guess is granted.",
		"wrong_lps": "%s is incorrect.\nCorrect answer: %s",
		"correct_exact": "%s is correct.\n+%d points awarded.",
		"correct_fuzzy": "%s accepted as close enough for %s.\n+%d points awarded."
	}
}

func _active_message_style() -> String:
	var style_key := GameConfig.MESSAGE_STYLE_DEFAULT.to_lower()
	if MESSAGE_TEMPLATE_SETS.has(style_key):
		return style_key
	return "default"

func _message(template_key: String, values: Array = [], style_override: String = "") -> String:
	var style_key := style_override.to_lower() if style_override != "" else _active_message_style()
	if not MESSAGE_TEMPLATE_SETS.has(style_key):
		style_key = "default"

	var templates: Dictionary = MESSAGE_TEMPLATE_SETS[style_key]
	if not templates.has(template_key):
		templates = MESSAGE_TEMPLATE_SETS["default"]

	var template: String = templates.get(template_key, template_key)
	if values.is_empty():
		return template
	return template % values

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

func handle_correct_answer(player: Player, prize: int, is_auto_accept: bool, game_target: int, submitted_answer: String) -> Dictionary:
	var result = {
		"player": player,
		"prize": prize,
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
