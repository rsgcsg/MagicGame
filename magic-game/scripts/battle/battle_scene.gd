extends Control

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const TURN_CONTROLLER_SCRIPT := preload("res://scripts/battle/battle_turn_controller.gd")
const REALM_MAP_CONTROLLER := preload("res://scripts/exploration/realm_map_controller.gd")
const STATUS_BADGE_SCENE := preload("res://scenes/battle/battle_status_badge.tscn")
const FLOATING_TEXT_SCENE := preload("res://scenes/battle/battle_floating_text.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

const RESULT_PENDING := "pending"
const RESULT_VICTORY := "victory"
const RESULT_FAILURE := "failure"
const REWARD_SKIP := "skip_reward"
const PHASE_ENEMY_TURN := "enemy_turn"

@onready var _background: Control = $Background
@onready var _shading: Control = $Shading
@onready var _content_root: Control = $Content
@onready var _enemy_name_label: Label = $Content/EnemyArea/EnemyNameLabel
@onready var _enemy_image: TextureRect = $Content/EnemyArea/EnemyImage
@onready var _enemy_hp_label: Label = $Content/EnemyArea/EnemyFooterRow/EnemyHpPanel/EnemyHpMargin/EnemyHpLabel
@onready var _enemy_intent_label: Label = $Content/EnemyArea/EnemyIntentPanel/EnemyIntentMargin/EnemyIntentLabel
@onready var _enemy_status_panel: Control = $Content/EnemyArea/EnemyFooterRow/EnemyStatusPanel
@onready var _enemy_status_empty_label: Label = $Content/EnemyArea/EnemyFooterRow/EnemyStatusPanel/EnemyStatusMargin/EnemyStatusLayout/EnemyStatusEmptyLabel
@onready var _enemy_status_flow: HFlowContainer = $Content/EnemyArea/EnemyFooterRow/EnemyStatusPanel/EnemyStatusMargin/EnemyStatusLayout/EnemyStatusFlow
@onready var _failure_message_label: Label = $Content/FailureMessageLabel
@onready var _victory_message_label: Label = $Content/VictoryMessageLabel
@onready var _battle_ended_status_label: Label = $Content/BattleEndedStatusLabel
@onready var _result_overlay: Control = $ResultOverlayLayer/ResultOverlay
@onready var _result_panel: PanelContainer = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel
@onready var _result_title_label: Label = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/ResultTitleLabel
@onready var _result_description_label: Label = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/ResultDescriptionLabel
@onready var _reward_placeholder_panel: PanelContainer = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/RewardPlaceholderPanel
@onready var _reward_label: Label = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/RewardPlaceholderPanel/RewardMargin/RewardLayout/RewardLabel
@onready var _material_reward_button: Button = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/RewardPlaceholderPanel/RewardMargin/RewardLayout/RewardChoiceGrid/MaterialRewardButton
@onready var _card_reward_button: Button = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/RewardPlaceholderPanel/RewardMargin/RewardLayout/RewardChoiceGrid/CardRewardButton
@onready var _clue_reward_button: Button = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/RewardPlaceholderPanel/RewardMargin/RewardLayout/RewardChoiceGrid/ClueRewardButton
@onready var _skip_reward_button: Button = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/RewardPlaceholderPanel/RewardMargin/RewardLayout/RewardChoiceGrid/SkipRewardButton
@onready var _result_action_hint_label: Label = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/ResultActionHintLabel
@onready var _defeat_continue_button: Button = $ResultOverlayLayer/ResultOverlay/ResultCenter/ResultPanel/ResultMargin/ResultLayout/DefeatContinueButton
@onready var _mana_label: Label = $Content/PlayerResourceBar/ManaPanel/ManaMargin/ManaLabel
@onready var _block_label: Label = $Content/PlayerResourceBar/BlockPanel/BlockMargin/BlockLabel
@onready var _action_points_label: Label = $Content/PlayerResourceBar/ActionPointsPanel/ActionPointsMargin/ActionPointsLabel
@onready var _player_status_panel: Control = $Content/PlayerStatusPanel
@onready var _player_status_empty_label: Label = $Content/PlayerStatusPanel/PlayerStatusMargin/PlayerStatusLayout/PlayerStatusEmptyLabel
@onready var _player_status_flow: HFlowContainer = $Content/PlayerStatusPanel/PlayerStatusMargin/PlayerStatusLayout/PlayerStatusFlow
@onready var _draw_pile_label: Label = $Content/DrawPilePanel/DrawPileMargin/PileLayout/DrawPileLabel
@onready var _discard_pile_label: Label = $Content/DiscardPilePanel/DiscardPileMargin/PileLayout/DiscardPileLabel
@onready var _hand_placeholder_label: Label = $Content/HandInfoLayout/HandPlaceholderLabel
@onready var _card_feedback_label: Label = $Content/HandInfoLayout/CardFeedbackLabel
@onready var _hand_view = $Content/HandPanel/HandMargin/HandLayout/HandView
@onready var _top_status_bar: Control = $Content/TopStatusBar
@onready var _hand_info_layout: Control = $Content/HandInfoLayout
@onready var _hand_panel: Control = $Content/HandPanel
@onready var _draw_pile_panel: Control = $Content/DrawPilePanel
@onready var _discard_pile_panel: Control = $Content/DiscardPilePanel
@onready var _player_resource_bar: Control = $Content/PlayerResourceBar
@onready var _end_turn_panel: Control = $Content/EndTurnPanel
@onready var _end_turn_button: Button = $Content/EndTurnPanel/Margin/EndTurnButton
@onready var _feedback_layer: Control = $FeedbackLayer
@onready var _turn_banner_label: Label = $FeedbackLayer/TurnBannerLabel
@onready var _floating_text_mount: Control = $FeedbackLayer/FloatingTextMount
@onready var _scene_manager: Node = get_node("/root/SceneManager")
@onready var _battle_manager: Node = get_node_or_null("/root/BattleManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")
@onready var _game_manager = get_node_or_null("/root/GameManager")

var _turn_controller: BattleTurnController
var _reported_battle_result := ""
var _current_result_payload := {}
var _result_acknowledged := false
var _action_sequence_active := false

func _ready() -> void:
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_enemy_status_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_enemy_status_flow.mouse_filter = Control.MOUSE_FILTER_PASS
	_player_status_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_player_status_flow.mouse_filter = Control.MOUSE_FILTER_PASS
	UI_BUTTON_FEEDBACK.wire_button(_end_turn_button)
	UI_BUTTON_FEEDBACK.wire_button(_material_reward_button)
	UI_BUTTON_FEEDBACK.wire_button(_card_reward_button)
	UI_BUTTON_FEEDBACK.wire_button(_clue_reward_button)
	UI_BUTTON_FEEDBACK.wire_button(_skip_reward_button)
	UI_BUTTON_FEEDBACK.wire_button(_defeat_continue_button)
	_setup_placeholder_battle()
	_turn_controller = TURN_CONTROLLER_SCRIPT.new()
	_turn_controller.start_placeholder_battle(_get_current_battle_context())
	_connect_temporary_debug_controls()
	_refresh_placeholder_view()

func _setup_placeholder_battle() -> void:
	if _battle_manager != null:
		_battle_manager.call("setup_placeholder_battle")

func _connect_temporary_debug_controls() -> void:
	_hand_view.card_play_requested.connect(_on_card_play_requested)
	_hand_view.card_discard_requested.connect(_on_card_discard_requested)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_material_reward_button.pressed.connect(_on_reward_choice_pressed.bind("material_fire_wind_bundle"))
	_card_reward_button.pressed.connect(_on_reward_choice_pressed.bind("card_realm_echo"))
	_skip_reward_button.pressed.connect(_on_reward_choice_pressed.bind(REWARD_SKIP))
	_defeat_continue_button.pressed.connect(_on_defeat_continue_pressed)

func _refresh_placeholder_view() -> void:
	var turn_data := _turn_controller.get_placeholder_turn_snapshot()
	var battle_result := str(turn_data.get("battle_result", ""))
	var battle_phase := str(turn_data.get("phase", ""))
	var battle_has_ended := battle_result == RESULT_FAILURE or battle_result == RESULT_VICTORY
	var result_handoff = turn_data.get("result_handoff", {})
	_failure_message_label.visible = false
	_victory_message_label.visible = false
	_battle_ended_status_label.visible = false
	_refresh_result_panel(battle_result, result_handoff if result_handoff is Dictionary else {})
	_set_live_battle_ui_interactable(not battle_has_ended and battle_phase != PHASE_ENEMY_TURN and not _action_sequence_active)
	_report_result_handoff_once(battle_result, result_handoff if result_handoff is Dictionary else {})
	_enemy_name_label.text = "Enemy: %s" % turn_data.get("enemy_name", "Slime")
	_refresh_enemy_icon(str(turn_data.get("enemy_icon_path", "")))
	_enemy_hp_label.text = str(turn_data.get("enemy_hp_text", "12/12 HP"))
	_enemy_intent_label.text = "Intent: %s" % turn_data.get("enemy_intent", "Attack 15")
	_refresh_status_badges(_enemy_status_flow, _enemy_status_empty_label, turn_data.get("enemy_status_entries", []), "No statuses")
	_mana_label.text = "Mana %s" % turn_data.get("battle_mana_text", "Placeholder")
	if _top_status_bar != null and _top_status_bar.has_method("set_runtime_status_override"):
		_top_status_bar.call("set_runtime_status_override", {
			"mana_label": _mana_label.text,
		})
	_block_label.text = "Block: %s" % turn_data.get("player_block", 0)
	_action_points_label.text = "Action Points: %s" % turn_data.get("action_points", 3)
	_refresh_status_badges(_player_status_flow, _player_status_empty_label, turn_data.get("player_status_entries", []), "No statuses")
	_draw_pile_label.text = "Draw Pile: %s" % turn_data.get("draw_pile_text", "Placeholder")
	_discard_pile_label.text = "Discard Pile: %s" % turn_data.get("discard_pile_text", "Placeholder")
	if battle_phase == PHASE_ENEMY_TURN:
		_hand_placeholder_label.text = "Enemy turn: intent resolving..."
	else:
		_hand_placeholder_label.text = "Turn %s: %s cards ready" % [turn_data.get("turn_number", 1), turn_data.get("hand_size", 5)]
	if _card_feedback_label.text.is_empty():
		_card_feedback_label.text = "Left click to play a card. Right click to discard."
		_card_feedback_label.tooltip_text = _card_feedback_label.text

	var hand_cards = turn_data.get("hand_cards", [])
	if hand_cards is Array:
		_hand_view.display_cards(hand_cards)
	else:
		_hand_view.display_cards([])

	_end_turn_button.disabled = battle_has_ended

func _refresh_enemy_icon(icon_path: String) -> void:
	if _enemy_image == null:
		return
	if icon_path.is_empty():
		return
	var texture := load(icon_path) as Texture2D
	if texture != null:
		_enemy_image.texture = texture
func _refresh_result_panel(battle_result: String, result_handoff: Dictionary) -> void:
	var battle_has_ended := battle_result == RESULT_FAILURE or battle_result == RESULT_VICTORY
	_result_overlay.visible = battle_has_ended
	if not battle_has_ended:
		_current_result_payload = {}
		_result_acknowledged = false
		return

	if battle_result == RESULT_VICTORY:
		var node_type := str(result_handoff.get("node_type", "normal_battle"))
		var is_boss_battle := node_type == "boss_battle"
		var is_debug_battle := node_type == "debug_battle"
		_result_title_label.text = "Boss Defeated" if is_boss_battle else "Victory"
		if is_boss_battle:
			_result_description_label.text = "The boss has fallen. Claim one final reward, then resolve expedition recovery."
		elif is_debug_battle:
			_result_description_label.text = "The direct debug battle is complete. Return to the workshop flow."
		else:
			_result_description_label.text = "The encounter is complete. Continue to the Realm Map and unlock the next route."
		_reward_placeholder_panel.visible = true
		_defeat_continue_button.visible = false
		_refresh_reward_choice_text()
		_set_reward_buttons_disabled(_result_acknowledged)
	else:
		_result_title_label.text = "Defeat"
		var current_node_type := str(_get_current_battle_context().get("node_type", "normal_battle"))
		if current_node_type == "debug_battle":
			_result_description_label.text = "Mana reached 0. This direct debug battle will return to the workshop flow."
		else:
			_result_description_label.text = "Mana reached 0. The expedition ends here, and any surviving realm cards will return to the external bag."
		_reward_placeholder_panel.visible = false
		_defeat_continue_button.visible = true
		_defeat_continue_button.text = "Return to Workshop" if current_node_type == "debug_battle" else "End Expedition"
		_defeat_continue_button.disabled = _result_acknowledged

	var current_node_type := str(_get_current_battle_context().get("node_type", "normal_battle"))
	if current_node_type == "debug_battle":
		_result_action_hint_label.text = "Battle handoff: %s" % result_handoff.get("battle_result", battle_result)
	else:
		_result_action_hint_label.text = "Exploration handoff: %s" % result_handoff.get("battle_result", battle_result)

func _refresh_reward_choice_text() -> void:
	var battle_context := _get_current_battle_context()
	var node_type := str(battle_context.get("node_type", "normal_battle"))
	if node_type == "debug_battle":
		_reward_label.text = "Direct debug battle launch: no realm reward is applied. Return to the workshop flow."
		_material_reward_button.visible = false
		_card_reward_button.visible = false
		_clue_reward_button.visible = false
		_skip_reward_button.visible = true
		_skip_reward_button.text = "Return to Workshop"
		return
	if node_type == "boss_battle":
		var boss_material_reward := _get_reward_option_by_type("material")
		var boss_card_reward := _get_reward_option_by_type("card")
		var boss_skip_reward := _get_reward_option_by_type("skip")
		_reward_label.text = "Boss loot already includes base materials and gold. Choose one final rare reward before expedition recovery."
		_material_reward_button.visible = true
		_card_reward_button.visible = true
		_clue_reward_button.visible = false
		_skip_reward_button.visible = true
		_material_reward_button.text = str(boss_material_reward.get("display_name", "Take Rare Material"))
		_card_reward_button.text = str(boss_card_reward.get("display_name", "Take Rare Card"))
		_skip_reward_button.text = str(boss_skip_reward.get("display_name", "Complete Expedition"))
		return

	var material_reward := _get_reward_option_by_type("material")
	var card_reward := _get_reward_option_by_type("card")
	var skip_reward := _get_reward_option_by_type("skip")
	_reward_label.text = "Victory grants base materials and gold automatically. Choose one extra reward for the current expedition backpack."
	_material_reward_button.visible = true
	_card_reward_button.visible = true
	_clue_reward_button.visible = false
	_skip_reward_button.visible = true
	_material_reward_button.text = str(material_reward.get("display_name", "Take Materials"))
	_card_reward_button.text = str(card_reward.get("display_name", "Take Card"))
	_skip_reward_button.text = str(skip_reward.get("display_name", "Skip Reward"))

func _report_result_handoff_once(battle_result: String, result_handoff: Dictionary) -> void:
	var battle_has_ended := battle_result == RESULT_FAILURE or battle_result == RESULT_VICTORY
	if not battle_has_ended or _battle_manager == null or _reported_battle_result == battle_result:
		return

	_reported_battle_result = battle_result
	_battle_manager.call("report_placeholder_battle_result", result_handoff)
	_current_result_payload = _battle_manager.get("last_battle_result_handoff")

func _on_card_play_requested(instance_id: String) -> void:
	if _action_sequence_active:
		return
	var card_name: String = _hand_view.get_card_name(instance_id)
	if _turn_controller.play_placeholder_card(instance_id):
		_action_sequence_active = true
		_scene_manager.call("play_ui_card_play_sound")
		_show_card_feedback("Played %s" % card_name)
		var action_report := _turn_controller.consume_last_action_report()
		_refresh_placeholder_view()
		await _play_action_report(action_report)
		_action_sequence_active = false

func _on_card_discard_requested(instance_id: String) -> void:
	if _action_sequence_active:
		return
	var card_name: String = _hand_view.get_card_name(instance_id)
	if _turn_controller.discard_placeholder_card(instance_id):
		_scene_manager.call("play_ui_button_click")
		_show_card_feedback("Discarded %s" % card_name)
		_refresh_placeholder_view()

func _on_end_turn_pressed() -> void:
	if _action_sequence_active:
		return
	_scene_manager.call("play_ui_button_click")
	if _turn_controller.end_placeholder_turn():
		_action_sequence_active = true
		await _run_enemy_turn_sequence()
		_action_sequence_active = false

func _on_return_to_realm_map_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.REALM_MAP)

