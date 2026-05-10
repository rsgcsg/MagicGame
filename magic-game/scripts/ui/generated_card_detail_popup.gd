extends Control

const MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")
const GENERATED_CARD_VIEW_SCENE_PATH := "res://scenes/ui/generated_card_view.tscn"

@onready var _backdrop: ColorRect = $Backdrop
@onready var _window_panel: PanelContainer = $Margin/WindowPanel
@onready var _title_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Header/TitleLabel
@onready var _close_button: Button = $Margin/WindowPanel/InnerMargin/Layout/Header/CloseButton
@onready var _card_mount: CenterContainer = $Margin/WindowPanel/InnerMargin/Layout/Body/LeftColumn/CardMount
@onready var _meta_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Body/RightColumn/MetaLabel
@onready var _effect_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Body/RightColumn/EffectLabel
@onready var _source_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Body/RightColumn/SourceLabel

var _card_view = null
var _pending_card: GeneratedCardData = null

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	_close_button.pressed.connect(_close_popup)
	_backdrop.gui_input.connect(_on_backdrop_gui_input)
	_ensure_card_view()
	if _pending_card != null:
		_apply_card(_pending_card)

func configure_for_generated_card(card: GeneratedCardData) -> void:
	if card == null:
		return
	_pending_card = card
	if not is_node_ready():
		return
	_apply_card(card)

func _apply_card(card: GeneratedCardData) -> void:
	_ensure_card_view()
	if _card_view == null:
		return
	_title_label.text = card.display_name
	_title_label.tooltip_text = card.display_name
	_card_view.compact_mode = false
	_card_view.detail_click_enabled = false
	_card_view.configure_from_generated_card(card)
	_meta_label.text = _build_meta_text(card)
	_meta_label.tooltip_text = _meta_label.text
	_effect_label.text = _build_effect_text(card)
	_effect_label.tooltip_text = _effect_label.text
	_source_label.text = _build_source_text(card)
	_source_label.tooltip_text = _source_label.text

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_popup()
		accept_event()

func _close_popup() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func _ensure_card_view() -> void:
	if _card_view != null:
		return
	var generated_card_view_scene := load(GENERATED_CARD_VIEW_SCENE_PATH) as PackedScene
	if generated_card_view_scene == null:
		push_error("Failed to load generated card view scene for detail popup.")
		return
	_card_view = generated_card_view_scene.instantiate()
	if _card_view == null:
		push_error("Failed to instantiate generated card view scene for detail popup.")
		return
	_card_view.detail_click_enabled = false
	_card_mount.add_child(_card_view)

func _build_meta_text(card: GeneratedCardData) -> String:
	return "Cost: %s action points\nSingle Use: %s\nTemplate: %s" % [
		card.action_point_cost,
		"Yes" if card.single_use else "No",
		card.source_template_id if not card.source_template_id.is_empty() else "unknown",
	]

func _build_effect_text(card: GeneratedCardData) -> String:
	var lines: Array[String] = []
	if not card.effect_lines.is_empty():
		lines.append("Effects:\n- %s" % "\n- ".join(card.effect_lines))
	if not card.description.is_empty():
		lines.append("Description:\n%s" % card.description)
	if lines.is_empty():
		lines.append("Effects: No visible effects recorded.")
	return "\n\n".join(lines)

func _build_source_text(card: GeneratedCardData) -> String:
	var source_bits: Array[String] = []
	for material_id in card.source_material_counts.keys():
		var material_data := MATERIAL_CATALOG.get_material(str(material_id))
		var display_name := str(material_data.get("short_label", material_data.get("display_name", str(material_id))))
		source_bits.append("%s x%s" % [display_name, int(card.source_material_counts[material_id])])
	source_bits.sort()
	return "Source Materials:\n%s" % [
		"\n".join(source_bits) if not source_bits.is_empty() else "None",
	]
