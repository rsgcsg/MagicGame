extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const REALM_SELECTION_WINDOW_SCENE := preload("res://scenes/realm_guild/realm_selection_window.tscn")
const EXPEDITION_SUMMARY_POPUP_SCENE := preload("res://scenes/ui/expedition_summary_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _return_to_town_button: Button = $Content/ReturnToTown/Button
@onready var _front_desk_button: Button = $Content/FrontDeskInteraction/Button
@onready var _return_to_town_card: Control = $Content/ReturnToTown
@onready var _front_desk_card: Control = $Content/FrontDeskInteraction
@onready var _popup_layer: Control = $PopupLayer
@onready var _scene_manager: Node = get_node("/root/SceneManager")
@onready var _game_manager = get_node_or_null("/root/GameManager")

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_return_to_town_button, _return_to_town_card)
	UI_BUTTON_FEEDBACK.wire_button(_front_desk_button, _front_desk_card)
	_return_to_town_button.pressed.connect(_on_return_to_town_pressed)
	_front_desk_button.pressed.connect(_on_front_desk_pressed)
	_open_latest_expedition_summary_if_available()

func _on_return_to_town_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.TOWN)

func _on_front_desk_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	for child in _popup_layer.get_children():
		child.queue_free()
	_popup_layer.add_child(REALM_SELECTION_WINDOW_SCENE.instantiate())

func _open_latest_expedition_summary_if_available() -> void:
	if _game_manager == null or not _game_manager.has_method("consume_latest_expedition_summary"):
		return
	var summary: Dictionary = _game_manager.call("consume_latest_expedition_summary")
	if summary.is_empty():
		return
	var popup = EXPEDITION_SUMMARY_POPUP_SCENE.instantiate()
	popup.configure_summary(summary)
	_popup_layer.add_child(popup)
