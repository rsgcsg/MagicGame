extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const REALM_MAP_CONTROLLER := preload("res://scripts/exploration/realm_map_controller.gd")
const BACKPACK_POPUP_SCENE := preload("res://scenes/ui/backpack_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

const LOCKED_MODULATE := Color(0.45, 0.45, 0.5, 0.72)
const AVAILABLE_MODULATE := Color(1, 1, 1, 1)
const UNRESOLVED_MODULATE := Color(0.75, 0.82, 1.12, 1)
const CLEARED_MODULATE := Color(1.08, 1.04, 0.78, 1)
const REWARD_CLAIMED_MODULATE := Color(1.15, 1.1, 0.78, 1)
const FAILED_MODULATE := Color(1.0, 0.62, 0.62, 1)

@onready var _start_button: Button = $Content/MapFrame/MapCanvas/StartNode/Button
@onready var _battle_left_button: Button = $Content/MapFrame/MapCanvas/BattleLeftNode/Button
@onready var _battle_right_button: Button = $Content/MapFrame/MapCanvas/BattleRightNode/Button
@onready var _rest_left_button: Button = $Content/MapFrame/MapCanvas/RestLeftNode/Button
@onready var _battle_center_button: Button = $Content/MapFrame/MapCanvas/BattleCenterNode/Button
@onready var _rest_right_button: Button = $Content/MapFrame/MapCanvas/RestRightNode/Button
@onready var _boss_button: Button = $Content/MapFrame/MapCanvas/BossNode/Button
@onready var _hint_label: Label = $Content/HintLabel
@onready var _scene_manager: Node = get_node("/root/SceneManager")
@onready var _battle_manager: Node = get_node_or_null("/root/BattleManager")
@onready var _return_to_workshop_button: Button = $Content/ReturnToWorkshop/Button
@onready var _open_card_bag_button: Button = $Content/OpenCardBag/Button
@onready var _popup_layer: Control = $PopupLayer
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")
@onready var _game_manager = get_node_or_null("/root/GameManager")

@onready var _node_views := {
	REALM_MAP_CONTROLLER.NODE_START: $Content/MapFrame/MapCanvas/StartNode,
	REALM_MAP_CONTROLLER.NODE_BATTLE_LEFT: $Content/MapFrame/MapCanvas/BattleLeftNode,
	REALM_MAP_CONTROLLER.NODE_BATTLE_RIGHT: $Content/MapFrame/MapCanvas/BattleRightNode,
	REALM_MAP_CONTROLLER.NODE_REST_LEFT: $Content/MapFrame/MapCanvas/RestLeftNode,
	REALM_MAP_CONTROLLER.NODE_BATTLE_CENTER: $Content/MapFrame/MapCanvas/BattleCenterNode,
	REALM_MAP_CONTROLLER.NODE_REST_RIGHT: $Content/MapFrame/MapCanvas/RestRightNode,
	REALM_MAP_CONTROLLER.NODE_BOSS: $Content/MapFrame/MapCanvas/BossNode,
}

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_start_button, _node_views[REALM_MAP_CONTROLLER.NODE_START])
	UI_BUTTON_FEEDBACK.wire_button(_battle_left_button, _node_views[REALM_MAP_CONTROLLER.NODE_BATTLE_LEFT])
	UI_BUTTON_FEEDBACK.wire_button(_battle_right_button, _node_views[REALM_MAP_CONTROLLER.NODE_BATTLE_RIGHT])
	UI_BUTTON_FEEDBACK.wire_button(_rest_left_button, _node_views[REALM_MAP_CONTROLLER.NODE_REST_LEFT])
	UI_BUTTON_FEEDBACK.wire_button(_battle_center_button, _node_views[REALM_MAP_CONTROLLER.NODE_BATTLE_CENTER])
	UI_BUTTON_FEEDBACK.wire_button(_rest_right_button, _node_views[REALM_MAP_CONTROLLER.NODE_REST_RIGHT])
	UI_BUTTON_FEEDBACK.wire_button(_boss_button, _node_views[REALM_MAP_CONTROLLER.NODE_BOSS])
	UI_BUTTON_FEEDBACK.wire_button(_return_to_workshop_button, $Content/ReturnToWorkshop)
	UI_BUTTON_FEEDBACK.wire_button(_open_card_bag_button, $Content/OpenCardBag)
	_start_button.pressed.connect(_on_start_pressed)
	_battle_left_button.pressed.connect(_on_battle_node_pressed.bind(REALM_MAP_CONTROLLER.NODE_BATTLE_LEFT))
	_battle_right_button.pressed.connect(_on_battle_node_pressed.bind(REALM_MAP_CONTROLLER.NODE_BATTLE_RIGHT))
	_battle_center_button.pressed.connect(_on_battle_node_pressed.bind(REALM_MAP_CONTROLLER.NODE_BATTLE_CENTER))
	_rest_left_button.pressed.connect(_on_rest_node_pressed.bind(REALM_MAP_CONTROLLER.NODE_REST_LEFT))
	_rest_right_button.pressed.connect(_on_rest_node_pressed.bind(REALM_MAP_CONTROLLER.NODE_REST_RIGHT))
	_boss_button.pressed.connect(_on_battle_node_pressed.bind(REALM_MAP_CONTROLLER.NODE_BOSS))
	_return_to_workshop_button.pressed.connect(_on_return_to_workshop_pressed)
	_open_card_bag_button.pressed.connect(_on_open_card_bag_pressed)
	_consume_battle_result_if_available()
	_auto_begin_route_if_needed()
	_refresh_node_states()

