class_name BattleState
extends RefCounted

const GAME_CONSTANTS := preload("res://scripts/common/game_constants.gd")
const BATTLE_STATUS_RULES := preload("res://scripts/battle/battle_status_rules.gd")
const BATTLE_PLACEHOLDER_CONTENT := preload("res://scripts/battle/battle_placeholder_content.gd")

const PHASE_SETUP := "setup"
const PHASE_PLAYER_TURN := "player_turn"
const PHASE_ENEMY_TURN := "enemy_turn"
const PHASE_VICTORY := "victory"
const PHASE_FAILURE := "failure"

const RESULT_PENDING := "pending"
const RESULT_VICTORY := "victory"
const RESULT_FAILURE := "failure"

const TARGET_NONE := "none"
const TARGET_SELF := "self"
const TARGET_ENEMY := "enemy"

const EFFECT_DAMAGE := "damage"
const EFFECT_ENEMY_HEAL := "enemy_heal"
const EFFECT_BLOCK := "block"
const EFFECT_DRAW := "draw"
const EFFECT_DISCARD := "discard"
const EFFECT_ACTION_POINTS := "action_points"
const EFFECT_MANA := "mana"
const EFFECT_STATUS := "status"

const ACTION_PLAY_CARD := "play_card"
const ACTION_ENEMY_TURN := "enemy_turn"
const EVENT_ENEMY_ACTION := "enemy_action"
const EVENT_ENEMY_HIT := "enemy_hit"
const EVENT_PLAYER_HIT := "player_hit"

var phase := PHASE_PLAYER_TURN
var turn_number := 1
var max_hand_size := GAME_CONSTANTS.DEFAULT_HAND_SIZE
var max_action_points := GAME_CONSTANTS.DEFAULT_ACTION_POINTS
var action_points := GAME_CONSTANTS.DEFAULT_ACTION_POINTS
var mana := GAME_CONSTANTS.DEFAULT_CURRENT_MANA
var max_mana := GAME_CONSTANTS.DEFAULT_MAX_MANA
var block := 0
var deck_source := "debug_default"
var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var consumed_cards: Array = []
var enemy_state := {}
var player_statuses := BATTLE_STATUS_RULES.build_empty_statuses()
var battle_result := RESULT_PENDING
var _last_action_report := {}
var _current_action_events: Array[Dictionary] = []

func setup_placeholder_battle(starting_deck: Array = [], battle_context: Dictionary = {}) -> void:
	phase = PHASE_PLAYER_TURN
	turn_number = 1
	max_hand_size = GAME_CONSTANTS.DEFAULT_HAND_SIZE
	max_action_points = GAME_CONSTANTS.DEFAULT_ACTION_POINTS
	action_points = max_action_points
	max_mana = int(battle_context.get("max_mana", GAME_CONSTANTS.DEFAULT_MAX_MANA))
	mana = int(battle_context.get("starting_mana", battle_context.get("current_mana", GAME_CONSTANTS.DEFAULT_CURRENT_MANA)))
	mana = clampi(mana, 0, max_mana)
	block = 0
	deck_source = str(battle_context.get("deck_source", "debug_default"))
	var allow_debug_fallback := bool(battle_context.get("allow_debug_fallback_deck", deck_source == "debug_default"))
	draw_pile = BATTLE_PLACEHOLDER_CONTENT.build_draw_pile(starting_deck, allow_debug_fallback)
	hand = []
	discard_pile = []
	consumed_cards = []
	player_statuses = BATTLE_STATUS_RULES.build_empty_statuses()
	enemy_state = BATTLE_PLACEHOLDER_CONTENT.build_enemy_state(str(battle_context.get("enemy_id", "slime")), battle_context)
	battle_result = RESULT_PENDING
	_last_action_report = {}
	_current_action_events = []
	draw_to_hand_limit()

func draw_to_hand_limit() -> void:
	while hand.size() < max_hand_size:
		if not _draw_one_card():
			return

func end_player_turn() -> bool:
	if phase != PHASE_PLAYER_TURN:
		return false
	phase = PHASE_ENEMY_TURN
	action_points = 0
	return true

func resolve_enemy_turn() -> Dictionary:
	if phase != PHASE_ENEMY_TURN:
		return {}

	_start_action_capture(ACTION_ENEMY_TURN, {
		"phase": phase,
		"turn_number": turn_number,
		"intent_data": get_current_enemy_intent_data(),
	})
	resolve_placeholder_enemy_action()
	if mana <= 0:
		_mark_failure()
	_finish_action_capture({
		"phase": phase,
		"battle_result": battle_result,
	})
	return _last_action_report.duplicate(true)

