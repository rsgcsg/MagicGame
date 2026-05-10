extends PanelContainer

signal play_requested(instance_id: String)
signal discard_requested(instance_id: String)

@export var instance_id := ""

@export var card_name := "Spark":
	set(value):
		card_name = value
		if is_node_ready():
			_refresh()

@export var cost := 1:
	set(value):
		cost = value
		if is_node_ready():
			_refresh()

@export_multiline var effect_text := "Card effect.":
	set(value):
		effect_text = value
		if is_node_ready():
			_refresh()

@export var template_id := "triangle":
	set(value):
		template_id = value
		if is_node_ready():
			_refresh()

@onready var _cost_label: Label = $Margin/Layout/ArtPanel/CostBadge/CostMargin/CostLabel
@onready var _art_preview = $Margin/Layout/ArtPanel/MagicCircleArtPreview
@onready var _effect_text: RichTextLabel = $Margin/Layout/DescriptionPanel/DescriptionMargin/EffectText

func _ready() -> void:
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_flash_click_feedback()
		play_requested.emit(instance_id)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_flash_click_feedback()
		discard_requested.emit(instance_id)
		accept_event()

func _refresh() -> void:
	_cost_label.text = str(cost)
	_art_preview.template_id = template_id
	tooltip_text = card_name
	_effect_text.text = effect_text
	_effect_text.tooltip_text = effect_text

func _flash_click_feedback() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.parallel().tween_property(self, "modulate", Color(1.08, 1.0, 0.84, 1.0), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.08)
