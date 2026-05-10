extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const TRADE_WINDOW_SCENE := preload("res://scenes/raw_material_shop/raw_material_trade_window.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _return_to_town_button: Button = $Content/ReturnToTown/Button
@onready var _shopkeeper_button: Button = $Content/ShopkeeperArea/ShopkeeperButton
@onready var _return_to_town_card: Control = $Content/ReturnToTown
@onready var _shopkeeper_card: Control = $Content/ShopkeeperArea
@onready var _popup_layer: Control = $PopupLayer
@onready var _scene_manager: Node = get_node("/root/SceneManager")

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_return_to_town_button, _return_to_town_card)
	UI_BUTTON_FEEDBACK.wire_button(_shopkeeper_button, _shopkeeper_card)
	_return_to_town_button.pressed.connect(_on_return_to_town_pressed)
	_shopkeeper_button.pressed.connect(_on_open_trade_window_pressed)

func _on_return_to_town_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.TOWN)

func _on_open_trade_window_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	for child in _popup_layer.get_children():
		child.queue_free()
	_popup_layer.add_child(TRADE_WINDOW_SCENE.instantiate())
