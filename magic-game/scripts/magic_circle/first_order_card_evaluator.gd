class_name FirstOrderCardEvaluator
extends RefCounted

const BALANCE_PROFILE := preload("res://scripts/magic_circle/generated_card_balance_profile.gd")
const COMBAT_PAYLOAD_BUILDER := preload("res://scripts/cards/generated_card_combat_payload_builder.gd")

const ELEMENTS := ["fire", "water", "earth", "wind"]
const PAIR8_IDS := ["FF", "WW", "EE", "AA", "FE", "FA", "WE", "WA"]
const PAIR_ORDER := {
	"FF": 0,
	"WW": 1,
	"EE": 2,
	"AA": 3,
	"FE": 4,
	"FA": 5,
	"WE": 6,
	"WA": 7,
}
const PURE_PAIR_BY_ELEMENT := {
	"fire": "FF",
	"water": "WW",
	"earth": "EE",
	"wind": "AA",
}
const MIXED_PAIR_BY_ELEMENTS := {
	"earth|fire": "FE",
	"fire|wind": "FA",
	"earth|water": "WE",
	"water|wind": "WA",
}
const FORBIDDEN_QUAD_TRANSFERS := {
	"FF|WW": [{"id": "Q01", "ratio": 0.5}, {"id": "Q02", "ratio": 0.5}],
	"AA|EE": [{"id": "Q04", "ratio": 0.5}, {"id": "Q03", "ratio": 0.5}],
	"FA|WE": [{"id": "Q19", "ratio": 0.5}, {"id": "Q18", "ratio": 0.5}],
	"FE|WA": [{"id": "Q17", "ratio": 0.5}, {"id": "Q20", "ratio": 0.5}],
}
const EFFECT_MAPPING := BALANCE_PROFILE.EFFECT_MAPPING

const DEFAULT_FIRST_PROPAGATION_RATE := BALANCE_PROFILE.DEFAULT_FIRST_PROPAGATION_RATE
const DEFAULT_SECOND_PROPAGATION_RATE := BALANCE_PROFILE.DEFAULT_SECOND_PROPAGATION_RATE
const DEFAULT_MAX_VISIBLE_EFFECTS := BALANCE_PROFILE.DEFAULT_MAX_VISIBLE_EFFECTS
const DEFAULT_LATENT_ACTIVATION_MIN_ORDER := BALANCE_PROFILE.DEFAULT_LATENT_ACTIVATION_MIN_ORDER
const EPSILON := 0.000001