func _on_return_to_workshop_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_end_current_expedition_and_exit(SCENE_PATHS.ALCHEMY_SHOP, "player_abandoned")

func _on_start_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	REALM_MAP_CONTROLLER.mark_start_completed()
	_refresh_node_states()

func _on_battle_node_pressed(node_id: String) -> void:
	_scene_manager.call("play_ui_button_click")
	REALM_MAP_CONTROLLER.mark_node_unresolved(node_id)
	var battle_context := REALM_MAP_CONTROLLER.create_battle_entry_context(node_id)
	if _realm_loadout_manager != null:
		var loadout_summary: Dictionary = _realm_loadout_manager.call("get_active_loadout_summary")
		battle_context["loadout_card_count"] = int(loadout_summary.get("selected_card_count", 0))
		battle_context["deck_source"] = "realm_loadout" if int(loadout_summary.get("selected_card_count", 0)) > 0 else "empty_realm_loadout"
		battle_context["allow_debug_fallback_deck"] = false
	if _game_manager != null:
		battle_context["starting_mana"] = int(_game_manager.get("current_mana"))
		battle_context["max_mana"] = int(_game_manager.get("max_mana"))
	if _battle_manager != null:
		_battle_manager.call("start_placeholder_battle_from_realm", battle_context)
	_scene_manager.call("change_scene", SCENE_PATHS.BATTLE)

func _on_rest_node_pressed(node_id: String) -> void:
	_scene_manager.call("play_ui_button_click")
	if _game_manager != null:
		_game_manager.active_expedition["current_rest_node_id"] = node_id
	_scene_manager.call("change_scene", SCENE_PATHS.REST_SITE)

func _on_open_card_bag_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	for child in _popup_layer.get_children():
		child.queue_free()
	var popup = BACKPACK_POPUP_SCENE.instantiate()
	popup.configure_default_scope("expedition")
	_popup_layer.add_child(popup)

func _refresh_node_states() -> void:
	var node_states := REALM_MAP_CONTROLLER.get_node_states()
	for node_id in _node_views.keys():
		_apply_node_state(node_id, _node_views[node_id], str(node_states.get(node_id, REALM_MAP_CONTROLLER.STATE_LOCKED)))
	_refresh_hint_text(node_states)

func _consume_battle_result_if_available() -> void:
	if _battle_manager == null:
		return

	var result_payload = _battle_manager.call("consume_latest_battle_result_for_realm")
	if result_payload is Dictionary and not result_payload.is_empty():
		_sync_expedition_mana_from_result(result_payload)
		_apply_auto_battle_loot(result_payload)
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("apply_selected_reward"):
			_realm_loadout_manager.call("apply_selected_reward", result_payload.get("selected_reward", {}), result_payload)
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("apply_battle_result_card_lifecycle"):
			_realm_loadout_manager.call("apply_battle_result_card_lifecycle", result_payload)
		if REALM_MAP_CONTROLLER.is_expedition_end_result(result_payload):
			_end_current_expedition_and_exit(SCENE_PATHS.ALCHEMY_SHOP, _build_expedition_end_reason(result_payload))
			return
		REALM_MAP_CONTROLLER.apply_battle_result(result_payload)

func _auto_begin_route_if_needed() -> void:
	if REALM_MAP_CONTROLLER.is_fresh_route_state():
		REALM_MAP_CONTROLLER.mark_start_completed()