func _on_complete_battle_and_return_pressed() -> void:
	# Temporary debug hook: skip combat resolution and jump back to the map.
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.REALM_MAP)

func _on_fail_expedition_placeholder_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	_scene_manager.call("change_scene", SCENE_PATHS.ALCHEMY_SHOP)

func _on_reward_choice_pressed(reward_id: String) -> void:
	if _result_acknowledged:
		return

	_scene_manager.call("play_ui_button_click")
	var selected_reward := _get_reward_option_by_id(reward_id)
	if _battle_manager != null:
		_current_result_payload = _battle_manager.call("acknowledge_victory_reward", selected_reward)
	_result_acknowledged = true
	_set_reward_buttons_disabled(true)
	if _should_end_expedition_after_victory():
		_finalize_expedition_and_exit_from_battle("boss_cleared")
		return
	_return_after_battle_result()

func _on_defeat_continue_pressed() -> void:
	if _result_acknowledged:
		return

	_scene_manager.call("play_ui_button_click")
	if _battle_manager != null and _battle_manager.get("last_battle_result_handoff") is Dictionary and (_battle_manager.get("last_battle_result_handoff") as Dictionary).is_empty():
		var defeat_payload := {
			"battle_result": RESULT_FAILURE,
			"result_type": RESULT_FAILURE,
			"mana_remaining": 0,
			"remaining_block": 0,
			"turn_number": 1,
			"hand_count": 0,
			"draw_count": 0,
			"discard_count": 0,
			"consumed_card_ids": [],
			"consumed_source_runtime_ids": [],
		}
		_battle_manager.call("report_placeholder_battle_result", defeat_payload)
		_current_result_payload = _battle_manager.get("last_battle_result_handoff")
	if _battle_manager != null:
		_current_result_payload = _battle_manager.call("acknowledge_defeat")
	_result_acknowledged = true
	_defeat_continue_button.disabled = true
	if _should_end_expedition_after_defeat():
		_finalize_expedition_and_exit_from_battle("battle_failure")
		return
	_return_after_battle_result()