func begin_next_player_turn() -> bool:
	if phase != PHASE_ENEMY_TURN or battle_result != RESULT_PENDING:
		return false
	turn_number += 1
	phase = PHASE_PLAYER_TURN
	action_points = max_action_points
	draw_to_hand_limit()
	return true

func resolve_placeholder_enemy_action() -> void:
	var intent_data := get_current_enemy_intent_data()
	if str(intent_data.get("type", "")) != "attack":
		return

	var attack_value := int(intent_data.get("value", 0))
	if attack_value <= 0:
		return
	_append_action_event({
		"type": EVENT_ENEMY_ACTION,
		"intent_type": "attack",
		"value": attack_value,
		"target": TARGET_SELF,
	})

	var modified_damage := BATTLE_STATUS_RULES.apply_outgoing_damage_modifiers(attack_value, _get_enemy_statuses())
	modified_damage = BATTLE_STATUS_RULES.apply_incoming_damage_modifiers(modified_damage, player_statuses)
	_apply_player_damage(modified_damage)

func _mark_failure() -> void:
	mana = 0
	phase = PHASE_FAILURE
	battle_result = RESULT_FAILURE

func _mark_victory() -> void:
	phase = PHASE_VICTORY
	battle_result = RESULT_VICTORY

func play_card(instance_id: String, target_id := "") -> bool:
	if phase != PHASE_PLAYER_TURN:
		return false

	var card_index := _find_card_index_in_hand(instance_id)
	if card_index == -1:
		return false

	var card: Dictionary = hand[card_index]
	var card_cost := int(card.get("cost", 0))
	if action_points < card_cost:
		return false

	var resolved_target_id := _resolve_target_id(card, target_id)
	if not _is_valid_target_for_card(card, resolved_target_id):
		return false

	_start_action_capture(ACTION_PLAY_CARD, {
		"phase": phase,
		"turn_number": turn_number,
		"instance_id": instance_id,
		"card_name": str(card.get("name", "")),
	})
	action_points -= card_cost
	hand.remove_at(card_index)
	_apply_card_effects(card, resolved_target_id)

	if bool(card.get("consumable", true)):
		consumed_cards.append(card)
	else:
		discard_pile.append(card)

	if mana <= 0:
		_mark_failure()
	_finish_action_capture({
		"phase": phase,
		"battle_result": battle_result,
	})
	return true

func discard_card(instance_id: String) -> bool:
	if phase != PHASE_PLAYER_TURN:
		return false

	var card_index := _find_card_index_in_hand(instance_id)
	if card_index == -1:
		return false

	var card: Dictionary = hand[card_index]
	hand.remove_at(card_index)
	discard_pile.append(card)
	return true

func get_placeholder_card_effect(card_id: String) -> Dictionary:
	return BATTLE_PLACEHOLDER_CONTENT.get_placeholder_card_effect(card_id)

func get_current_enemy_id() -> String:
	return str(enemy_state.get("enemy_id", ""))

func get_current_enemy_intent_data() -> Dictionary:
	var intent_data = enemy_state.get("intent_data", {})
	if intent_data is Dictionary:
		return intent_data.duplicate(true)
	return {}

func get_current_enemy_intent_text() -> String:
	var intent_data := get_current_enemy_intent_data()
	return str(intent_data.get("display_name", "Unknown"))

func get_result_handoff_data() -> Dictionary:
	return {
		"battle_result": battle_result,
		"result_type": battle_result,
		"phase": phase,
		"enemy_id": get_current_enemy_id(),
		"victory": battle_result == RESULT_VICTORY,
		"failure": battle_result == RESULT_FAILURE,
		"failure_reason": "mana_depleted" if battle_result == RESULT_FAILURE else "",
		"mana_remaining": mana,
		"remaining_mana": mana,
		"remaining_block": block,
		"turn_number": turn_number,
		"hand_count": hand.size(),
		"draw_count": draw_pile.size(),
		"discard_count": discard_pile.size(),
		"consumed_card_ids": _get_consumed_card_ids(),
		"consumed_source_runtime_ids": _get_consumed_source_runtime_ids(),
		"deck_source": deck_source,
	}

func get_player_status_rows() -> Array[String]:
	return BATTLE_STATUS_RULES.build_status_rows(player_statuses)

func get_enemy_status_rows() -> Array[String]:
	return BATTLE_STATUS_RULES.build_status_rows(_get_enemy_statuses())

