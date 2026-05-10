extends PanelContainer

const DEFAULT_BODY_TEXT := "Generated card placeholder effect."
const GENERATED_CARD_DETAIL_POPUP_SCENE := preload("res://scenes/ui/generated_card_detail_popup.tscn")

const COMPACT_CARD_SIZE := Vector2(124, 164)
const COMPACT_ART_HEIGHT := 70
const COMPACT_DESCRIPTION_HEIGHT := 78
const COMPACT_COST_FONT_SIZE := 16
const COMPACT_EFFECT_FONT_SIZE := 11

const FULL_CARD_SIZE := Vector2(152, 232)
const FULL_ART_HEIGHT := 96
const FULL_DESCRIPTION_HEIGHT := 112
const FULL_COST_FONT_SIZE := 17
const FULL_EFFECT_FONT_SIZE := 12

@export var card_name := "Generated Card":
	set(value):
		card_name = value
		_refresh_if_ready()

@export var action_point_cost := 1:
	set(value):
		action_point_cost = value
		_refresh_if_ready()

@export_multiline var body_text := DEFAULT_BODY_TEXT:
	set(value):
		body_text = value
		_refresh_if_ready()

@export var template_id := "triangle":
	set(value):
		template_id = value
		_refresh_if_ready()

@export var single_use := true:
	set(value):
		single_use = value
		_refresh_if_ready()

@export var compact_mode := false:
	set(value):
		compact_mode = value
		_refresh_if_ready()

@export var detail_click_enabled := true

@onready var _cost_label: Label = $Margin/Layout/ArtPanel/CostBadge/CostMargin/CostLabel
@onready var _art_panel: Panel = $Margin/Layout/ArtPanel
@onready var _art_preview = $Margin/Layout/ArtPanel/MagicCircleArtPreview
@onready var _description_panel: PanelContainer = $Margin/Layout/DescriptionPanel
@onready var _effect_text: RichTextLabel = $Margin/Layout/DescriptionPanel/DescriptionMargin/EffectText

var _bound_generated_card: GeneratedCardData = null

func _ready() -> void:
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if not detail_click_enabled or _bound_generated_card == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_flash_click_feedback()
		SceneManager.play_ui_button_click()
		_open_detail_popup()
		accept_event()

func configure_from_generated_card(card: GeneratedCardData) -> void:
	if card == null:
		return
	_bound_generated_card = card
	card_name = card.display_name
	action_point_cost = card.action_point_cost
	template_id = card.source_template_id if not card.source_template_id.is_empty() else "triangle"
	single_use = card.single_use
	body_text = _build_card_body_text(card, compact_mode)
	if is_node_ready():
		_refresh()

func configure_from_battle_card(card_data: Dictionary) -> void:
	_bound_generated_card = null
	card_name = str(card_data.get("name", "Card"))
	action_point_cost = int(card_data.get("cost", 0))
	template_id = str(card_data.get("template_id", "triangle"))
	single_use = bool(card_data.get("consumable", true))
	body_text = str(card_data.get("effect_text", DEFAULT_BODY_TEXT))
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	if compact_mode:
		custom_minimum_size = COMPACT_CARD_SIZE
		_art_panel.custom_minimum_size = Vector2(0, COMPACT_ART_HEIGHT)
		_description_panel.custom_minimum_size = Vector2(0, COMPACT_DESCRIPTION_HEIGHT)
		_cost_label.add_theme_font_size_override("font_size", COMPACT_COST_FONT_SIZE)
		_effect_text.add_theme_font_size_override("normal_font_size", COMPACT_EFFECT_FONT_SIZE)
	else:
		custom_minimum_size = FULL_CARD_SIZE
		_art_panel.custom_minimum_size = Vector2(0, FULL_ART_HEIGHT)
		_description_panel.custom_minimum_size = Vector2(0, FULL_DESCRIPTION_HEIGHT)
		_cost_label.add_theme_font_size_override("font_size", FULL_COST_FONT_SIZE)
		_effect_text.add_theme_font_size_override("normal_font_size", FULL_EFFECT_FONT_SIZE)
	_cost_label.text = str(action_point_cost)
	tooltip_text = card_name
	_effect_text.text = body_text
	_effect_text.tooltip_text = body_text
	_art_preview.template_id = template_id

func _build_card_body_text(card: GeneratedCardData, force_compact := false) -> String:
	var lines: Array[String] = []
	if not card.effect_lines.is_empty():
		if force_compact:
			lines.append(str(card.effect_lines[0]))
		else:
			lines.append("\n".join(card.effect_lines))
	if not card.description.is_empty():
		lines.append(card.description)
	if lines.is_empty():
		lines.append(DEFAULT_BODY_TEXT)
	return "\n\n".join(lines)

func _refresh_if_ready() -> void:
	if is_node_ready():
		_refresh()

func _open_detail_popup() -> void:
	var popup = GENERATED_CARD_DETAIL_POPUP_SCENE.instantiate()
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	host.add_child(popup)
	popup.call("configure_for_generated_card", _bound_generated_card)

func _flash_click_feedback() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.05)
	tween.parallel().tween_property(self, "modulate", Color(1.08, 1.0, 0.84, 1.0), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.08)
