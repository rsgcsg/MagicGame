extends PanelContainer

@onready var _label: Label = $Margin/Label
var _pending_entry: Dictionary = {}

func _ready() -> void:
	if not _pending_entry.is_empty():
		_apply_entry(_pending_entry)

func configure_from_entry(entry: Dictionary) -> void:
	_pending_entry = entry.duplicate(true)
	if not is_node_ready():
		return
	_apply_entry(_pending_entry)

func _apply_entry(entry: Dictionary) -> void:
	var badge_text := str(entry.get("badge_text", "Status"))
	_label.text = badge_text
	_label.tooltip_text = str(entry.get("tooltip_text", badge_text))
	tooltip_text = _label.tooltip_text
	modulate = entry.get("badge_modulate", Color.WHITE)
