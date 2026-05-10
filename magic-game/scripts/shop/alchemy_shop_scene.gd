extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const SHELF_POPUP_SCENE := preload("res://scenes/shop/shop_shelf_popup.tscn")
const EXPEDITION_SUMMARY_POPUP_SCENE := preload("res://scenes/ui/expedition_summary_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _background: TextureRect = $Background
@onready var _shading: ColorRect = $Shading
@onready var _overlay_layer: Control = $OverlayLayer
@onready var _town_button: Button = $Content/ToTown/Button
@onready var _laboratory_button: Button = $Content/ToLaboratory/Button
@onready var _shelf_button: Button = $Content/Shelf/Button
@onready var _gold_value_label: Label = $Content/BusinessInfoPanel/Margin/Layout/GoldRow/Margin/Row/GoldValue
@onready var _game_manager: Node = get_node("/root/GameManager")
@onready var _scene_manager: Node = get_node("/root/SceneManager")

func _ready() -> void:
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_town_button)
	UI_BUTTON_FEEDBACK.wire_button(_laboratory_button)
	UI_BUTTON_FEEDBACK.wire_button(_shelf_button)
	_connect_buttons()
	_refresh_business_info()
	_open_latest_expedition_summary_if_available()

func _connect_buttons() -> void:
	_town_button.pressed.connect(_on_navigation_button_pressed.bind("To Town", SCENE_PATHS.TOWN))
	_laboratory_button.pressed.connect(_on_navigation_button_pressed.bind("To Laboratory", SCENE_PATHS.LABORATORY))
	_shelf_button.pressed.connect(_on_open_shelf_pressed)

func _refresh_business_info() -> void:
	_gold_value_label.text = str(_game_manager.get("gold"))

func _open_shelf_popup() -> void:
	for child in _overlay_layer.get_children():
		child.queue_free()
	_overlay_layer.add_child(SHELF_POPUP_SCENE.instantiate())

func _open_latest_expedition_summary_if_available() -> void:
	if _game_manager == null or not _game_manager.has_method("consume_latest_expedition_summary"):
		return
	var summary: Dictionary = _game_manager.call("consume_latest_expedition_summary")
	if summary.is_empty():
		return
	for child in _overlay_layer.get_children():
		child.queue_free()
	var popup = EXPEDITION_SUMMARY_POPUP_SCENE.instantiate()
	popup.configure_summary(summary)
	_overlay_layer.add_child(popup)

func _on_navigation_button_pressed(button_name: String, scene_id: String) -> void:
	print("AlchemyShop button pressed: %s -> %s" % [button_name, scene_id])
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", scene_id)

func _on_open_shelf_pressed() -> void:
	print("AlchemyShop button pressed: Open Shelf")
	_scene_manager.call("play_ui_button_click")
	_open_shelf_popup()
