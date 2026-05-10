extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const REALM_MAP_CONTROLLER := preload("res://scripts/exploration/realm_map_controller.gd")
const ALCHEMY_TABLE_POPUP_SCENE := preload("res://scenes/lab/alchemy_table_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@onready var _rest_button: Button = $Content/ChoiceRow/RestButton/Button
@onready var _return_to_realm_map_button: Button = $Content/ReturnToRealmMap/Button
@onready var _end_expedition_button: Button = $Content/ContinueExpedition/Button
@onready var _craft_card_button: Button = $Content/ChoiceRow/CraftCardButton/Button
@onready var _rest_card: Control = $Content/ChoiceRow/RestButton
@onready var _return_to_realm_map_card: Control = $Content/ReturnToRealmMap
@onready var _end_expedition_card: Control = $Content/ContinueExpedition
@onready var _craft_card: Control = $Content/ChoiceRow/CraftCardButton
@onready var _popup_layer: Control = $PopupLayer
@onready var _scene_manager: Node = get_node("/root/SceneManager")
@onready var _game_manager = get_node_or_null("/root/GameManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_rest_button, _rest_card)
	UI_BUTTON_FEEDBACK.wire_button(_return_to_realm_map_button, _return_to_realm_map_card)
	UI_BUTTON_FEEDBACK.wire_button(_end_expedition_button, _end_expedition_card)
	UI_BUTTON_FEEDBACK.wire_button(_craft_card_button, _craft_card)
	_rest_button.pressed.connect(_on_rest_pressed)
	_return_to_realm_map_button.pressed.connect(_on_return_to_realm_map_pressed)
	_end_expedition_button.pressed.connect(_on_end_expedition_pressed)
	_craft_card_button.pressed.connect(_on_craft_card_pressed)

func _on_return_to_realm_map_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_complete_current_rest_node_and_return()

func _on_rest_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	if _game_manager != null and _game_manager.has_method("restore_full_mana"):
		_game_manager.call("restore_full_mana")
	_complete_current_rest_node_and_return()

func _on_end_expedition_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_end_current_expedition_and_exit("player_abandoned")

func _on_craft_card_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	for child in _popup_layer.get_children():
		child.queue_free()
	var popup = ALCHEMY_TABLE_POPUP_SCENE.instantiate()
	popup.configure_for_realm_expedition()
	_popup_layer.add_child(popup)

func _complete_current_rest_node_and_return() -> void:
	var rest_node_id := _get_current_rest_node_id()
	REALM_MAP_CONTROLLER.mark_rest_completed(rest_node_id)
	_scene_manager.call("change_scene", SCENE_PATHS.REALM_MAP)

func _end_current_expedition_and_exit(end_reason: String) -> void:
	var expedition_summary := {}
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("finalize_active_expedition"):
		expedition_summary = _realm_loadout_manager.call("finalize_active_expedition", true)
	if not expedition_summary.is_empty():
		expedition_summary["end_reason"] = end_reason
		expedition_summary["destination_scene"] = SCENE_PATHS.ALCHEMY_SHOP
		if _game_manager != null and _game_manager.has_method("set_latest_expedition_summary"):
			_game_manager.call("set_latest_expedition_summary", expedition_summary)
	REALM_MAP_CONTROLLER.reset_placeholder_progress()
	if _game_manager != null:
		if end_reason != "player_abandoned" and _game_manager.has_method("restore_full_mana"):
			_game_manager.call("restore_full_mana")
		_game_manager.active_expedition = {}
	_scene_manager.call("change_scene", SCENE_PATHS.ALCHEMY_SHOP)

func _get_current_rest_node_id() -> String:
	if _game_manager == null:
		return REALM_MAP_CONTROLLER.NODE_REST_LEFT
	return str(_game_manager.active_expedition.get("current_rest_node_id", REALM_MAP_CONTROLLER.NODE_REST_LEFT))