static func evaluate_circle(circle_input: Dictionary) -> Dictionary:
	var circle_id := str(circle_input.get("circle_id", "alchemy_circle"))
	var template_id := str(circle_input.get("template_id", "unknown_template"))
	var template_name := str(circle_input.get("template_name", "Magic Circle"))
	var order := int(circle_input.get("order", 1))
	var circle_nodes: Array = circle_input.get("nodes", [])
	var edges: Array = circle_input.get("edges", [])
	var missing_nodes: Array[String] = []
	var source_material_ids: Array[String] = []
	var source_material_counts := {}
	var node_vectors := {}
	var initial_element_totals := _zero_vector(ELEMENTS)

	if circle_nodes.is_empty():
		return _build_invalid_result(circle_id, template_id, template_name, order, missing_nodes, "No circle nodes available.")

	for node_data in circle_nodes:
		var node_id := str(node_data.get("id", ""))
		var payload: Dictionary = node_data.get("payload", {})
		if str(payload.get("type", "")) != "material":
			missing_nodes.append(node_id)
			continue

		var material_id := str(payload.get("material_id", ""))
		var vector_data: Dictionary = payload.get("vector4", {})
		if vector_data.is_empty() and not material_id.is_empty():
			vector_data = MagicMaterialCatalog.get_material(material_id).get("vector", {}).duplicate(true)
		if material_id.is_empty() or vector_data.is_empty():
			missing_nodes.append(node_id)
			continue

		var normalized_vector := _normalize_vector(vector_data, ELEMENTS)
		node_vectors[node_id] = normalized_vector
		initial_element_totals = _add_vectors(initial_element_totals, normalized_vector, ELEMENTS)
		source_material_ids.append(material_id)
		source_material_counts[material_id] = int(source_material_counts.get(material_id, 0)) + 1

	if not missing_nodes.is_empty():
		return _build_invalid_result(
			circle_id,
			template_id,
			template_name,
			order,
			missing_nodes,
			"Assign materials to: %s" % ", ".join(missing_nodes)
		)

	var first := _propagate_with_local_and_incoming(node_vectors, edges, ELEMENTS, DEFAULT_FIRST_PROPAGATION_RATE)
	var pair8_by_node := {}
	var pair16_by_node := {}
	var node_ids := node_vectors.keys()
	for node_id_variant in node_ids:
		var node_id := str(node_id_variant)
		var pair16 := _build_pair16(first["local"][node_id], first["incoming"][node_id])
		pair16_by_node[node_id] = pair16
		pair8_by_node[node_id] = _reduce_pair16_to_pair8(pair16)

	var second := _propagate_with_local_and_incoming(pair8_by_node, edges, PAIR8_IDS, DEFAULT_SECOND_PROPAGATION_RATE)
	var effect_ids := EFFECT_MAPPING.keys()
	var total_effect32 := _zero_vector(effect_ids)
	var effect32_by_node := {}
	for node_id_variant in node_ids:
		var node_id := str(node_id_variant)
		var quad64 := _build_quad64(second["local"][node_id], second["incoming"][node_id])
		var effect32 := _reduce_quad64_to_effect32(quad64)
		effect32_by_node[node_id] = effect32
		total_effect32 = _add_vectors(total_effect32, effect32, effect_ids)

	var interpretation := _interpret_effect_vector(total_effect32, order)
	var visible_effects: Array[Dictionary] = interpretation.get("visible_effects", [])
	var visible_effect_texts: Array[String] = []
	for effect_data in visible_effects:
		visible_effect_texts.append(str(effect_data.get("text", "")))
	var combat_payload := COMBAT_PAYLOAD_BUILDER.build_from_visible_effects(visible_effects)

	var waste_data: Dictionary = interpretation.get("waste", {})
	var hidden_effects: Array[Dictionary] = interpretation.get("hidden_effects", [])
	var latent_traits := _build_latent_traits(hidden_effects, order, circle_nodes.size(), edges.size(), waste_data)
	var card_name := _make_card_name(template_name, source_material_ids)
	var initial_mass := _sum_vector(initial_element_totals, ELEMENTS)
	var final_mass := _sum_vector(total_effect32, effect_ids)
	var debug_lines := [
		"Algorithm: first_order_magic_circle_v1",
		"Circle order %s | nodes %s | edges %s" % [order, circle_nodes.size(), edges.size()],
		"Mass %.2f -> %.2f (diff %.4f)" % [initial_mass, final_mass, final_mass - initial_mass],
		"Visible %s | Hidden %s | Waste %.2f" % [visible_effects.size(), hidden_effects.size(), float(waste_data.get("score", 0.0))],
	]
	for top_dimension in _top_dimensions(total_effect32, 4):
		debug_lines.append("%s %s" % [str(top_dimension.get("id", "")), str(top_dimension.get("value", 0.0))])

	var message := "First-order evaluation ready."
	if visible_effects.is_empty():
		message = "First-order evaluation resolved with unstable or hidden-heavy output."

	return {
		"valid": true,
		"can_generate": true,
		"message": message,
		"algorithm_id": "first_order_magic_circle_v1",
		"algorithm_stage": "effect32_interpreted",
		"circle_id": circle_id,
		"template_id": template_id,
		"template_name": template_name,
		"order": order,
		"source_material_ids": source_material_ids,
		"source_material_counts": source_material_counts,
		"element_vector4": initial_element_totals,
		"effect_vector32": total_effect32,
		"visible_effects": visible_effects,
		"visible_effect_texts": visible_effect_texts,
		"combat_payload": combat_payload,
		"hidden_effects": hidden_effects,
		"latent_traits": latent_traits,
		"waste_dimensions": waste_data.get("dimensions", []),
		"waste_score": float(waste_data.get("score", 0.0)),
		"mass": {
			"initial": initial_mass,
			"final": final_mass,
			"difference": final_mass - initial_mass,
			"conserved": abs(final_mass - initial_mass) < EPSILON,
		},
		"debug_lines": debug_lines,
		"debug_data": {
			"pair16_by_node": pair16_by_node,
			"pair8_by_node": pair8_by_node,
			"effect32_by_node": effect32_by_node,
			"top_dimensions": _top_dimensions(total_effect32, 8),
		},
		"card_preview": {
			"card_id": "%s_%s_preview" % [template_id, source_material_ids.size()],
			"card_name": card_name,
			"description": "First-order magic circle generated card.",
			"action_point_cost": _derive_action_point_cost(order, visible_effects),
			"single_use": true,
			"effect_lines": visible_effect_texts,
		},
	}

