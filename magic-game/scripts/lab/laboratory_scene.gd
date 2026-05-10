extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const ALCHEMY_TABLE_POPUP_SCENE := preload("res://scenes/lab/alchemy_table_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _back_to_shop_button: Button = $Content/BackToShop/Button
@onready var _alchemy_table_button: Button = $Content/AlchemyTable/Button
@onready var _back_to_shop_card: Control = $Content/BackToShop
@onready var _alchemy_table_card: Control = $Content/AlchemyTable
@onready var _popup_layer: Control = $PopupLayer
@onready var _scene_manager: Node = get_node("/root/SceneManager")

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_back_to_shop_button, _back_to_shop_card)
	UI_BUTTON_FEEDBACK.wire_button(_alchemy_table_button, _alchemy_table_card)
	_back_to_shop_button.pressed.connect(_on_back_to_shop_pressed)
	_alchemy_table_button.pressed.connect(_on_alchemy_table_pressed)

func _on_back_to_shop_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.ALCHEMY_SHOP)

func _on_alchemy_table_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	for child in _popup_layer.get_children():
		child.queue_free()
	_popup_layer.add_child(ALCHEMY_TABLE_POPUP_SCENE.instantiate())
