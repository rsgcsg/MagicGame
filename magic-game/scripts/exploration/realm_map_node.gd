extends PanelContainer

@export var label_text := "Node":
	set(value):
		label_text = value
		if is_node_ready():
			_title_label.text = label_text

@export var icon_text := "*":
	set(value):
		icon_text = value
		if is_node_ready():
			_icon_label.text = icon_text

@export var state_text := "State":
	set(value):
		state_text = value
		if is_node_ready():
			_state_label.text = state_text

@onready var _icon_label: Label = $Margin/Layout/IconLabel
@onready var _title_label: Label = $Margin/Layout/TitleLabel
@onready var _state_label: Label = $Margin/Layout/StateLabel

func _ready() -> void:
	_icon_label.text = icon_text
	_title_label.text = label_text
	_state_label.text = state_text