func _get_reward_option_by_id(reward_id: String) -> Dictionary:
	if _battle_manager == null:
		return {}

	var reward_options = _battle_manager.call("get_placeholder_reward_options")
	if reward_options is Array:
		for reward_option in reward_options:
			if reward_option is Dictionary and str(reward_option.get("reward_id", "")) == reward_id:
				return reward_option.duplicate(true)

	return {}

func _get_reward_option_by_type(reward_type: String) -> Dictionary:
	if _battle_manager == null:
		return {}
	var reward_options = _battle_manager.call("get_placeholder_reward_options")
	if reward_options is Array:
		for reward_option in reward_options:
			if reward_option is Dictionary and str(reward_option.get("reward_type", "")) == reward_type:
				return reward_option.duplicate(true)
	return {}

func _set_reward_buttons_disabled(disabled: bool) -> void:
	_material_reward_button.disabled = disabled
	_card_reward_button.disabled = disabled
	_clue_reward_button.disabled = disabled
	_skip_reward_button.disabled = disabled

func _return_after_battle_result() -> void:
	var return_target := SCENE_PATHS.REALM_MAP
	if _current_result_payload is Dictionary and not _current_result_payload.is_empty():
		return_target = str(_current_result_payload.get("return_target", SCENE_PATHS.REALM_MAP))
	_scene_manager.call("change_scene", return_target)

