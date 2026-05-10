extends PanelContainer

const MAGIC_MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var popup_title := "Expedition Summary"

@onready var _title_label: Label = $BackdropMargin/PopupPanel/InnerMargin/Layout/Header/TitleLabel
@onready var _subtitle_label: Label = $BackdropMargin/PopupPanel/InnerMargin/Layout/SubTitleLabel
@onready var _details_label: Label = $BackdropMargin/PopupPanel/InnerMargin/Layout/BodyScroll/DetailsLabel
@onready var _close_button: Button = $BackdropMargin/PopupPanel/InnerMargin/Layout/FooterRow/CloseButton

var _summary: Dictionary = {}

func _ready() -> void:
	_title_label.text = popup_title
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	_close_button.pressed.connect(_on_close_button_pressed)
	_refresh()

func _on_close_button_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func configure_summary(summary: Dictionary) -> void:
	_summary = summary.duplicate(true)
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	_subtitle_label.text = _build_subtitle()
	_subtitle_label.tooltip_text = _subtitle_label.text
	_details_label.text = _build_details_text()
	_details_label.tooltip_text = _details_label.text

func _build_subtitle() -> String:
	var end_reason := str(_summary.get("end_reason", "expedition_complete"))
	match end_reason:
		"battle_failure":
			return "The expedition ended in defeat. Surviving internal resources were returned to the workshop."
		"boss_cleared":
			return "The boss was defeated. Surviving internal resources were returned to the workshop."
		_:
			return "The expedition ended. Review what returned and what was lost."

func _build_details_text() -> String:
	var lines: Array[String] = []
	lines.append("Recovered Cards: %s" % int(_summary.get("recovered_card_count", 0)))
	lines.append("Lost Cards: %s" % int(_summary.get("lost_card_count", 0)))
	lines.append("Recovered Materials: %s" % _format_material_dictionary(_summary.get("recovered_materials", {})))
	lines.append("Reward Materials Gained: %s" % _format_material_dictionary(_summary.get("reward_materials", {})))
	lines.append("Spent Realm Materials: %s" % _format_material_dictionary(_summary.get("spent_materials", {})))
	lines.append("Reward Cards Added: %s" % int(_summary.get("reward_card_count", 0)))
	lines.append("Cards Crafted In Realm: %s" % int(_summary.get("crafted_card_count", 0)))
	return "\n".join(lines)

func _format_material_dictionary(materials: Variant) -> String:
	if materials is Dictionary:
		var parts: Array[String] = []
		for material_id in materials.keys():
			var amount := int(materials[material_id])
			if amount <= 0:
				continue
			var material_data := MAGIC_MATERIAL_CATALOG.get_material(str(material_id))
			var display_name := str(material_data.get("short_label", material_data.get("display_name", material_id)))
			parts.append("%s x%s" % [display_name, amount])
		if not parts.is_empty():
			return ", ".join(parts)
	return "None"
