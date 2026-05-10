extends Button

signal slot_selected(node_id: String)
signal material_dropped(node_id: String, material_id: String)

@export var node_id := ""

var _material_label := ""
var _selected := false
var _drop_hover := false

func _ready() -> void:
	pressed.connect(_on_pressed)
	_refresh()

func set_slot_state(display_node_id: String, material_label: String, selected: bool) -> void:
	node_id = display_node_id
	_material_label = material_label
	_selected = selected
	_refresh()

func _on_pressed() -> void:
	slot_selected.emit(node_id)

func _refresh() -> void:
	var node_title := node_id if not node_id.is_empty() else "Node"
	var payload_text := _material_label if not _material_label.is_empty() else "+"
	text = "%s\n%s" % [node_title, payload_text]
	tooltip_text = "Selected circle node" if _selected else "Circle node slot"
	if _drop_hover:
		modulate = Color(1.08, 1.18, 0.92, 1)
	elif _selected:
		modulate = Color(1.18, 1.08, 0.74, 1)
	elif _material_label.is_empty():
		modulate = Color(0.9, 0.86, 1.0, 1)
	else:
		modulate = Color(0.78, 1.04, 0.86, 1)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var is_valid := data is Dictionary and str(data.get("type", "")) == "alchemy_material" and not str(data.get("material_id", "")).is_empty()
	if _drop_hover != is_valid:
		_drop_hover = is_valid
		_refresh()
	return is_valid

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_drop_hover = false
	_refresh()
	if not (data is Dictionary):
		return
	var material_id := str(data.get("material_id", ""))
	if material_id.is_empty():
		return
	slot_selected.emit(node_id)
	material_dropped.emit(node_id, material_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _drop_hover:
		_drop_hover = false
		_refresh()