func _should_end_expedition_after_victory() -> bool:
	var current_node_type := str(_get_current_battle_context().get("node_type", "normal_battle"))
	return current_node_type == REALM_MAP_CONTROLLER.NODE_TYPE_BOSS and _has_active_realm_expedition()

func _should_end_expedition_after_defeat() -> bool:
	var current_node_type := str(_get_current_battle_context().get("node_type", "normal_battle"))
	return current_node_type != "debug_battle" and _has_active_realm_expedition()

func _has_active_realm_expedition() -> bool:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("has_active_expedition"):
		return false
	return bool(_realm_loadout_manager.call("has_active_expedition"))

func _finalize_expedition_and_exit_from_battle(end_reason: String) -> void:
	if _battle_manager != null:
		_battle_manager.set("pending_realm_result", false)
	if _game_manager != null and _game_manager.has_method("set_mana") and _current_result_payload is Dictionary and not _current_result_payload.is_empty():
		_game_manager.call("set_mana", int(_current_result_payload.get("remaining_mana", _current_result_payload.get("mana_remaining", _game_manager.get("current_mana")))))
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("add_active_materials") and _current_result_payload is Dictionary and not _current_result_payload.is_empty():
		var auto_material_bundle: Dictionary = _current_result_payload.get("auto_material_bundle", {}) if _current_result_payload.get("auto_material_bundle", {}) is Dictionary else {}
		if auto_material_bundle is Dictionary and not (auto_material_bundle as Dictionary).is_empty():
			_realm_loadout_manager.call("add_active_materials", auto_material_bundle, "reward")
	if _game_manager != null and _game_manager.has_method("add_gold") and _current_result_payload is Dictionary and not _current_result_payload.is_empty():
		_game_manager.call("add_gold", int(_current_result_payload.get("auto_gold_reward", 0)))
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("apply_selected_reward") and _current_result_payload is Dictionary and not _current_result_payload.is_empty():
		_realm_loadout_manager.call("apply_selected_reward", _current_result_payload.get("selected_reward", {}), _current_result_payload)
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
		if _game_manager.has_method("restore_full_mana"):
			_game_manager.call("restore_full_mana")
		_game_manager.active_expedition = {}
	_scene_manager.call("change_scene", SCENE_PATHS.ALCHEMY_SHOP)