static func _build_invalid_result(
	circle_id: String,
	template_id: String,
	template_name: String,
	order: int,
	missing_nodes: Array[String],
	message: String
) -> Dictionary:
	return {
		"valid": false,
		"can_generate": false,
		"message": message,
		"algorithm_id": "first_order_magic_circle_v1",
		"algorithm_stage": "validation",
		"circle_id": circle_id,
		"template_id": template_id,
		"template_name": template_name,
		"order": order,
		"missing_node_ids": missing_nodes,
		"source_material_ids": [],
		"source_material_counts": {},
		"element_vector4": _zero_vector(ELEMENTS),
		"effect_vector32": _zero_vector(EFFECT_MAPPING.keys()),
		"visible_effects": [],
		"visible_effect_texts": [],
		"combat_payload": {"target": "none", "effects": []},
		"hidden_effects": [],
		"latent_traits": [],
		"waste_dimensions": [],
		"waste_score": 0.0,
		"mass": {"initial": 0.0, "final": 0.0, "difference": 0.0, "conserved": true},
		"debug_lines": ["Validation incomplete."],
		"debug_data": {},
		"card_preview": {},
	}

static func _zero_vector(dimensions: Array) -> Dictionary:
	var output := {}
	for dimension in dimensions:
		output[str(dimension)] = 0.0
	return output

static func _normalize_vector(raw: Dictionary, dimensions: Array) -> Dictionary:
	var output := {}
	for dimension in dimensions:
		output[str(dimension)] = float(raw.get(str(dimension), 0.0))
	return output

static func _add_vectors(left: Dictionary, right: Dictionary, dimensions: Array) -> Dictionary:
	var output := {}
	for dimension in dimensions:
		var dimension_id := str(dimension)
		output[dimension_id] = float(left.get(dimension_id, 0.0)) + float(right.get(dimension_id, 0.0))
	return output

static func _scale_vector(vector: Dictionary, scalar: float, dimensions: Array) -> Dictionary:
	var output := {}
	for dimension in dimensions:
		var dimension_id := str(dimension)
		output[dimension_id] = float(vector.get(dimension_id, 0.0)) * scalar
	return output

static func _sum_vector(vector: Dictionary, dimensions: Array) -> float:
	var total := 0.0
	for dimension in dimensions:
		total += float(vector.get(str(dimension), 0.0))
	return total

static func _normalize_by_signed_sum(vector: Dictionary, dimensions: Array) -> Dictionary:
	var total := _sum_vector(vector, dimensions)
	if abs(total) < EPSILON:
		return _zero_vector(dimensions)
	return _scale_vector(vector, 1.0 / total, dimensions)

static func _build_adjacency(node_ids: Array, edges: Array) -> Dictionary:
	var adjacency := {}
	for raw_node_id in node_ids:
		adjacency[str(raw_node_id)] = []
	for edge_variant in edges:
		var edge: Dictionary = edge_variant
		var start := str(edge.get("from", ""))
		var ending := str(edge.get("to", ""))
		var weight := float(edge.get("weight", 1.0))
		if not adjacency.has(start):
			adjacency[start] = []
		if not adjacency.has(ending):
			adjacency[ending] = []
		(adjacency[start] as Array).append({"node_id": ending, "weight": weight})
		(adjacency[ending] as Array).append({"node_id": start, "weight": weight})
	return adjacency

