extends PanelContainer

signal action_pressed(runtime_instance_id: String)

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var runtime_instance_id := ""
@export var card_name := "Generated Card"
@export_multiline var effect_summary := "Placeholder effect summary."
@export_multiline var meta_summary := "Placeholder source summary."
@export var action_text := "Add"
@export var action_enabled := true
@export var action_point_cost := 1
@export var single_use := true
@export var template_id := "triangle"
@export_multiline var card_body_text := "Generated card placeholder effect."

@onready var _card_view = $Margin/Layout/BodyRow/CardView
@onready var _name_label: Label = $Margin/Layout/BodyRow/InfoColumn/HeaderRow/NameLabel
@onready var _effect_label: Label = $Margin/Layout/BodyRow/InfoColumn/EffectLabel
@onready var _meta_label: Label = $Margin/Layout/BodyRow/InfoColumn/MetaLabel
@onready var _action_button: Button = $Margin/Layout/BodyRow/InfoColumn/HeaderRow/ActionButton

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_action_button)
	_action_button.pressed.connect(_on_action_button_pressed)
	_refresh()

func _refresh() -> void:
	_card_view.card_name = card_name
	_card_view.action_point_cost = action_point_cost
	_card_view.template_id = template_id
	_card_view.single_use = single_use
	_card_view.body_text = card_body_text
	_name_label.text = card_name
	_name_label.tooltip_text = card_name
	_effect_label.text = effect_summary
	_effect_label.tooltip_text = effect_summary
	_meta_label.text = meta_summary
	_meta_label.tooltip_text = meta_summary
	_action_button.visible = action_enabled
	_action_button.text = action_text

func _on_action_button_pressed() -> void:
	action_pressed.emit(runtime_instance_id)