func _set_live_battle_ui_interactable(enabled: bool) -> void:
	var interaction_mode := Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	_top_status_bar.mouse_filter = interaction_mode
	_hand_info_layout.mouse_filter = interaction_mode
	_hand_panel.mouse_filter = interaction_mode
	_hand_view.mouse_filter = interaction_mode
	_draw_pile_panel.mouse_filter = interaction_mode
	_discard_pile_panel.mouse_filter = interaction_mode
	_player_resource_bar.mouse_filter = interaction_mode
	_enemy_status_panel.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	_enemy_status_flow.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	_player_status_panel.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	_player_status_flow.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	_end_turn_panel.mouse_filter = interaction_mode

func _get_current_battle_context() -> Dictionary:
	if _battle_manager == null or not _battle_manager.has_method("get_current_battle_entry_context"):
		return {}
	var battle_context: Variant = _battle_manager.call("get_current_battle_entry_context")
	if battle_context is Dictionary:
		var current_battle: Variant = _battle_manager.get("current_battle")
		if current_battle is Dictionary:
			for key in current_battle.keys():
				battle_context[key] = current_battle[key]
		return battle_context
	return {}

func _refresh_status_badges(container: HFlowContainer, empty_label: Label, status_entries_variant: Variant, empty_text: String) -> void:
	for child in container.get_children():
		child.queue_free()

	var status_entries: Array = status_entries_variant if status_entries_variant is Array else []
	empty_label.text = empty_text
	empty_label.tooltip_text = empty_text
	empty_label.visible = status_entries.is_empty()
	container.visible = not status_entries.is_empty()

	if status_entries.is_empty():
		return

	for entry_variant in status_entries:
		if not (entry_variant is Dictionary):
			continue
		var badge = STATUS_BADGE_SCENE.instantiate()
		container.add_child(badge)
		if badge != null and badge.has_method("configure_from_entry"):
			badge.call("configure_from_entry", entry_variant)