static func _propagate_with_local_and_incoming(node_vectors: Dictionary, edges: Array, dimensions: Array, rate: float) -> Dictionary:
	var node_ids := node_vectors.keys()
	var adjacency := _build_adjacency(node_ids, edges)
	var local := {}
	var incoming := {}

	for node_id_variant in node_ids:
		var node_id := str(node_id_variant)
		incoming[node_id] = _zero_vector(dimensions)

	for node_id_variant in node_ids:
		var node_id := str(node_id_variant)
		var vector: Dictionary = node_vectors[node_id]
		var neighbors: Array = adjacency.get(node_id, [])
		if neighbors.is_empty():
			local[node_id] = vector.duplicate(true)
			continue

		local[node_id] = _scale_vector(vector, 1.0 - rate, dimensions)
		var total_weight := 0.0
		for neighbor_variant in neighbors:
			total_weight += float((neighbor_variant as Dictionary).get("weight", 1.0))

		if abs(total_weight) < EPSILON:
			incoming[node_id] = _add_vectors(incoming[node_id], _scale_vector(vector, rate, dimensions), dimensions)
			continue

		for neighbor_variant in neighbors:
			var neighbor: Dictionary = neighbor_variant
			var neighbor_id := str(neighbor.get("node_id", ""))
			var weight := float(neighbor.get("weight", 1.0))
			var sent := _scale_vector(vector, rate * weight / total_weight, dimensions)
			incoming[neighbor_id] = _add_vectors(incoming[neighbor_id], sent, dimensions)

	var mixed := {}
	for node_id_variant in node_ids:
		var node_id := str(node_id_variant)
		mixed[node_id] = _add_vectors(local.get(node_id, _zero_vector(dimensions)), incoming[node_id], dimensions)
	return {"local": local, "incoming": incoming, "mixed": mixed}

static func _build_pair16(local4: Dictionary, incoming4: Dictionary) -> Dictionary:
	var total := _add_vectors(local4, incoming4, ELEMENTS)
	var mass := _sum_vector(total, ELEMENTS)
	var local_sum := _sum_vector(local4, ELEMENTS)
	var incoming_sum := _sum_vector(incoming4, ELEMENTS)
	var p := _normalize_by_signed_sum(local4 if abs(local_sum) >= EPSILON else total, ELEMENTS)
	var q := _normalize_by_signed_sum(incoming4 if abs(incoming_sum) >= EPSILON else p, ELEMENTS)
	var pair16 := {}
	for first in ELEMENTS:
		for second in ELEMENTS:
			pair16[_compose_key(first, second)] = mass * float(p.get(first, 0.0)) * float(q.get(second, 0.0))
	return pair16

static func _reduce_pair16_to_pair8(pair16: Dictionary) -> Dictionary:
	var pair8 := _zero_vector(PAIR8_IDS)
	for key_variant in pair16.keys():
		var key := str(key_variant)
		var value := float(pair16[key])
		var split := key.split(">")
		var first := split[0]
		var second := split[1]
		if first == second:
			pair8[PURE_PAIR_BY_ELEMENT[first]] = float(pair8[PURE_PAIR_BY_ELEMENT[first]]) + value
		elif _sorted_join([first, second]) == "fire|water":
			pair8["FF"] = float(pair8["FF"]) + value * 0.5
			pair8["WW"] = float(pair8["WW"]) + value * 0.5
		elif _sorted_join([first, second]) == "earth|wind":
			pair8["AA"] = float(pair8["AA"]) + value * 0.5
			pair8["EE"] = float(pair8["EE"]) + value * 0.5
		else:
			var pair_id: String = str(MIXED_PAIR_BY_ELEMENTS[_sorted_join([first, second])])
			pair8[pair_id] = float(pair8[pair_id]) + value
	return pair8

static func _build_quad64(local8: Dictionary, incoming8: Dictionary) -> Dictionary:
	var total := _add_vectors(local8, incoming8, PAIR8_IDS)
	var mass := _sum_vector(total, PAIR8_IDS)
	var local_sum := _sum_vector(local8, PAIR8_IDS)
	var incoming_sum := _sum_vector(incoming8, PAIR8_IDS)
	var p := _normalize_by_signed_sum(local8 if abs(local_sum) >= EPSILON else total, PAIR8_IDS)
	var q := _normalize_by_signed_sum(incoming8 if abs(incoming_sum) >= EPSILON else p, PAIR8_IDS)
	var quad64 := {}
	for first in PAIR8_IDS:
		for second in PAIR8_IDS:
			quad64[_compose_key(first, second)] = mass * float(p.get(first, 0.0)) * float(q.get(second, 0.0))
	return quad64

