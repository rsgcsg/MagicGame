extends Node

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const GAME_CONSTANTS := preload("res://scripts/common/game_constants.gd")
const GENERATED_CARD_BUILDER := preload("res://scripts/cards/generated_card_builder.gd")

signal battle_state_changed
signal battle_result_handoff_requested(result_data: Dictionary)

const RESULT_VICTORY := "victory"
const RESULT_FAILURE := "failure"

const NODE_STATE_CLEARED := "cleared"
const NODE_STATE_FAILED := "failed"
const NODE_STATE_REWARD_CLAIMED := "reward_claimed"
const NODE_STATE_UNRESOLVED := "unresolved"

var current_battle: Dictionary = {}
var current_battle_entry_context: Dictionary = {}
var last_battle_result_handoff: Dictionary = {}
var pending_realm_result := false

@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

func start_placeholder_battle_from_realm(context: Dictionary) -> void:
	current_battle_entry_context = _merge_with_default_entry_context(context)
	current_battle = current_battle_entry_context.duplicate(true)
	last_battle_result_handoff = {}
	pending_realm_result = false
	battle_state_changed.emit()

func setup_placeholder_battle() -> void:
	if current_battle_entry_context.is_empty():
		current_battle_entry_context = get_debug_battle_entry_context()

	var battle_cards := _build_battle_cards_for_current_context()
	var is_debug_battle := str(current_battle_entry_context.get("node_type", "")) == "debug_battle"
	var using_realm_loadout := not battle_cards.is_empty()
	var deck_source := "realm_loadout" if using_realm_loadout else ("debug_default" if is_debug_battle else "empty_realm_loadout")
	current_battle = {
		"battle_id": current_battle_entry_context.get("battle_id", "debug_battle_01"),
		"realm_id": current_battle_entry_context.get("realm_id", "debug_realm"),
		"source_node_id": current_battle_entry_context.get("source_node_id", "debug_battle"),
		"encounter_id": current_battle_entry_context.get("encounter_id", "debug_slime_encounter"),
		"enemy_id": current_battle_entry_context.get("enemy_id", "slime"),
		"action_points": GAME_CONSTANTS.DEFAULT_ACTION_POINTS,
		"hand_size": GAME_CONSTANTS.DEFAULT_HAND_SIZE,
		"intent": "Attack 15",
		"battle_cards": battle_cards,
		"deck_source": deck_source,
		"allow_debug_fallback_deck": is_debug_battle,
		"loadout_card_count": battle_cards.size(),
	}
	battle_state_changed.emit()

func get_current_battle_entry_context() -> Dictionary:
	if current_battle_entry_context.is_empty():
		current_battle_entry_context = get_debug_battle_entry_context()

	return current_battle_entry_context.duplicate(true)

func get_debug_battle_entry_context() -> Dictionary:
	return _merge_with_default_entry_context({
		"battle_id": "debug_battle_01",
		"realm_id": "debug_realm",
		"source_node_id": "debug_battle",
		"encounter_id": "debug_slime_encounter",
		"enemy_id": "slime",
		"node_type": "debug_battle",
		"difficulty_hint": "debug",
		"return_target": SCENE_PATHS.ALCHEMY_SHOP,
	})

func report_placeholder_battle_result(result_data: Dictionary) -> void:
	last_battle_result_handoff = build_battle_result_payload(result_data)
	pending_realm_result = false
	battle_result_handoff_requested.emit(last_battle_result_handoff)

func acknowledge_victory_reward(selected_reward: Dictionary) -> Dictionary:
	if last_battle_result_handoff.is_empty():
		return {}

	last_battle_result_handoff["selected_reward"] = selected_reward.duplicate(true)
	last_battle_result_handoff["reward_acknowledged"] = true
	last_battle_result_handoff["target_node_state"] = NODE_STATE_REWARD_CLAIMED
	pending_realm_result = _should_queue_realm_result(last_battle_result_handoff)
	battle_result_handoff_requested.emit(last_battle_result_handoff)
	return last_battle_result_handoff.duplicate(true)

func acknowledge_defeat() -> Dictionary:
	if last_battle_result_handoff.is_empty():
		return {}

	last_battle_result_handoff["result_type"] = RESULT_FAILURE
	last_battle_result_handoff["battle_result"] = RESULT_FAILURE
	last_battle_result_handoff["failure_reason"] = str(last_battle_result_handoff.get("failure_reason", "mana_depleted"))
	last_battle_result_handoff["target_node_state"] = NODE_STATE_FAILED
	last_battle_result_handoff["reward_acknowledged"] = false
	last_battle_result_handoff["failure_policy_id"] = str(last_battle_result_handoff.get("failure_policy_id", "mana_zero_expedition_failure_placeholder"))
	pending_realm_result = _should_queue_realm_result(last_battle_result_handoff)
	battle_result_handoff_requested.emit(last_battle_result_handoff)
	return last_battle_result_handoff.duplicate(true)

