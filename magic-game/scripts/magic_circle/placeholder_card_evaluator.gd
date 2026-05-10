class_name PlaceholderCardEvaluator
extends RefCounted

const FIRST_ORDER_EVALUATOR := preload("res://scripts/magic_circle/first_order_card_evaluator.gd")

static func build_circle_input(template_id: String, template_data: Dictionary, node_assignments: Dictionary) -> Dictionary:
	var circle_nodes: Array[Dictionary] = []
	for raw_node_id in template_data.get("nodes", []):
		var node_id := str(raw_node_id)
		var payload := {}
		if node_assignments.has(node_id):
			var assignment: Dictionary = node_assignments[node_id]
			payload = {
				"type": "material",
				"material_id": str(assignment.get("material_id", "")),
				"vector4": assignment.get("vector", {}).duplicate(true),
			}
		circle_nodes.append({
			"id": node_id,
			"payload": payload,
		})

	return {
		"circle_id": "alchemy_%s_circle" % template_id,
		"template_id": template_id,
		"template_name": str(template_data.get("display_name", "Magic Circle")),
		"order": int(template_data.get("order", 1)),
		"nodes": circle_nodes,
		"edges": template_data.get("edges", []).duplicate(true),
	}

static func evaluate(template_id: String, template_data: Dictionary, node_assignments: Dictionary) -> Dictionary:
	return evaluate_circle(build_circle_input(template_id, template_data, node_assignments))

static func evaluate_circle(circle_input: Dictionary) -> Dictionary:
	return FIRST_ORDER_EVALUATOR.evaluate_circle(circle_input)
