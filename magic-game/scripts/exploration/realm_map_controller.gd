class_name RealmMapController
extends Node

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")

const NODE_START := "start"
const NODE_BATTLE_LEFT := "battle_left_01"
const NODE_BATTLE_RIGHT := "battle_right_01"
const NODE_REST_LEFT := "rest_left_01"
const NODE_BATTLE_CENTER := "battle_center_01"
const NODE_REST_RIGHT := "rest_right_01"
const NODE_BOSS := "boss_01"

const NODE_TYPE_START := "start"
const NODE_TYPE_BATTLE := "normal_battle"
const NODE_TYPE_REST := "rest_site"
const NODE_TYPE_BOSS := "boss_battle"

const STATE_LOCKED := "locked"
const STATE_AVAILABLE := "available"
const STATE_UNRESOLVED := "unresolved"
const STATE_CLEARED := "cleared"
const STATE_FAILED := "failed"
const STATE_REWARD_CLAIMED := "reward_claimed"

const NODE_DEFINITIONS := {
	NODE_START: {
		"display_name": "Start",
		"node_type": NODE_TYPE_START,
		"next_nodes": [NODE_BATTLE_LEFT, NODE_BATTLE_RIGHT],
	},
	NODE_BATTLE_LEFT: {
		"display_name": "Cinder Sprite",
		"node_type": NODE_TYPE_BATTLE,
		"battle_id": "battle_left_01",
		"encounter_id": "cinder_sprite_left_01",
		"enemy_id": "cinder_sprite",
		"difficulty_hint": "intro_left",
		"next_nodes": [NODE_REST_LEFT, NODE_BATTLE_CENTER],
	},
	NODE_BATTLE_RIGHT: {
		"display_name": "Blue Wisp",
		"node_type": NODE_TYPE_BATTLE,
		"battle_id": "battle_right_01",
		"encounter_id": "blue_wisp_right_01",
		"enemy_id": "blue_wisp",
		"difficulty_hint": "intro_right",
		"next_nodes": [NODE_BATTLE_CENTER, NODE_REST_RIGHT],
	},
	NODE_REST_LEFT: {
		"display_name": "Rest L",
		"node_type": NODE_TYPE_REST,
		"next_nodes": [NODE_BOSS],
	},
	NODE_BATTLE_CENTER: {
		"display_name": "Blue Wisp",
		"node_type": NODE_TYPE_BATTLE,
		"battle_id": "battle_center_01",
		"encounter_id": "blue_wisp_center_01",
		"enemy_id": "blue_wisp",
		"difficulty_hint": "mid",
		"next_nodes": [NODE_BOSS],
	},
	NODE_REST_RIGHT: {
		"display_name": "Rest R",
		"node_type": NODE_TYPE_REST,
		"next_nodes": [NODE_BOSS],
	},
	NODE_BOSS: {
		"display_name": "Hollow Bloom",
		"node_type": NODE_TYPE_BOSS,
		"battle_id": "boss_01",
		"encounter_id": "hollow_bloom_boss_01",
		"enemy_id": "hollow_bloom",
		"difficulty_hint": "boss",
		"next_nodes": [],
	},
}

static var node_states := {}
static var last_applied_battle_result: Dictionary = {}

func get_placeholder_route() -> Array[String]:
	return [
		NODE_START,
		NODE_BATTLE_LEFT,
		NODE_REST_LEFT,
		NODE_BOSS,
	]

static func get_node_ids() -> Array[String]:
	return NODE_DEFINITIONS.keys()

static func get_node_definition(node_id: String) -> Dictionary:
	return NODE_DEFINITIONS.get(node_id, {}).duplicate(true)

static func get_node_state(node_id: String) -> String:
	_ensure_node_states()
	return str(node_states.get(node_id, STATE_LOCKED))

static func get_node_states() -> Dictionary:
	_ensure_node_states()
	return node_states.duplicate(true)

static func get_next_node_ids(node_id: String) -> Array[String]:
	var node_definition: Dictionary = get_node_definition(node_id)
	var next_nodes_variant = node_definition.get("next_nodes", [])
	if next_nodes_variant is Array:
		var next_nodes: Array[String] = []
		for next_node in next_nodes_variant:
			next_nodes.append(str(next_node))
		return next_nodes
	return []

