extends PanelContainer

signal node_selected(node_id: String)
signal node_clear_requested(node_id: String)
signal material_drop_requested(node_id: String, material_id: String)

@onready var template_title_label: Label = $EditorMargin/EditorLayout/Header/TemplateTitleLabel
@onready var editor_state_label: Label = $EditorMargin/EditorLayout/Header/EditorStateLabel
@onready var node_layer: Control = $EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer
@onready var connection_layer: Control = $EditorMargin/EditorLayout/GraphArea/GraphCanvas/ConnectionLayer
@onready var connection_hint_label: Label = $EditorMargin/EditorLayout/GraphArea/GraphCanvas/ConnectionLayer/ConnectionHintLabel
@onready var selected_node_label: Label = $EditorMargin/EditorLayout/Footer/SelectedNodeLabel
@onready var clear_node_button: Button = $EditorMargin/EditorLayout/Footer/ClearNodeButton
@onready var graph_canvas: Control = $EditorMargin/EditorLayout/GraphArea/GraphCanvas

@onready var _node_slots: Array[Button] = [
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeA,
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeB,
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeC,
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeD,
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeE,
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeF,
	$EditorMargin/EditorLayout/GraphArea/GraphCanvas/NodeLayer/NodeG,
]

var _active_node_ids: Array[String] = []
var _active_edges: Array = []
var _node_layout := {}
var _selected_node_id := ""
var _assignments := {}

func _ready() -> void:
	for slot_button in _node_slots:
		slot_button.slot_selected.connect(_on_slot_selected)
		slot_button.material_dropped.connect(_on_slot_material_dropped)
	if not graph_canvas.resized.is_connected(_refresh_slots):
		graph_canvas.resized.connect(_refresh_slots)
	connection_hint_label.visible = false
	clear_node_button.disabled = true
	clear_node_button.pressed.connect(_on_clear_node_pressed)

func load_template(template_data: Dictionary, assignments: Dictionary, selected_node_id := "") -> void:
	template_title_label.text = str(template_data.get("display_name", "Magic Circle"))
	editor_state_label.text = str(template_data.get("summary", "Ready"))
	_active_node_ids.assign(template_data.get("nodes", []))
	_active_edges = template_data.get("edges", []).duplicate(true)
	_node_layout = template_data.get("node_layout", {}).duplicate(true)
	_selected_node_id = selected_node_id
	_assignments = assignments.duplicate(true)
	_refresh_slots()

func set_assignments(assignments: Dictionary, selected_node_id := "") -> void:
	_assignments = assignments.duplicate(true)
	if not selected_node_id.is_empty():
		_selected_node_id = selected_node_id
	_refresh_slots()

func get_selected_node_id() -> String:
	return _selected_node_id

func _on_slot_selected(selected_id: String) -> void:
	if not _active_node_ids.has(selected_id):
		return
	_selected_node_id = selected_id
	node_selected.emit(selected_id)
	_refresh_slots()

func _on_clear_node_pressed() -> void:
	if _selected_node_id.is_empty():
		return
	node_clear_requested.emit(_selected_node_id)

func _on_slot_material_dropped(node_id: String, material_id: String) -> void:
	if not _active_node_ids.has(node_id):
		return
	_selected_node_id = node_id
	material_drop_requested.emit(node_id, material_id)
	_refresh_slots()

func _refresh_slots() -> void:
	for slot_index in range(_node_slots.size()):
		var slot_button := _node_slots[slot_index]
		if slot_index >= _active_node_ids.size():
			slot_button.visible = false
			continue

		var node_id := _active_node_ids[slot_index]
		var assignment = _assignments.get(node_id, {})
		var material_label := ""
		if assignment is Dictionary:
			material_label = str(assignment.get("short_label", assignment.get("display_name", "")))
		slot_button.visible = true
		slot_button.set_slot_state(node_id, material_label, node_id == _selected_node_id)
		_apply_slot_layout(slot_button, node_id)

	if _selected_node_id.is_empty():
		selected_node_label.text = "No node selected"
		clear_node_button.disabled = true
	else:
		selected_node_label.text = "Selected: %s" % _selected_node_id
		clear_node_button.disabled = false

	connection_layer.set_connection_data(node_layer, _node_slots, _active_node_ids, _active_edges)

func _apply_slot_layout(slot_button: Button, node_id: String) -> void:
	var relative_position: Vector2 = _node_layout.get(node_id, Vector2.ZERO)
	var slot_size := slot_button.custom_minimum_size
	if slot_size == Vector2.ZERO:
		slot_size = Vector2(72, 72)
	slot_button.size = slot_size
	slot_button.position = (graph_canvas.size * 0.5) + relative_position - (slot_size * 0.5)
