extends Button

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var card_name := "Card"
@export_range(12, 48) var visible_name_character_limit := 24

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(self)
	text = _compact_card_name(card_name)
	tooltip_text = card_name

func _compact_card_name(full_name: String) -> String:
	if full_name.length() <= visible_name_character_limit:
		return full_name
	return "%s..." % full_name.substr(0, visible_name_character_limit - 3)