static func _reduce_quad64_to_effect32(quad64: Dictionary) -> Dictionary:
	var effect32 := _zero_vector(EFFECT_MAPPING.keys())
	var effect_lookup := _build_effect_lookup()
	for key_variant in quad64.keys():
		var key := str(key_variant)
		var split := key.split(">")
		var canonical_key := _canonical_pair_pair_key(split[0], split[1])
		var value := float(quad64[key])
		if FORBIDDEN_QUAD_TRANSFERS.has(canonical_key):
			for transfer_variant in FORBIDDEN_QUAD_TRANSFERS[canonical_key]:
				var transfer: Dictionary = transfer_variant
				var target_id := str(transfer.get("id", ""))
				var ratio := float(transfer.get("ratio", 0.0))
				effect32[target_id] = float(effect32[target_id]) + value * ratio
			continue
		var effect_id := str(effect_lookup.get(canonical_key, ""))
		if effect_id.is_empty():
			continue
		effect32[effect_id] = float(effect32[effect_id]) + value
	return effect32

static func _build_effect_lookup() -> Dictionary:
	var lookup := {}
	for effect_id_variant in EFFECT_MAPPING.keys():
		var effect_id := str(effect_id_variant)
		var data: Dictionary = EFFECT_MAPPING[effect_id]
		if str(data.get("type", "waste")) == "forbidden":
			continue
		var pairs: Array = data.get("pairs", [])
		if pairs.size() < 2:
			continue
		lookup[_canonical_pair_pair_key(str(pairs[0]), str(pairs[1]))] = effect_id
	return lookup

static func _interpret_effect_vector(effect32: Dictionary, order: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var hidden_effects: Array[Dictionary] = []
	var modifiers: Array[Dictionary] = []
	var waste_dimensions: Array[Dictionary] = []

	for effect_id_variant in EFFECT_MAPPING.keys():
		var effect_id := str(effect_id_variant)
		var data: Dictionary = EFFECT_MAPPING[effect_id]
		var coefficient := float(effect32.get(effect_id, 0.0))
		var effect_type := str(data.get("type", "waste"))

		if effect_type == "waste":
			if abs(coefficient) > EPSILON:
				waste_dimensions.append({"id": effect_id, "coefficient": snappedf(coefficient, 0.0001)})
			continue

		if not data.has("threshold"):
			continue
		var threshold := float(data.get("threshold", 0.0))
		var level := int(floor(abs(coefficient) / threshold))
		if level < 1:
			continue

		var sign := "positive" if coefficient >= 0.0 else "negative"
		var entry := {
			"id": effect_id,
			"dimension": str(data.get("dimension", "")),
			"type": effect_type,
			"coefficient": coefficient,
			"level": level,
			"sign": sign,
			"priority_score": abs(coefficient) / threshold,
			"priority_tier": int(data.get("priority_tier", 9)),
			"mapping": data,
		}

		if effect_type == "hidden" and order < DEFAULT_LATENT_ACTIVATION_MIN_ORDER:
			hidden_effects.append({
				"id": effect_id,
				"latent_id": str(data.get("latent_id", effect_id)),
				"level": level,
				"sign": sign,
				"coefficient": snappedf(coefficient, 0.0001),
				"description": str(data.get("positive" if sign == "positive" else "negative", "")),
			})
		elif effect_type.begins_with("modifier"):
			modifiers.append(entry)
		else:
			candidates.append(entry)

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["priority_score"]), float(b["priority_score"])):
			return float(a["priority_score"]) > float(b["priority_score"])
		if int(a["priority_tier"]) != int(b["priority_tier"]):
			return int(a["priority_tier"]) < int(b["priority_tier"])
		return str(a["id"]) < str(b["id"])
	)

	var selected: Array[Dictionary] = []
	for index in range(min(DEFAULT_MAX_VISIBLE_EFFECTS, candidates.size())):
		selected.append(candidates[index].duplicate(true))
	_apply_modifiers(selected, modifiers)

	var visible_effects: Array[Dictionary] = []
	for candidate in selected:
		visible_effects.append(_candidate_to_text(candidate))

	waste_dimensions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return abs(float(a["coefficient"])) > abs(float(b["coefficient"]))
	)
	var waste_score := 0.0
	for waste_dimension in waste_dimensions:
		waste_score += abs(float(waste_dimension.get("coefficient", 0.0)))

	return {
		"visible_effects": visible_effects,
		"hidden_effects": hidden_effects,
		"waste": {
			"score": snappedf(waste_score, 0.0001),
			"dimensions": waste_dimensions.slice(0, min(8, waste_dimensions.size())),
		},
		"modifiers": modifiers,
	}

