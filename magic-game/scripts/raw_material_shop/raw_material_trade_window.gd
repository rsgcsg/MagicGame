extends PanelContainer

const SHOP_SERVICE := preload("res://scripts/raw_material_shop/raw_material_shop_service.gd")
const TRADE_ROW_SCENE := preload("res://scenes/raw_material_shop/raw_material_trade_row.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _buy_tab: Button = $Margin/WindowPanel/InnerMargin/Layout/ButtonRow/BuyTab
@onready var _sell_tab: Button = $Margin/WindowPanel/InnerMargin/Layout/ButtonRow/SellTab
@onready var _exit_button: Button = $Margin/WindowPanel/InnerMargin/Layout/ButtonRow/ExitButton
@onready var _gold_label: Label = $Margin/WindowPanel/InnerMargin/Layout/Header/GoldLabel
@onready var _body_title_label: Label = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/BodyTitleLabel
@onready var _summary_label: Label = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/SummaryLabel
@onready var _buy_view: VBoxContainer = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/BuyView
@onready var _sell_view: VBoxContainer = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/SellView
@onready var _buy_list: VBoxContainer = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/BuyView/BuyScroll/BuyList
@onready var _sell_list: VBoxContainer = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/SellView/SellScroll/SellList
@onready var _buy_empty_label: Label = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/BuyView/BuyEmptyLabel
@onready var _sell_empty_label: Label = $Margin/WindowPanel/InnerMargin/Layout/BodyPanel/BodyMargin/BodyLayout/SellView/SellEmptyLabel
@onready var _status_label: Label = $Margin/WindowPanel/InnerMargin/Layout/StatusLabel
@onready var _inventory_manager = get_node_or_null("/root/InventoryManager")
@onready var _game_manager = get_node_or_null("/root/GameManager")

var _current_mode := "buy"
var _stock_lookup: Dictionary = {}

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_buy_tab)
	UI_BUTTON_FEEDBACK.wire_button(_sell_tab)
	UI_BUTTON_FEEDBACK.wire_button(_exit_button)
	_buy_tab.pressed.connect(_show_buy_view)
	_sell_tab.pressed.connect(_show_sell_view)
	_exit_button.pressed.connect(_on_exit_pressed)
	if _inventory_manager != null and _inventory_manager.has_signal("materials_changed"):
		_inventory_manager.materials_changed.connect(_refresh_view)
	if _game_manager != null and _game_manager.has_signal("profile_changed"):
		_game_manager.profile_changed.connect(_refresh_view)
	_load_shop_stock()
	_set_mode("buy", false)

func _show_buy_view() -> void:
	_set_mode("buy", true)

func _show_sell_view() -> void:
	_set_mode("sell", true)

func _on_exit_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func _load_shop_stock() -> void:
	_stock_lookup = SHOP_SERVICE.build_stock_lookup(SHOP_SERVICE.load_stock_entries())

func _set_mode(mode: String, play_sound: bool) -> void:
	if play_sound:
		SceneManager.play_ui_button_click()
	_current_mode = mode
	_body_title_label.text = "Buy Materials" if mode == "buy" else "Sell Materials"
	_buy_view.visible = mode == "buy"
	_sell_view.visible = mode == "sell"
	_refresh_view()

func _refresh_view() -> void:
	_refresh_gold_label()
	_refresh_buy_rows()
	_refresh_sell_rows()
	_update_tab_states()
	_refresh_summary()

func _refresh_gold_label() -> void:
	var gold: int = int(_game_manager.get("gold")) if _game_manager != null else 0
	_gold_label.text = "Gold %s" % gold

func _refresh_summary() -> void:
	if _current_mode == "buy":
		_summary_label.text = "Buy one unit at a time. Common reagents are cheap; hybrids and unstable stock cost more."
	else:
		_summary_label.text = "Sell one unit at a time. You can only sell materials currently stored in the workshop material bag."
	_summary_label.tooltip_text = _summary_label.text

