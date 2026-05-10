extends Button

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var material_id := ""
@export var full_material_name := ""
@export var quantity := 0

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(self)
	_refresh()

func _refresh() -> void:
	var display_name := material_id if not material_id.is_empty() else "Material"
	text = "%s\nx%s" % [display_name, quantity]
	tooltip_text = "%s x%s" % [_get_tooltip_name(display_name), quantity]

func _get_tooltip_name(fallback_name: String) -> String:
	if not full_material_name.is_empty():
		return full_material_name
	return fallback_name
