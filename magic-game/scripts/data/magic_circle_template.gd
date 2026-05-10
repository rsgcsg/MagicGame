class_name MagicCircleTemplate
extends Resource

@export var sort_order := 0
@export var template_id := ""
@export var display_name := ""
@export_multiline var summary := ""
@export var available_in_lab := true
@export var circle_order := 1
@export var node_positions: Array[Vector2] = []
@export var edge_pairs: Array[String] = []
@export var bonus_tags: Array[String] = []
@export var default_action_point_cost := 1

func to_catalog_entry() -> Dictionary:
	var node_ids: Array[String] = []
	var node_layout := {}
	var default_node_ids: Array[String] = ["A", "B", "C", "D", "E", "F", "G", "H"]
	for index in range(node_positions.size()):
		var node_id: String = default_node_ids[index] if index < default_node_ids.size() else "N%s" % index
		node_ids.append(node_id)
		node_layout[node_id] = node_positions[index]

	var parsed_edges: Array[Dictionary] = []
	for raw_pair in edge_pairs:
		var pair := str(raw_pair)
		var parts := pair.split(":")
		if parts.size() != 2:
			continue
		parsed_edges.append({
			"from": str(parts[0]),
			"to": str(parts[1]),
		})

	return {
		"template_id": template_id,
		"display_name": display_name,
		"summary": summary,
		"available_in_lab": available_in_lab,
		"sort_order": sort_order,
		"order": circle_order,
		"nodes": node_ids,
		"node_layout": node_layout,
		"edges": parsed_edges,
		"bonus_tags": bonus_tags.duplicate(),
		"default_action_point_cost": default_action_point_cost,
	}
