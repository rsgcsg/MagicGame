extends SceneTree

const TEMPLATE_CATALOG := preload("res://scripts/magic_circle/magic_circle_template_catalog.gd")
const MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const EVALUATOR := preload("res://scripts/magic_circle/placeholder_card_evaluator.gd")
const GENERATED_CARD_BUILDER := preload("res://scripts/cards/generated_card_builder.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_run_checks()
	if _failures.is_empty():
		print("Card generation sanity check passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _run_checks() -> void:
	var line_recipe: Dictionary = _evaluate_recipe("line", ["fire_crystal", "water_dew", "earth_stone"])
	var triangle_recipe: Dictionary = _evaluate_recipe("triangle", ["fire_crystal", "water_dew", "earth_stone"])
	_expect(_effect_signature(line_recipe) != _effect_signature(triangle_recipe), "Line and triangle should differ for the same ordered materials.")

	var line_swapped: Dictionary = _evaluate_recipe("line", ["fire_crystal", "earth_stone", "water_dew"])
	_expect(_effect_signature(line_recipe) != _effect_signature(line_swapped), "Line template should react to material placement changes.")

	var hidden_recipe: Dictionary = _evaluate_recipe("triangle", ["wind_feather", "wind_feather", "fire_crystal"])
	_expect(int(hidden_recipe.get("hidden_effects", []).size()) > 0, "Hidden effects should be recorded for latent recipes.")
	_expect(float(hidden_recipe.get("waste_score", 0.0)) > 0.0, "Waste score should be recorded for unstable recipes.")

	var visible_cap_recipe: Dictionary = _evaluate_recipe("star", ["wind_feather", "fire_crystal", "water_dew", "earth_stone", "unstable_mixture"])
	_expect(int(visible_cap_recipe.get("visible_effects", []).size()) <= 3, "Visible effects should stay capped at 3.")

	var large_recipe: Dictionary = _evaluate_recipe("wheel", ["fire_crystal", "water_dew", "earth_stone", "wind_feather", "moss_amber", "stormglass_prism", "unstable_mixture"])
	_expect(bool(large_recipe.get("valid", false)), "Large authored templates should evaluate through the existing circle flow.")
	_expect(int((large_recipe.get("source_material_ids", []) as Array).size()) >= 6, "Large templates should preserve larger source material lists.")

	var unstable_recipe: Dictionary = _evaluate_recipe("line", ["fire_crystal", "water_dew", "wind_feather"])
	var unstable_texts: Array = unstable_recipe.get("visible_effect_texts", [])
	var has_bad_text := false
	for text_variant in unstable_texts:
		var text := str(text_variant)
		if text.contains("Down") or text.contains("Lose") or text.contains("Discard") or text.contains("Heal enemy"):
			has_bad_text = true
			break
	_expect(has_bad_text or float(unstable_recipe.get("waste_score", 0.0)) >= 50.0, "Unstable combinations should produce bad visible effects or heavy waste.")

	var generated_card: GeneratedCardData = GENERATED_CARD_BUILDER.build_from_alchemy_evaluation(visible_cap_recipe)
	_expect(generated_card != null, "Generated card builder should still return a card.")
	_expect(generated_card.effect_lines.size() <= 3, "Generated cards should keep the visible effect cap.")
	_expect(not generated_card.source_effect_vector32.is_empty(), "Generated cards should store the effect vector.")
	_expect(not generated_card.combat_payload.is_empty(), "Generated cards should store structured combat payloads.")
	_expect(int((generated_card.combat_payload.get("effects", []) as Array).size()) > 0, "Generated card combat payloads should include executable effects.")
	_expect(generated_card.algorithm_id == "first_order_magic_circle_v1", "Generated cards should record the algorithm id.")

func _evaluate_recipe(template_id: String, material_ids: Array[String]) -> Dictionary:
	var template_data: Dictionary = TEMPLATE_CATALOG.get_template(template_id)
	var node_assignments: Dictionary = {}
	var nodes: Array = template_data.get("nodes", [])
	for index in range(min(nodes.size(), material_ids.size())):
		var node_id := str(nodes[index])
		var material_id: String = material_ids[index]
		var material_data: Dictionary = MATERIAL_CATALOG.get_material(material_id)
		material_data["material_id"] = material_id
		node_assignments[node_id] = material_data
	return EVALUATOR.evaluate(template_id, template_data, node_assignments)

func _effect_signature(result: Dictionary) -> String:
	var debug_data: Dictionary = result.get("debug_data", {})
	var rows: Array = debug_data.get("top_dimensions", [])
	var parts: Array[String] = []
	for row_variant in rows:
		var row: Dictionary = row_variant
		parts.append("%s:%s" % [row.get("id", ""), row.get("value", 0.0)])
	return "|".join(parts)

func _expect(condition: bool, failure_message: String) -> void:
	if not condition:
		_failures.append(failure_message)