static func reset_placeholder_progress() -> void:
	last_applied_battle_result = {}
	node_states = {}
	for node_id in NODE_DEFINITIONS.keys():
		node_states[node_id] = STATE_LOCKED
	node_states[NODE_START] = STATE_AVAILABLE

static func is_fresh_route_state() -> bool:
	_ensure_node_states()
	if str(node_states.get(NODE_START, STATE_LOCKED)) != STATE_AVAILABLE:
		return false
	for node_id in NODE_DEFINITIONS.keys():
		if node_id == NODE_START:
			continue
		if str(node_states.get(node_id, STATE_LOCKED)) != STATE_LOCKED:
			return false
	return last_applied_battle_result.is_empty()

static func mark_start_completed() -> void:
	complete_node_progress(NODE_START, STATE_REWARD_CLAIMED)

static func mark_rest_completed(node_id: String) -> void:
	complete_node_progress(node_id, STATE_REWARD_CLAIMED)

static func mark_node_unresolved(node_id: String) -> void:
	_ensure_node_states()
	node_states[node_id] = STATE_UNRESOLVED

static func complete_node_progress(node_id: String, final_state := STATE_REWARD_CLAIMED) -> void:
	_ensure_node_states()
	if not node_states.has(node_id):
		return
	node_states[node_id] = final_state
	if final_state == STATE_REWARD_CLAIMED or final_state == STATE_CLEARED:
		_advance_frontier_from(node_id)

static func create_battle_entry_context(source_node_id: String) -> Dictionary:
	var node_definition: Dictionary = get_node_definition(source_node_id)
	var node_type := str(node_definition.get("node_type", NODE_TYPE_BATTLE))
	return {
		"battle_id": str(node_definition.get("battle_id", source_node_id)),
		"realm_id": "training_realm",
		"source_node_id": source_node_id,
		"encounter_id": str(node_definition.get("encounter_id", "%s_encounter" % source_node_id)),
		"enemy_id": str(node_definition.get("enemy_id", "slime")),
		"node_type": node_type,
		"difficulty_hint": str(node_definition.get("difficulty_hint", "intro")),
		"return_target": SCENE_PATHS.REALM_MAP,
		"reward_set_id": "training_battle_placeholder",
		"failure_policy_id": "mana_zero_expedition_failure_placeholder",
	}

static func apply_battle_result(result_payload: Dictionary) -> void:
	_ensure_node_states()
	if result_payload.is_empty():
		return

	last_applied_battle_result = result_payload.duplicate(true)
	var source_node_id := str(result_payload.get("source_node_id", NODE_BATTLE_LEFT))
	var target_node_state := str(result_payload.get("target_node_state", STATE_UNRESOLVED))
	if not node_states.has(source_node_id):
		return

	node_states[source_node_id] = target_node_state
	if target_node_state == STATE_REWARD_CLAIMED or target_node_state == STATE_CLEARED:
		_advance_frontier_from(source_node_id)

static func is_expedition_end_result(result_payload: Dictionary) -> bool:
	var result_type := str(result_payload.get("result_type", result_payload.get("battle_result", "")))
	if result_type == "failure":
		return true
	return result_type == "victory" and str(result_payload.get("node_type", "")) == NODE_TYPE_BOSS

static func _unlock_next_nodes(node_id: String) -> void:
	for next_node_id in get_next_node_ids(node_id):
		if str(node_states.get(next_node_id, STATE_LOCKED)) == STATE_LOCKED:
			node_states[next_node_id] = STATE_AVAILABLE

static func _advance_frontier_from(node_id: String) -> void:
	_replace_available_frontier(get_next_node_ids(node_id))

static func _replace_available_frontier(next_node_ids: Array[String]) -> void:
	for existing_node_id in node_states.keys():
		if str(node_states.get(existing_node_id, STATE_LOCKED)) == STATE_AVAILABLE:
			node_states[existing_node_id] = STATE_LOCKED
	for next_node_id in next_node_ids:
		if not node_states.has(next_node_id):
			continue
		if str(node_states.get(next_node_id, STATE_LOCKED)) == STATE_LOCKED:
			node_states[next_node_id] = STATE_AVAILABLE

static func _ensure_node_states() -> void:
	if node_states.is_empty():
		reset_placeholder_progress()
