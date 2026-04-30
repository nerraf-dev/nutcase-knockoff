class_name VoteMessageBuilder
extends RefCounted

const DEFAULT_STYLE := "casual"

const MESSAGE_TEMPLATE_SETS: Dictionary = {
	"casual": {
		"vote_incoming": [
			"{player} answered: \"{answer}\"\nClose enough for the points?\nVOTE!",
			"{player} said \"{answer}\".\nYou gonna take that?",
			"\"{answer}\" from {player}.\nDoes it count?",
			"{player} dropped an answer.\nClose enough?\nCast your vote.",
			"Ooh, {player} said \"{answer}\"...\nIs that good enough?",
			"{player} reckons \"{answer}\" is close.\nIs it though?"
		],
		"vote_active_title": [
			"Cast your vote now"
		],
		"vote_active_body": [
			"Majority accepts. Tie = reject."
		],
		"vote_result_title": [
			"Vote result"
		],
		"vote_result_accepted": [
			"Accepted"
		],
		"vote_result_rejected": [
			"Rejected"
		],
		"vote_result_tie_rejected": [
			"Tie - Rejected"
		],
		"vote_accepted_outcome": [
			"Vote passed. {player} gets +{points} points for \"{answer}\".",
			"Lucky break, {player}. Accepted for +{points} points.",
			"The vote says yes. {player} scores +{points} for \"{answer}\"."
		],
		"vote_rejected_tie_outcome": [
			"It's a tie. Nobody wins the prize.",
			"Deadlocked vote. No points awarded.",
			"Tie vote. The pot stays put."
		],
		"vote_rejected_shared_outcome": [
			"Rejected. The prize was shared among NO votes.",
			"Vote failed. NO voters split the points.",
			"Not accepted. NO voters share the pot."
		],
		"unvotable_accepted_outcome": [
			"No one can vote right now. Lucky one, {player} gets +{points} points.",
			"No {scope} voters available. \"{answer}\" sneaks through for +{points} points.",
			"No {scope} voters to challenge it. {player} takes +{points} points."
		],
		"unvotable_rejected_outcome": [
			"No one can vote right now, and it wasn't close enough. No points this time.",
			"No {scope} voters available, and \"{answer}\" was too far off. No points.",
			"No {scope} voters to decide it, and it misses the mark. No points this round."
		]
	}
}

var _rng := RandomNumberGenerator.new()
var _last_template_index_by_key: Dictionary = {}


func _init() -> void:
	_rng.randomize()


func build(template_key: String, tokens: Dictionary = {}, style_override: String = "") -> String:
	var style_key := _resolve_style(style_override)
	var templates: Dictionary = MESSAGE_TEMPLATE_SETS[style_key]
	if not templates.has(template_key):
		templates = MESSAGE_TEMPLATE_SETS[DEFAULT_STYLE]
		style_key = DEFAULT_STYLE

	var template_text := _pick_variant(templates, template_key, style_key)
	if tokens.is_empty():
		return template_text
	return _fill_template(template_text, tokens)


func _resolve_style(style_override: String) -> String:
	if not style_override.is_empty() and MESSAGE_TEMPLATE_SETS.has(style_override.to_lower()):
		return style_override.to_lower()
	return DEFAULT_STYLE


func _pick_variant(templates: Dictionary, template_key: String, style_key: String) -> String:
	var entry = templates.get(template_key, "")
	if entry is String:
		return str(entry)
	if not (entry is Array):
		return str(entry)

	var variants: Array = entry
	if variants.is_empty():
		return ""

	var chosen_index := 0
	if variants.size() > 1:
		chosen_index = _rng.randi_range(0, variants.size() - 1)
		var memory_key := "%s:%s" % [style_key, template_key]
		var last_index := int(_last_template_index_by_key.get(memory_key, -1))
		if chosen_index == last_index:
			chosen_index = (chosen_index + 1) % variants.size()
		_last_template_index_by_key[memory_key] = chosen_index

	return str(variants[chosen_index])


func _fill_template(template: String, tokens: Dictionary) -> String:
	var result := template
	for key in tokens.keys():
		result = result.replace("{%s}" % str(key), str(tokens[key]))
	return result
