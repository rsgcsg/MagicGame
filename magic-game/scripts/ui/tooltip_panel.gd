extends PanelContainer

@export var tooltip_text := "Tooltip"

func _ready() -> void:
	var label := Label.new()
	label.text = tooltip_text
	add_child(label)
