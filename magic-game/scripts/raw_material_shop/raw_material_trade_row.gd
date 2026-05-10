extends PanelContainer

signal action_pressed(material_id: String)

const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

var _material_id := ""
var _pending_config: Dictionary = {}

@onready var _name_label: Label = $Margin/Layout/MainRow/NameLabel
@onready var _detail_label: Label = $Margin/Layout/DetailLabel
@onready var _price_label: Label = $Margin/Layout/MainRow/PriceLabel
@onready var _stock_label: Label = $Margin/Layout/MainRow/StockLabel
@onready var _action_button: Button = $Margin/Layout/MainRow/ActionButton

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_action_button)
	_action_button.pressed.connect(_on_action_button_pressed)
	if not _pending_config.is_empty():
		_apply_config(_pending_config)
		_pending_config.clear()

func configure_row(material_id: String, display_name: String, detail_text: String, price_text: String, stock_text: String, action_text: String, action_enabled: bool, tooltip: String) -> void:
	var config := {
		"material_id": material_id,
		"display_name": display_name,
		"detail_text": detail_text,
		"price_text": price_text,
		"stock_text": stock_text,
		"action_text": action_text,
		"action_enabled": action_enabled,
		"tooltip": tooltip,
	}
	if _name_label == null:
		_pending_config = config
		return
	_apply_config(config)

func _apply_config(config: Dictionary) -> void:
	_material_id = str(config.get("material_id", ""))
	var tooltip := str(config.get("tooltip", ""))
	_name_label.text = str(config.get("display_name", ""))
	_name_label.tooltip_text = tooltip
	_detail_label.text = str(config.get("detail_text", ""))
	_detail_label.tooltip_text = tooltip
	_price_label.text = str(config.get("price_text", ""))
	_stock_label.text = str(config.get("stock_text", ""))
	_action_button.text = str(config.get("action_text", ""))
	_action_button.disabled = not bool(config.get("action_enabled", false))
	tooltip_text = tooltip

func _on_action_button_pressed() -> void:
	action_pressed.emit(_material_id)
