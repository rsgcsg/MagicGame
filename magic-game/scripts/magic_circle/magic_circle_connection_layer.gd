class_name MagicCircleConnectionLayer
extends Control

const LINE_COLOR := Color(0.82, 0.68, 1.0, 0.78)
const LINE_WIDTH := 3.0

var _node_layer: Control
var _node_slots: Array[Button] = []
var _active_node_ids: Array[String] = []
var _edges: Array = []

func set_connection_data(node_layer: Control, node_slots: Array[Button], active_node_ids: Array[String], edges: Array) -> void:
	_node_layer = node_layer
	_node_slots = node_slots
	_active_node_ids = active_node_ids.duplicate()
	_edges = edges.duplicate(true)
	queue_redraw()

func _draw() -> void:
	if _node_layer == null:
		return

	for edge_data in _edges:
		if not (edge_data is Dictionary):
			continue

		var from_node_id := str(edge_data.get("from", ""))
		var to_node_id := str(edge_data.get("to", ""))
		var from_slot := _get_slot_for_node_id(from_node_id)
		var to_slot := _get_slot_for_node_id(to_node_id)
		if from_slot == null or to_slot == null:
			continue

		draw_line(_slot_center(from_slot), _slot_center(to_slot), LINE_COLOR, LINE_WIDTH, true)

func _get_slot_for_node_id(target_node_id: String) -> Button:
	var node_index := _active_node_ids.find(target_node_id)
	if node_index < 0 or node_index >= _node_slots.size():
		return null

	var slot_button := _node_slots[node_index]
	if not slot_button.visible:
		return null

	return slot_button

func _slot_center(slot_button: Button) -> Vector2:
	var global_center := slot_button.get_global_rect().get_center()
	return get_global_transform().affine_inverse() * global_center
