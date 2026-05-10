class_name AlchemyTemplateButton
extends Button

signal template_pressed(template_id: String)

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

var _template_id := ""

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(self)
	pressed.connect(_on_pressed)

func configure_button(template_data: Dictionary, selected: bool) -> void:
	_template_id = str(template_data.get("template_id", ""))
	text = str(template_data.get("display_name", _template_id))
	tooltip_text = str(template_data.get("summary", "Magic circle template"))
	disabled = selected

func _on_pressed() -> void:
	template_pressed.emit(_template_id)