func consume_latest_battle_result_for_realm() -> Dictionary:
	if not pending_realm_result:
		return {}

	pending_realm_result = false
	return last_battle_result_handoff.duplicate(true)

func build_battle_result_payload(battle_facts: Dictionary) -> Dictionary:
	var context := get_current_battle_entry_context()
	var battle_result := str(battle_facts.get("battle_result", battle_facts.get("result_type", "")))
	var is_victory := battle_result == RESULT_VICTORY
	var is_failure := battle_result == RESULT_FAILURE
	var payload := context.duplicate(true)
	var result_reason := "pending"
	if is_victory:
		result_reason = "enemy_defeated"
	elif is_failure:
		result_reason = "mana_depleted"
	var target_node_state := NODE_STATE_UNRESOLVED
	if is_victory:
		target_node_state = NODE_STATE_CLEARED
	elif is_failure:
		target_node_state = NODE_STATE_FAILED
	payload["result_type"] = battle_result
	payload["battle_result"] = battle_result
	payload["result_reason"] = result_reason
	payload["failure_reason"] = "mana_depleted" if is_failure else ""
	payload["enemy_id"] = str(battle_facts.get("enemy_id", context.get("enemy_id", "slime")))
	payload["node_type"] = str(context.get("node_type", "normal_battle"))
	payload["mana_remaining"] = int(battle_facts.get("mana_remaining", battle_facts.get("remaining_mana", GAME_CONSTANTS.DEFAULT_CURRENT_MANA)))
	payload["remaining_block"] = int(battle_facts.get("remaining_block", 0))
	payload["turn_number"] = int(battle_facts.get("turn_number", 1))
	payload["hand_count"] = int(battle_facts.get("hand_count", 0))
	payload["draw_count"] = int(battle_facts.get("draw_count", 0))
	payload["discard_count"] = int(battle_facts.get("discard_count", 0))
	payload["consumed_card_ids"] = battle_facts.get("consumed_card_ids", [])
	payload["consumed_source_runtime_ids"] = battle_facts.get("consumed_source_runtime_ids", [])
	payload["reward_options"] = get_placeholder_reward_options()
	payload["auto_material_bundle"] = _build_auto_material_loot(context) if is_victory else {}
	payload["auto_gold_reward"] = _build_auto_gold_reward(context) if is_victory else 0
	payload["selected_reward"] = battle_facts.get("selected_reward", {})
	payload["reward_acknowledged"] = false
	payload["return_target"] = str(context.get("return_target", SCENE_PATHS.REALM_MAP))
	payload["target_node_state"] = target_node_state
	payload["failure_policy_id"] = str(context.get("failure_policy_id", "mana_zero_expedition_failure_placeholder"))
	var consumed_card_ids = payload["consumed_card_ids"]
	var consumed_card_count: int = consumed_card_ids.size() if consumed_card_ids is Array else 0
	payload["rest_site_hook"] = {
		"remaining_mana": payload["mana_remaining"],
		"consumed_card_count": consumed_card_count,
	}
	payload["card_lifecycle_hook"] = {
		"hand_limit": GAME_CONSTANTS.DEFAULT_HAND_SIZE,
		"played_cards_consumed": true,
		"discard_reshuffles": true,
	}
	return payload

func get_placeholder_reward_options() -> Array:
	var context := get_current_battle_entry_context()
	if str(context.get("node_type", "")) == "debug_battle":
		return [
			{
				"reward_id": "skip_reward",
				"reward_type": "skip",
				"display_name": "Return to Workshop",
				"description": "Direct debug battle launches do not apply realm rewards.",
			},
		]
	if str(context.get("node_type", "")) == "boss_battle":
		return [
			{
				"reward_id": "material_fire_wind_bundle",
				"reward_type": "material",
				"display_name": "Take Rare Material",
				"description": "Claim a larger boss bundle with a rare alchemical material.",
				"material_bundle": {
					"gravebloom_pollen": 1,
					"stormglass_prism": 1,
					"moonwell_pearl": 2,
					"moss_amber": 1,
				},
			},
			{
				"reward_id": "card_realm_echo",
				"reward_type": "card",
				"display_name": "Take Rare Card",
				"description": "Claim a rarer persistent card forged from the boss core.",
				"generated_card": GENERATED_CARD_BUILDER.build_placeholder_realm_reward_card(
					"hollow_bloom_requiem",
					{
						"display_name": "Hollow Bloom Requiem",
						"description": "A rare boss card that cuts hard and leaves behind a defensive afterimage.",
						"action_point_cost": 2,
						"effect_lines": ["Deal 14 damage", "Gain 6 block"],
						"combat_payload": {
							"target": "enemy",
							"effects": [
								{"type": "damage", "target": "enemy", "value": 14},
								{"type": "block", "target": "self", "value": 6},
							],
						},
						"single_use": false,
					}
				),
			},
			{
				"reward_id": "skip_reward",
				"reward_type": "skip",
				"display_name": "Complete Expedition",
				"description": "Leave the boss reward behind and resolve expedition recovery.",
			},
		]

	return [
		_build_normal_material_reward(context),
		{
			"reward_id": "card_realm_echo",
			"reward_type": "card",
			"display_name": "Take Card",
			"description": "Add a generated card to the current expedition backpack.",
			"generated_card": GENERATED_CARD_BUILDER.build_placeholder_realm_reward_card(
				"realm_echo",
				{
					"display_name": "Realm Echo",
					"description": "A reward card shaped by leftover realm energy.",
					"effect_lines": ["Deal 9 damage", "Gain 4 block"],
					"combat_payload": {
						"target": "enemy",
						"effects": [
							{"type": "damage", "target": "enemy", "value": 9},
							{"type": "block", "target": "self", "value": 4},
						],
					},
					"single_use": true,
				}
			),
		},
		{
			"reward_id": "skip_reward",
			"reward_type": "skip",
			"display_name": "Skip Reward",
			"description": "Leave the reward behind and continue.",
		},
	]