func get_player_status_entries() -> Array[Dictionary]:
	return BATTLE_STATUS_RULES.build_status_entries(player_statuses)

func get_enemy_status_entries() -> Array[Dictionary]:
	return BATTLE_STATUS_RULES.build_status_entries(_get_enemy_statuses())

func consume_last_action_report() -> Dictionary:
	var report := _last_action_report.duplicate(true)
	_last_action_report = {}
	return report

func _find_card_index_in_hand(instance_id: String) -> int:
	for card_index in range(hand.size()):
		var card = hand[card_index]
		if card is Dictionary and str(card.get("instance_id", "")) == instance_id:
			return card_index
	return -1

func _apply_card_effects(card: Dictionary, target_id: String) -> void:
	var effect_data := _resolve_card_effect_data(card)
	var effect_entries: Array = effect_data.get("effects", [])
	if effect_entries.is_empty():
		_apply_legacy_effect_data(effect_data, target_id)
		return

	for effect_entry_variant in effect_entries:
		if not (effect_entry_variant is Dictionary):
			continue
		_apply_effect_entry(effect_entry_variant, target_id)

func _apply_legacy_effect_data(effect_data: Dictionary, target_id: String) -> void:
	var block_gain := int(effect_data.get("block", 0))
	if block_gain > 0:
		_apply_block_delta(block_gain)

	var damage := int(effect_data.get("damage", 0))
	if damage > 0:
		_apply_enemy_damage(target_id, damage)

func _apply_effect_entry(effect_entry: Dictionary, target_id: String) -> void:
	var effect_type := str(effect_entry.get("type", ""))
	var value := int(effect_entry.get("value", 0))
	var resolved_target := str(effect_entry.get("target", TARGET_NONE))
	if resolved_target == TARGET_ENEMY and target_id.is_empty():
		resolved_target = TARGET_ENEMY

	match effect_type:
		EFFECT_DAMAGE:
			if resolved_target == TARGET_ENEMY:
				_apply_enemy_damage(target_id, value)
		EFFECT_ENEMY_HEAL:
			if resolved_target == TARGET_ENEMY:
				_apply_enemy_heal(target_id, value)
		EFFECT_BLOCK:
			if resolved_target == TARGET_SELF:
				_apply_block_delta(value)
		EFFECT_DRAW:
			if resolved_target == TARGET_SELF:
				_draw_cards(value)
		EFFECT_DISCARD:
			if resolved_target == TARGET_SELF:
				_discard_cards_from_hand(value)
		EFFECT_ACTION_POINTS:
			if resolved_target == TARGET_SELF:
				_modify_action_points(value)
		EFFECT_MANA:
			if resolved_target == TARGET_SELF:
				_modify_mana(value)
		EFFECT_STATUS:
			_apply_status_effect(resolved_target, str(effect_entry.get("status_id", "")), value)

func _apply_enemy_damage(target_id: String, base_damage: int) -> void:
	if base_damage <= 0 or not _is_valid_enemy_target(target_id):
		return
	var modified_damage := BATTLE_STATUS_RULES.apply_outgoing_damage_modifiers(base_damage, player_statuses)
	modified_damage = BATTLE_STATUS_RULES.apply_incoming_damage_modifiers(modified_damage, _get_enemy_statuses())
	var current_hp := int(enemy_state.get("current_hp", 0))
	enemy_state["current_hp"] = max(0, current_hp - modified_damage)
	_append_action_event({
		"type": EVENT_ENEMY_HIT,
		"target": TARGET_ENEMY,
		"damage": modified_damage,
		"value": modified_damage,
	})
	if int(enemy_state.get("current_hp", 0)) <= 0:
		_mark_victory()

func _apply_enemy_heal(target_id: String, amount: int) -> void:
	if amount <= 0 or not _is_valid_enemy_target(target_id):
		return
	var current_hp := int(enemy_state.get("current_hp", 0))
	var max_hp := int(enemy_state.get("max_hp", current_hp))
	enemy_state["current_hp"] = mini(max_hp, current_hp + amount)

func _apply_player_damage(base_damage: int) -> void:
	if base_damage <= 0:
		return
	var blocked_damage: int = mini(block, base_damage)
	block -= blocked_damage
	var unblocked_damage: int = base_damage - blocked_damage
	_append_action_event({
		"type": EVENT_PLAYER_HIT,
		"target": TARGET_SELF,
		"blocked": blocked_damage,
		"damage": unblocked_damage,
		"value": unblocked_damage,
		"total": base_damage,
	})
	if unblocked_damage > 0:
		mana = max(0, mana - unblocked_damage)

