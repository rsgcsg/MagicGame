class_name GeneratedCardBuilder
extends RefCounted

const COMBAT_PAYLOAD_BUILDER := preload("res://scripts/cards/generated_card_combat_payload_builder.gd")

static func build_placeholder_card() -> GeneratedCardData:
	var card := GeneratedCardData.new()
	card.card_id = "generated_placeholder"
	card.display_name = "Unstable Spark"
	card.description = "Placeholder generated card."
	card.action_point_cost = 1
	card.single_use = true
	card.effect_lines.assign(["Deal 6 damage"])
	card.combat_payload = {
		"target": "enemy",
		"effects": [
			{"type": "damage", "target": "enemy", "value": 6},
		],
	}
	card.debug_summary = "Architecture scaffold placeholder."
	return card

static func build_from_alchemy_evaluation(evaluation_result: Dictionary) -> GeneratedCardData:
	var card_preview: Dictionary = evaluation_result.get("card_preview", {})
	var debug_lines: Array = evaluation_result.get("debug_lines", [])
	var visible_effect_texts: Array[String] = []
	if evaluation_result.get("visible_effect_texts", []) is Array:
		for effect_text in evaluation_result.get("visible_effect_texts", []):
			visible_effect_texts.append(str(effect_text))
	if visible_effect_texts.is_empty():
		for effect_data_variant in evaluation_result.get("visible_effects", []):
			var effect_data: Dictionary = effect_data_variant
			visible_effect_texts.append(str(effect_data.get("text", "")))
	var card := GeneratedCardData.new()
	card.card_id = str(card_preview.get("card_id", evaluation_result.get("card_id", "alchemy_generated_preview")))
	card.display_name = str(card_preview.get("card_name", "Generated Card"))
	card.description = str(card_preview.get("description", "Placeholder card generated at the Alchemy Table."))
	card.action_point_cost = int(card_preview.get("action_point_cost", 1))
	card.single_use = bool(card_preview.get("single_use", true))
	card.algorithm_id = str(evaluation_result.get("algorithm_id", ""))
	card.source_template_id = str(evaluation_result.get("template_id", ""))
	card.source_circle_order = int(evaluation_result.get("order", 1))
	card.source_material_ids.assign(evaluation_result.get("source_material_ids", evaluation_result.get("material_ids", [])))
	card.source_material_counts = evaluation_result.get("source_material_counts", {}).duplicate(true)
	card.source_element_vector4 = evaluation_result.get("element_vector4", {}).duplicate(true)
	card.source_effect_vector32 = evaluation_result.get("effect_vector32", {}).duplicate(true)
	card.combat_payload = evaluation_result.get("combat_payload", {"target": "none", "effects": []}).duplicate(true)
	card.hidden_effects = (evaluation_result.get("hidden_effects", []) as Array).duplicate(true)
	card.waste_dimensions = (evaluation_result.get("waste_dimensions", []) as Array).duplicate(true)
	card.waste_score = float(evaluation_result.get("waste_score", 0.0))
	card.effect_lines.assign(card_preview.get("effect_lines", visible_effect_texts))
	card.debug_summary = "\n".join(debug_lines) if debug_lines is Array else str(evaluation_result.get("debug_summary", ""))
	return card

static func build_from_alchemy_preview(preview_data: Dictionary) -> GeneratedCardData:
	return build_from_alchemy_evaluation(preview_data)

static func build_placeholder_realm_reward_card(reward_id: String, reward_context: Dictionary = {}) -> GeneratedCardData:
	var card := GeneratedCardData.new()
	card.card_id = "realm_reward_%s" % reward_id
	card.display_name = str(reward_context.get("display_name", "Realm Echo"))
	card.description = str(reward_context.get("description", "A temporary realm-forged reward card."))
	card.action_point_cost = int(reward_context.get("action_point_cost", 1))
	card.single_use = bool(reward_context.get("single_use", true))
	card.source_template_id = "realm_reward"
	card.source_circle_order = 1
	var reward_effect_lines: Array = reward_context.get("effect_lines", ["Deal 7 damage"])
	card.effect_lines.assign(reward_effect_lines)
	if reward_context.get("combat_payload", {}) is Dictionary and not (reward_context.get("combat_payload", {}) as Dictionary).is_empty():
		card.combat_payload = (reward_context.get("combat_payload", {}) as Dictionary).duplicate(true)
	else:
		card.combat_payload = COMBAT_PAYLOAD_BUILDER.build_from_effect_lines_legacy(card.effect_lines, 7)
	card.debug_summary = "Realm reward placeholder card."
	return card