func _apply_node_state(node_id: String, node_view: Control, state: String) -> void:
	var button: Button = node_view.get_node("Button")
	_update_node_label(node_id, node_view, state)
	match state:
		REALM_MAP_CONTROLLER.STATE_LOCKED:
			node_view.modulate = LOCKED_MODULATE
			button.disabled = true
		REALM_MAP_CONTROLLER.STATE_AVAILABLE:
			node_view.modulate = AVAILABLE_MODULATE
			button.disabled = false
		REALM_MAP_CONTROLLER.STATE_UNRESOLVED:
			node_view.modulate = UNRESOLVED_MODULATE
			button.disabled = true
		REALM_MAP_CONTROLLER.STATE_CLEARED:
			node_view.modulate = CLEARED_MODULATE
			button.disabled = true
		REALM_MAP_CONTROLLER.STATE_REWARD_CLAIMED:
			node_view.modulate = REWARD_CLAIMED_MODULATE
			button.disabled = true
		REALM_MAP_CONTROLLER.STATE_FAILED:
			node_view.modulate = FAILED_MODULATE
			button.disabled = true
	UI_BUTTON_FEEDBACK.sync_base_values(node_view)

func _refresh_hint_text(node_states: Dictionary) -> void:
	var available_nodes: Array[String] = []
	for node_id in _node_views.keys():
		if str(node_states.get(node_id, REALM_MAP_CONTROLLER.STATE_LOCKED)) == REALM_MAP_CONTROLLER.STATE_AVAILABLE:
			var node_definition := REALM_MAP_CONTROLLER.get_node_definition(node_id)
			available_nodes.append(str(node_definition.get("display_name", node_id)))
	if available_nodes.is_empty():
		_hint_label.text = "Clear the current node to push deeper into the realm."
		return
	_hint_label.text = "Available route choices: %s" % ", ".join(available_nodes)

func _update_node_label(node_id: String, node_view: Control, state: String) -> void:
	var node_definition := REALM_MAP_CONTROLLER.get_node_definition(node_id)
	var base_label := str(node_definition.get("display_name", node_id))
	node_view.set("label_text", base_label)
	node_view.set("state_text", state.capitalize())
	node_view.set("icon_text", _get_node_icon(node_definition))

func _get_node_icon(node_definition: Dictionary) -> String:
	match str(node_definition.get("node_type", "")):
		REALM_MAP_CONTROLLER.NODE_TYPE_START:
			return "◈"
		REALM_MAP_CONTROLLER.NODE_TYPE_REST:
			return "✦"
		REALM_MAP_CONTROLLER.NODE_TYPE_BOSS:
			return "☠"
		_:
			return "⚔"

func _build_expedition_end_reason(result_payload: Dictionary) -> String:
	if str(result_payload.get("result_type", "")) == "failure":
		return "battle_failure"
	if str(result_payload.get("node_type", "")) == REALM_MAP_CONTROLLER.NODE_TYPE_BOSS:
		return "boss_cleared"
	return "realm_complete"

func _sync_expedition_mana_from_result(result_payload: Dictionary) -> void:
	if _game_manager == null or not _game_manager.has_method("set_mana"):
		return
	_game_manager.call("set_mana", int(result_payload.get("remaining_mana", result_payload.get("mana_remaining", _game_manager.get("current_mana")))))

func _apply_auto_battle_loot(result_payload: Dictionary) -> void:
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("add_active_materials"):
		var auto_material_bundle: Dictionary = result_payload.get("auto_material_bundle", {}) if result_payload.get("auto_material_bundle", {}) is Dictionary else {}
		if auto_material_bundle is Dictionary and not (auto_material_bundle as Dictionary).is_empty():
			_realm_loadout_manager.call("add_active_materials", auto_material_bundle, "reward")
	if _game_manager != null and _game_manager.has_method("add_gold"):
		_game_manager.call("add_gold", int(result_payload.get("auto_gold_reward", 0)))

func _end_current_expedition_and_exit(destination_scene: String, end_reason: String) -> void:
	var expedition_summary := {}
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("finalize_active_expedition"):
		expedition_summary = _realm_loadout_manager.call("finalize_active_expedition", true)
	if not expedition_summary.is_empty():
		expedition_summary["end_reason"] = end_reason
		expedition_summary["destination_scene"] = destination_scene
		if _game_manager != null and _game_manager.has_method("set_latest_expedition_summary"):
			_game_manager.call("set_latest_expedition_summary", expedition_summary)
	REALM_MAP_CONTROLLER.reset_placeholder_progress()
	if _game_manager != null:
		if end_reason != "player_abandoned" and _game_manager.has_method("restore_full_mana"):
			_game_manager.call("restore_full_mana")
		_game_manager.active_expedition = {}
	_scene_manager.call("change_scene", destination_scene)