func _apply_block_delta(raw_delta: int) -> void:
	block = BATTLE_STATUS_RULES.apply_block_delta(block, raw_delta, player_statuses)

func _draw_cards(amount: int) -> void:
	for _index in range(maxi(0, amount)):
		if not _draw_one_card():
			return

func _draw_one_card() -> bool:
	if hand.size() >= max_hand_size:
		return false
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		draw_pile = discard_pile.duplicate(true)
		discard_pile = []
		draw_pile.shuffle()
	if draw_pile.is_empty():
		return false
	hand.append(draw_pile.pop_front())
	return true

func _discard_cards_from_hand(amount: int) -> void:
	for _index in range(maxi(0, amount)):
		if hand.is_empty():
			return
		var discarded_card = hand.pop_back()
		discard_pile.append(discarded_card)

func _modify_action_points(delta: int) -> void:
	action_points = maxi(0, action_points + delta)

func _modify_mana(delta: int) -> void:
	mana = clampi(mana + delta, 0, max_mana)

func _apply_status_effect(target: String, status_id: String, value: int) -> void:
	if status_id.is_empty() or value == 0:
		return
	var status_bucket := player_statuses if target == TARGET_SELF else _get_enemy_statuses()
	if not status_bucket.has(status_id):
		return
	if BATTLE_STATUS_RULES.is_signed_status(status_id):
		status_bucket[status_id] = int(status_bucket.get(status_id, 0)) + value
	else:
		status_bucket[status_id] = maxi(0, int(status_bucket.get(status_id, 0)) + value)
	if target == TARGET_ENEMY:
		enemy_state["statuses"] = status_bucket

func _get_consumed_card_ids() -> Array[String]:
	var consumed_card_ids: Array[String] = []
	for card in consumed_cards:
		if card is Dictionary:
			consumed_card_ids.append(str(card.get("card_id", card.get("instance_id", ""))))
	return consumed_card_ids

func _get_consumed_source_runtime_ids() -> Array[String]:
	var runtime_ids: Array[String] = []
	for card in consumed_cards:
		if not (card is Dictionary):
			continue
		var runtime_id := str(card.get("source_runtime_id", ""))
		if runtime_id.is_empty():
			continue
		runtime_ids.append(runtime_id)
	return runtime_ids

func _resolve_target_id(card: Dictionary, requested_target_id: String) -> String:
	var effect_data := _resolve_card_effect_data(card)
	if str(effect_data.get("target", TARGET_NONE)) == TARGET_ENEMY and requested_target_id.is_empty():
		return get_current_enemy_id()
	return requested_target_id

func _is_valid_target_for_card(card: Dictionary, target_id: String) -> bool:
	var effect_data := _resolve_card_effect_data(card)
	var target_type := str(effect_data.get("target", TARGET_NONE))
	if target_type == TARGET_ENEMY:
		return _is_valid_enemy_target(target_id)
	return true

func _is_valid_enemy_target(target_id: String) -> bool:
	return not target_id.is_empty() and target_id == get_current_enemy_id() and int(enemy_state.get("current_hp", 0)) > 0

func _resolve_card_effect_data(card: Dictionary) -> Dictionary:
	var inline_effect_data: Variant = card.get("effect_data", {})
	if inline_effect_data is Dictionary and not inline_effect_data.is_empty():
		return inline_effect_data.duplicate(true)
	return get_placeholder_card_effect(str(card.get("card_id", "")))

func _get_enemy_statuses() -> Dictionary:
	var statuses_variant = enemy_state.get("statuses", {})
	if statuses_variant is Dictionary:
		return statuses_variant
	var fallback := BATTLE_STATUS_RULES.build_empty_statuses()
	enemy_state["statuses"] = fallback
	return fallback

func _start_action_capture(action_type: String, metadata: Dictionary = {}) -> void:
	_current_action_events = []
	_last_action_report = {"action_type": action_type}
	for key in metadata.keys():
		_last_action_report[key] = metadata[key]

func _append_action_event(event_data: Dictionary) -> void:
	if event_data.is_empty():
		return
	_current_action_events.append(event_data.duplicate(true))

func _finish_action_capture(metadata: Dictionary = {}) -> void:
	var report := _last_action_report.duplicate(true)
	for key in metadata.keys():
		report[key] = metadata[key]
	report["events"] = _current_action_events.duplicate(true)
	_last_action_report = report
	_current_action_events = []