static func _apply_modifiers(selected: Array[Dictionary], modifiers: Array[Dictionary]) -> void:
	var numeric_effects: Array[Dictionary] = []
	for candidate in selected:
		var mapping: Dictionary = candidate.get("mapping", {})
		if mapping.has("base_value"):
			numeric_effects.append(candidate)
	if numeric_effects.is_empty():
		return

	var target: Dictionary = numeric_effects[0]
	var additive := 0
	var multiplier := 1.0
	for modifier in modifiers:
		if str(modifier.get("type", "")) == "modifier_add":
			var delta := 2 * int(modifier.get("level", 0))
			additive += delta if str(modifier.get("sign", "positive")) == "positive" else -delta
		elif str(modifier.get("type", "")) == "modifier_multiply":
			if str(modifier.get("sign", "positive")) == "positive":
				multiplier *= 1.0 + 0.25 * int(modifier.get("level", 0))
			else:
				multiplier *= max(0.0, 1.0 - 0.20 * int(modifier.get("level", 0)))

	target["modifier_additive"] = additive
	target["modifier_multiplier"] = multiplier

static func _candidate_to_text(candidate: Dictionary) -> Dictionary:
	var mapping: Dictionary = candidate.get("mapping", {})
	var base_value := int(mapping.get("base_value", 1)) * int(candidate.get("level", 1))
	var additive := int(candidate.get("modifier_additive", 0))
	var multiplier := float(candidate.get("modifier_multiplier", 1.0))
	var final_value: int = max(0, int(floor((base_value + additive) * multiplier)))
	var template_key := "positive" if str(candidate.get("sign", "positive")) == "positive" else "negative"
	var text_template := str(mapping.get(template_key, "Effect {value}"))
	return {
		"dimension": str(candidate.get("id", "")),
		"text": text_template.format({"value": final_value}),
		"level": int(candidate.get("level", 1)),
		"coefficient": snappedf(float(candidate.get("coefficient", 0.0)), 0.0001),
		"base_value": base_value,
		"final_value": final_value,
		"sign": str(candidate.get("sign", "positive")),
	}

static func _build_latent_traits(hidden_effects: Array[Dictionary], order: int, node_count: int, edge_count: int, waste_data: Dictionary) -> Array[Dictionary]:
	var latent_traits: Array[Dictionary] = [
		{"trait_id": "circle_order", "strength": order},
		{"trait_id": "structure_density", "strength": edge_count - node_count + 1},
	]
	for hidden_effect in hidden_effects:
		latent_traits.append({
			"trait_id": str(hidden_effect.get("latent_id", hidden_effect.get("id", "latent"))),
			"strength": int(hidden_effect.get("level", 1)),
			"sign": str(hidden_effect.get("sign", "positive")),
		})
	var waste_score := float(waste_data.get("score", 0.0))
	if waste_score > 0.0:
		latent_traits.append({"trait_id": "instability", "strength": waste_score})
	return latent_traits

static func _top_dimensions(effect32: Dictionary, limit: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for effect_id_variant in EFFECT_MAPPING.keys():
		var effect_id := str(effect_id_variant)
		rows.append({
			"id": effect_id,
			"dimension": str(EFFECT_MAPPING[effect_id].get("dimension", "")),
			"type": str(EFFECT_MAPPING[effect_id].get("type", "waste")),
			"value": snappedf(float(effect32.get(effect_id, 0.0)), 0.0001),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return abs(float(a["value"])) > abs(float(b["value"]))
	)
	return rows.slice(0, min(limit, rows.size()))

static func _derive_action_point_cost(order: int, visible_effects: Array) -> int:
	return maxi(1, order + maxi(0, visible_effects.size() - 1))

static func _make_card_name(template_name: String, source_material_ids: Array[String]) -> String:
	var material_display := "Empty"
	if not source_material_ids.is_empty():
		var first_material := MagicMaterialCatalog.get_material(source_material_ids[0])
		material_display = str(first_material.get("display_name", str(source_material_ids[0]).replace("_", " ").capitalize()))
	return "%s %s Card" % [material_display, template_name]

static func _compose_key(first: String, second: String) -> String:
	return "%s>%s" % [first, second]

static func _canonical_pair_pair_key(first: String, second: String) -> String:
	if int(PAIR_ORDER[first]) <= int(PAIR_ORDER[second]):
		return "%s|%s" % [first, second]
	return "%s|%s" % [second, first]

static func _sorted_join(parts: Array[String]) -> String:
	var working: Array[String] = parts.duplicate()
	working.sort()
	return "|".join(working)
