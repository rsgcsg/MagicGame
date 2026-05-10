class_name AlchemyMaterialButton
extends Button

signal material_pressed(material_id: String)

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

var _material_id := ""
var _drag_preview_text := ""

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(self)
	pressed.connect(_on_pressed)

func configure_button(material_id: String, button_text: String, action_enabled: bool, tooltip: String) -> void:
	_material_id = material_id
	text = button_text
	disabled = not action_enabled
	tooltip_text = tooltip
	_drag_preview_text = button_text.split("\n")[0]

func _on_pressed() -> void:
	material_pressed.emit(_material_id)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or _material_id.is_empty():
		return null
	var preview_label := Label.new()
	preview_label.text = _drag_preview_text
	preview_label.modulate = Color(0.98, 0.92, 0.80, 0.96)
	preview_label.add_theme_font_size_override("font_size", 18)
	set_drag_preview(preview_label)
	return {
		"type": "alchemy_material",
		"material_id": _material_id,
	}