func _build_normal_material_reward(context: Dictionary) -> Dictionary:
	var enemy_id := str(context.get("enemy_id", "slime"))
	match enemy_id:
		"cinder_sprite":
			return {
				"reward_id": "material_fire_wind_bundle",
				"reward_type": "material",
				"display_name": "Take Ember Bundle",
				"description": "Add a larger fire-forward bundle to the current expedition backpack.",
				"material_bundle": {
					"fire_crystal": 1,
					"fire_earth_ore": 1,
					"ashvine_fiber": 1,
					"cinder_petal": 1,
				},
			}
		"blue_wisp":
			return {
				"reward_id": "material_fire_wind_bundle",
				"reward_type": "material",
				"display_name": "Take Mist Bundle",
				"description": "Add a larger water-wind bundle to the current expedition backpack.",
				"material_bundle": {
					"water_dew": 1,
					"wind_feather": 1,
					"water_wind_mist": 1,
					"moonwell_pearl": 1,
				},
			}
		_:
			return {
				"reward_id": "material_fire_wind_bundle",
				"reward_type": "material",
				"display_name": "Take Materials",
				"description": "Add a broader 4-unit material bundle to the current expedition backpack.",
				"material_bundle": {
					"fire_crystal": 1,
					"water_dew": 1,
					"earth_stone": 1,
					"wind_feather": 1,
				},
			}

func _build_auto_material_loot(context: Dictionary) -> Dictionary:
	var enemy_id := str(context.get("enemy_id", "slime"))
	match enemy_id:
		"cinder_sprite":
			return {
				"fire_crystal": 4,
				"fire_earth_ore": 3,
				"ashvine_fiber": 3,
				"cinder_petal": 2,
			}
		"blue_wisp":
			return {
				"water_dew": 4,
				"wind_feather": 3,
				"water_wind_mist": 3,
				"moonwell_pearl": 2,
			}
		"hollow_bloom":
			return {
				"moonwell_pearl": 2,
				"moss_amber": 2,
				"stormglass_prism": 1,
				"gravebloom_pollen": 1,
			}
		_:
			return {
				"fire_crystal": 3,
				"water_dew": 3,
				"earth_stone": 3,
				"wind_feather": 3,
			}

func _build_auto_gold_reward(context: Dictionary) -> int:
	var node_type := str(context.get("node_type", "normal_battle"))
	if node_type == "boss_battle":
		return 35
	if node_type == "debug_battle":
		return 0
	return 12

func _merge_with_default_entry_context(context: Dictionary) -> Dictionary:
	var merged := {
		"battle_id": "battle_01",
		"realm_id": "training_realm",
		"source_node_id": "battle_01",
		"encounter_id": "training_slime_01",
		"enemy_id": "slime",
		"node_type": "normal_battle",
		"difficulty_hint": "intro",
		"return_target": SCENE_PATHS.REALM_MAP,
		"reward_set_id": "training_battle_placeholder",
		"failure_policy_id": "mana_zero_expedition_failure_placeholder",
	}
	for key in context.keys():
		merged[key] = context[key]
	return merged

func _build_battle_cards_for_current_context() -> Array[Dictionary]:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("build_active_battle_cards"):
		return []
	return _realm_loadout_manager.call("build_active_battle_cards")

func _should_queue_realm_result(result_payload: Dictionary) -> bool:
	return str(result_payload.get("return_target", "")) == SCENE_PATHS.REALM_MAP
