extends PanelContainer

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var primary_text := ""
@export var secondary_text := ""
@export var arrow_text := ">"
@export var arrow_on_left := true

@onready var _icon_row: HBoxContainer = $Margin/Layout/IconRow
@onready var _arrow_label: Label = $Margin/Layout/IconRow/ArrowLabel
@onready var _secondary_label: Label = $Margin/Layout/IconRow/SecondaryLabel
@onready var _primary_label: Label = $Margin/Layout/PrimaryLabel
@onready var _button: Button = $Button

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_button, self)
	_refresh()

func _refresh() -> void:
	_primary_label.text = primary_text
	_secondary_label.text = secondary_text
	_arrow_label.text = arrow_text

	if arrow_on_left:
		_icon_row.move_child(_arrow_label, 0)
		_icon_row.move_child(_secondary_label, 1)
	else:
		_icon_row.move_child(_secondary_label, 0)
		_icon_row.move_child(_arrow_label, 1)
