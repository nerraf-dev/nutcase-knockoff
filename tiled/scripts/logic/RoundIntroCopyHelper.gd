class_name RoundIntroCopyHelper
extends RefCounted

const DEFAULT_STYLE := "casual"

const ROUND_INTRO_TEMPLATES: Dictionary = {
	"casual": {
		"fact_base_only": [
			"This one is worth %d points.",
			"Up for grabs: %d points.",
			"Here comes a %d-point question.",
			"Prize pot says %d points.",
			"A %d-point challenge is rolling in."
		],
		"fact_base_plus_bonus": [
			"This one starts at %d points, with an early-guess bonus.",
			"Worth %d points, plus extra for a quick solve.",
			"%d points on the board, with bonus points for getting in early.",
			"Starts at %d points, and yes, speed gets bonus points.",
			"%d points on offer, plus early-bird bonus."
		],
		"invite": [
			"Give this one a bash.",
			"Have a go.",
			"Give it a bash.",
			"Go on, have a crack.",
			"Let's see who cooks first."
		]
	}
}

var _rng := RandomNumberGenerator.new()
var _last_variant_index_by_key: Dictionary = {}


func _init() -> void:
	_rng.randomize()


func build_round_intro_message(base_points: int, include_bonus_hint: bool = true, style_override: String = "") -> String:
	var style_key := _resolve_style(style_override)
	var style_templates: Dictionary = ROUND_INTRO_TEMPLATES[style_key]

	var fact_key := "fact_base_plus_bonus" if include_bonus_hint else "fact_base_only"
	var fact_line := _pick_variant(style_templates, fact_key, style_key) % [base_points]
	var invite_line := _pick_variant(style_templates, "invite", style_key)
	return "%s\n%s" % [fact_line, invite_line]


func _resolve_style(style_override: String) -> String:
	if not style_override.is_empty() and ROUND_INTRO_TEMPLATES.has(style_override.to_lower()):
		return style_override.to_lower()
	return DEFAULT_STYLE


func _pick_variant(style_templates: Dictionary, key: String, style_key: String) -> String:
	var variants_any = style_templates.get(key, [])
	if not (variants_any is Array):
		return str(variants_any)

	var variants: Array = variants_any
	if variants.is_empty():
		return ""

	var chosen_index := 0
	if variants.size() > 1:
		chosen_index = _rng.randi_range(0, variants.size() - 1)
		var memory_key := "%s:%s" % [style_key, key]
		var last_index := int(_last_variant_index_by_key.get(memory_key, -1))
		if chosen_index == last_index:
			chosen_index = (chosen_index + 1) % variants.size()
		_last_variant_index_by_key[memory_key] = chosen_index

	return str(variants[chosen_index])