func _refresh_buy_rows() -> void:
	for child in _buy_list.get_children():
		child.queue_free()

	var has_rows := false
	for entry_data in SHOP_SERVICE.load_stock_entries():
		var material_id := str(entry_data.get("material_id", ""))
		var entry: Dictionary = _stock_lookup.get(material_id, {})
		if entry.is_empty():
			continue
		has_rows = true
		var owned: int = int(_inventory_manager.call("get_material_count", material_id)) if _inventory_manager != null and _inventory_manager.has_method("get_material_count") else 0
		var can_afford: bool = false
		if _game_manager != null and _game_manager.has_method("can_afford_gold"):
			can_afford = bool(_game_manager.call("can_afford_gold", int(entry.get("buy_price", 0))))
		var action_enabled := int(entry.get("stock", 0)) > 0 and bool(can_afford)
		var row = TRADE_ROW_SCENE.instantiate()
		_buy_list.add_child(row)
		row.configure_row(
			material_id,
			str(entry.get("display_name", material_id)),
			"%s | %s | %s" % [entry.get("rarity", "Common"), entry.get("stability", "Stable"), entry.get("vector_summary", "")],
			"Buy %sg" % int(entry.get("buy_price", 0)),
			"Stock %s | Owned %s" % [int(entry.get("stock", 0)), owned],
			"Buy 1",
			action_enabled,
			_build_material_tooltip(entry)
		)
		row.action_pressed.connect(_on_buy_row_pressed)
	_buy_empty_label.visible = not has_rows

func _refresh_sell_rows() -> void:
	for child in _sell_list.get_children():
		child.queue_free()

	var has_rows := false
	for material_id in SHOP_SERVICE.list_sellable_material_ids(_stock_lookup, _inventory_manager):
		var entry := SHOP_SERVICE.build_sell_entry(material_id, _stock_lookup, _inventory_manager)
		has_rows = true
		var owned := int(entry.get("owned", 0))
		var row = TRADE_ROW_SCENE.instantiate()
		_sell_list.add_child(row)
		row.configure_row(
			material_id,
			str(entry.get("display_name", material_id)),
			"%s | %s | %s" % [entry.get("rarity", "Common"), entry.get("stability", "Stable"), entry.get("vector_summary", "")],
			"Sell %sg" % int(entry.get("sell_price", 0)),
			"Owned %s | Shop %s" % [owned, int(entry.get("stock", 0))],
			"Sell 1",
			owned > 0,
			_build_material_tooltip(entry)
		)
		row.action_pressed.connect(_on_sell_row_pressed)
	_sell_empty_label.visible = not has_rows

func _update_tab_states() -> void:
	_buy_tab.disabled = _current_mode == "buy"
	_sell_tab.disabled = _current_mode == "sell"

func _build_material_tooltip(entry: Dictionary) -> String:
	return "%s\n%s\n%s | %s\nBuy %sg | Sell %sg" % [
		str(entry.get("display_name", "")),
		str(entry.get("descriptor", "")),
		str(entry.get("rarity", "Common")),
		str(entry.get("vector_summary", "")),
		int(entry.get("buy_price", 0)),
		int(entry.get("sell_price", 0)),
	]

func _on_buy_row_pressed(material_id: String) -> void:
	SceneManager.play_ui_button_click()
	var result := SHOP_SERVICE.try_buy_one(material_id, _stock_lookup, _inventory_manager, _game_manager)
	_set_status(str(result.get("message", "")), bool(result.get("success", false)))
	_refresh_view()

func _on_sell_row_pressed(material_id: String) -> void:
	SceneManager.play_ui_button_click()
	var result := SHOP_SERVICE.try_sell_one(material_id, _stock_lookup, _inventory_manager, _game_manager)
	_set_status(str(result.get("message", "")), bool(result.get("success", false)))
	_refresh_view()

func _set_status(message: String, success: bool) -> void:
	_status_label.text = message
	_status_label.tooltip_text = message
	if success:
		_status_label.modulate = Color(0.14, 0.34, 0.16, 1.0)
	else:
		_status_label.modulate = Color(0.45, 0.12, 0.1, 1.0)