func _show_card_feedback(message: String) -> void:
	_card_feedback_label.text = message
	_card_feedback_label.tooltip_text = message
	_card_feedback_label.modulate = Color(1.12, 1.0, 0.8, 1.0)
	var tween := create_tween()
	tween.tween_property(_card_feedback_label, "scale", Vector2(1.03, 1.03), 0.06)
	tween.parallel().tween_property(_card_feedback_label, "modulate", Color(1.12, 1.0, 0.8, 1.0), 0.06)
	tween.tween_property(_card_feedback_label, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(_card_feedback_label, "modulate", Color(0.95, 0.9, 0.82, 1.0), 0.12)

func _run_enemy_turn_sequence() -> void:
	_set_live_battle_ui_interactable(false)
	_refresh_placeholder_view()
	_show_card_feedback("Enemy turn")
	await _play_turn_banner("Enemy Turn")
	var current_snapshot := _turn_controller.get_placeholder_turn_snapshot()
	var current_intent_data: Dictionary = current_snapshot.get("enemy_intent_data", {}) if current_snapshot.get("enemy_intent_data", {}) is Dictionary else {}
	await _play_enemy_action_animation(current_intent_data)
	var action_report := _turn_controller.resolve_placeholder_enemy_turn()
	_refresh_placeholder_view()
	await _play_action_report(action_report)
	var post_enemy_snapshot := _turn_controller.get_placeholder_turn_snapshot()
	var battle_result := str(post_enemy_snapshot.get("battle_result", ""))
	if battle_result == RESULT_PENDING:
		_turn_controller.begin_next_placeholder_turn()
		_refresh_placeholder_view()
		_show_card_feedback("Player turn")
		await _play_turn_banner("Player Turn")
	else:
		_refresh_placeholder_view()

func _play_action_report(action_report: Dictionary) -> void:
	var events: Array = action_report.get("events", []) if action_report.get("events", []) is Array else []
	if events.is_empty():
		return

	for event_variant in events:
		if not (event_variant is Dictionary):
			continue
		var event_type := str(event_variant.get("type", ""))
		match event_type:
			"enemy_action":
				_show_card_feedback("Enemy attacks for %s" % int(event_variant.get("value", 0)))
			"enemy_hit":
				await _play_enemy_hit_feedback(event_variant)
			"player_hit":
				await _play_player_hit_feedback(event_variant)

func _play_turn_banner(text_value: String) -> void:
	_turn_banner_label.text = text_value
	_turn_banner_label.modulate = Color(0.98, 0.94, 0.84, 0.0)
	_turn_banner_label.scale = Vector2(0.96, 0.96)
	_turn_banner_label.visible = true
	var tween := create_tween()
	tween.tween_property(_turn_banner_label, "modulate", Color(0.98, 0.94, 0.84, 1.0), 0.12)
	tween.parallel().tween_property(_turn_banner_label, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(0.26)
	tween.tween_property(_turn_banner_label, "modulate", Color(0.98, 0.94, 0.84, 0.0), 0.16)
	await tween.finished
	_turn_banner_label.visible = false

func _play_enemy_action_animation(intent_data: Dictionary) -> void:
	if str(intent_data.get("type", "")) == "attack":
		await _shake_control(_enemy_image, Vector2(10, 0), 0.16)
	else:
		await get_tree().create_timer(0.12).timeout

func _play_enemy_hit_feedback(event_data: Dictionary) -> void:
	var damage := int(event_data.get("damage", event_data.get("value", 0)))
	_spawn_floating_text(_enemy_image, "-%s" % damage, Color(1.0, 0.52, 0.42, 1.0), Vector2(0, -54))
	await _shake_control(_enemy_image, Vector2(14, 6), 0.18)

func _play_player_hit_feedback(event_data: Dictionary) -> void:
	var blocked := int(event_data.get("blocked", 0))
	var damage := int(event_data.get("damage", 0))
	if damage > 0:
		_spawn_floating_text(_player_resource_bar, "-%s" % damage, Color(1.0, 0.54, 0.46, 1.0), Vector2(-80, -36))
	if blocked > 0:
		_spawn_floating_text(_player_resource_bar, "Block %s" % blocked, Color(0.52, 0.84, 1.0, 1.0), Vector2(86, -34))
	await _shake_screen(Vector2(10, 8), 0.18)

func _spawn_floating_text(anchor_control: Control, feedback_text: String, feedback_color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var floating_text = FLOATING_TEXT_SCENE.instantiate()
	_floating_text_mount.add_child(floating_text)
	var anchor_rect := anchor_control.get_global_rect()
	var mount_origin := _floating_text_mount.get_global_position()
	floating_text.position = anchor_rect.get_center() - mount_origin + offset
	if floating_text.has_method("play_feedback"):
		floating_text.call("play_feedback", feedback_text, feedback_color)

func _shake_control(target: Control, magnitude: Vector2, duration: float) -> void:
	var start_position := target.position
	var tween := create_tween()
	tween.tween_property(target, "position", start_position + Vector2(magnitude.x, -magnitude.y * 0.4), duration * 0.25)
	tween.tween_property(target, "position", start_position + Vector2(-magnitude.x, magnitude.y * 0.5), duration * 0.35)
	tween.tween_property(target, "position", start_position + Vector2(magnitude.x * 0.4, -magnitude.y * 0.2), duration * 0.2)
	tween.tween_property(target, "position", start_position, duration * 0.2)
	await tween.finished

func _shake_screen(magnitude: Vector2, duration: float) -> void:
	var targets: Array[Control] = [_background, _shading, _content_root]
	var tween := create_tween()
	for target in targets:
		target.position = Vector2.ZERO
	tween.tween_callback(func() -> void:
		for target in targets:
			target.position = Vector2(magnitude.x, -magnitude.y * 0.4)
	)
	tween.tween_interval(duration * 0.25)
	tween.tween_callback(func() -> void:
		for target in targets:
			target.position = Vector2(-magnitude.x, magnitude.y * 0.5)
	)
	tween.tween_interval(duration * 0.35)
	tween.tween_callback(func() -> void:
		for target in targets:
			target.position = Vector2(magnitude.x * 0.35, -magnitude.y * 0.2)
	)
	tween.tween_interval(duration * 0.2)
	tween.tween_callback(func() -> void:
		for target in targets:
			target.position = Vector2.ZERO
	)
	tween.tween_interval(duration * 0.2)
	await tween.finished
