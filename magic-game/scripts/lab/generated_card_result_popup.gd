extends PanelContainer

const MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _close_button: Button = $Margin/WindowPanel/InnerMargin/Layout/Header/CloseButton
@onready var _card_view = $Margin/WindowPanel/InnerMargin/Layout/Body/LeftColumn/GeneratedCardView
@onready var _status_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Body/RightColumn/StatusLabel
@onready var _effect_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Body/RightColumn/EffectLabel
@onready var _source_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Body/RightColumn/SourceLabel

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	_close_button.pressed.connect(_on_close_pressed)
	_card_view.detail_click_enabled = false

func configure_popup(card: GeneratedCardData, evaluation: Dictionary, generated_scope_label: String) -> void:
	if card != null:
		_card_view.detail_click_enabled = false
		_card_view.configure_from_generated_card(card)
	_status_label.text = "Stored in %s" % generated_scope_label
	_status_label.tooltip_text = _status_label.text
	_effect_label.text = _build_effect_text(card, evaluation)
	_effect_label.tooltip_text = _effect_label.text
	_source_label.text = _build_source_text(card, evaluation)
	_source_label.tooltip_text = _source_label.text

func _on_close_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func _build_effect_text(card: GeneratedCardData, evaluation: Dictionary) -> String:
	var effect_lines: Array[String] = []
	if card != null and not card.effect_lines.is_empty():
		effect_lines.assign(card.effect_lines)
	elif evaluation.get("effect_lines", []) is Array:
		for effect_line in evaluation.get("effect_lines", []):
			effect_lines.append(str(effect_line))
	if effect_lines.is_empty():
		return "Effects: No visible effects recorded."
	return "Effects:\n- %s" % "\n- ".join(effect_lines)

func _build_source_text(card: GeneratedCardData, evaluation: Dictionary) -> String:
	var template_id := card.source_template_id if card != null else ""
	if template_id.is_empty():
		template_id = str(evaluation.get("template_id", "unknown"))
	var material_counts: Dictionary = card.source_material_counts.duplicate(true) if card != null else {}
	if material_counts.is_empty():
		material_counts = evaluation.get("source_material_counts", {}).duplicate(true) if evaluation.get("source_material_counts", {}) is Dictionary else {}
	var source_bits: Array[String] = []
	for material_id in material_counts.keys():
		var material_data := MATERIAL_CATALOG.get_material(str(material_id))
		var display_name := str(material_data.get("short_label", material_data.get("display_name", str(material_id))))
		source_bits.append("%s x%s" % [display_name, int(material_counts[material_id])])
	source_bits.sort()
	return "Template: %s\nMaterials: %s" % [
		template_id,
		", ".join(source_bits) if not source_bits.is_empty() else "None",
	]
