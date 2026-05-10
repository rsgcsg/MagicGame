class_name BattleTurnController
extends Node

const BATTLE_STATE_SCRIPT := preload("res://scripts/battle/battle_state.gd")

var _battle_state: RefCounted
var _battle_context: Dictionary = {}

func get_placeholder_turn_snapshot() -> Dictionary:
	_ensure_placeholder_state()

	return {
		"phase": _battle_state.phase,
		"battle_result": _battle_state.battle_result,
		"turn_number": _battle_state.turn_number,
		"enemy_name": _battle_state.enemy_state.get("name", "Slime"),
		"enemy_id": _battle_state.get_current_enemy_id(),
		"enemy_icon_path": str(_battle_state.enemy_state.get("icon_path", "")),
		"enemy_current_hp": int(_battle_state.enemy_state.get("current_hp", 0)),
		"enemy_max_hp": int(_battle_state.enemy_state.get("max_hp", 0)),
		"enemy_hp_text": "%s/%s HP" % [_battle_state.enemy_state.get("current_hp", 0), _battle_state.enemy_state.get("max_hp", 0)],
		"enemy_status_rows": _battle_state.get_enemy_status_rows(),
		"enemy_status_entries": _battle_state.get_enemy_status_entries(),
		"enemy_status_text": "\n".join(_battle_state.get_enemy_status_rows()),
		"hand_size": _battle_state.hand.size(),
		"action_points": _battle_state.action_points,
		"player_block": _battle_state.block,
		"player_block_text": "%s Block" % _battle_state.block,
		"player_status_rows": _battle_state.get_player_status_rows(),
		"player_status_entries": _battle_state.get_player_status_entries(),
		"player_status_text": "\n".join(_battle_state.get_player_status_rows()),
		"enemy_intent": _battle_state.get_current_enemy_intent_text(),
		"enemy_intent_data": _battle_state.get_current_enemy_intent_data(),
		"battle_mana_text": "%s/%s Mana" % [_battle_state.mana, _battle_state.max_mana],
		"draw_pile_text": "%s cards" % _battle_state.draw_pile.size(),
		"discard_pile_text": "%s cards" % _battle_state.discard_pile.size(),
		"deck_text": "%s cards" % _get_placeholder_deck_size(),
		"deck_source_text": str(_battle_state.deck_source).replace("_", " ").capitalize(),
		"hand_cards": _battle_state.hand.duplicate(true),
		"result_handoff": _battle_state.get_result_handoff_data(),
	}

func reset_placeholder_turn() -> Dictionary:
	start_placeholder_battle(_battle_context)
	return get_placeholder_turn_snapshot()

func end_placeholder_turn() -> bool:
	_ensure_placeholder_state()
	return bool(_battle_state.call("end_player_turn"))

func resolve_placeholder_enemy_turn() -> Dictionary:
	_ensure_placeholder_state()
	var report: Variant = _battle_state.call("resolve_enemy_turn")
	return report.duplicate(true) if report is Dictionary else {}

func begin_next_placeholder_turn() -> bool:
	_ensure_placeholder_state()
	return bool(_battle_state.call("begin_next_player_turn"))

func play_placeholder_card(instance_id: String, target_id := "") -> bool:
	_ensure_placeholder_state()
	return bool(_battle_state.call("play_card", instance_id, target_id))

func discard_placeholder_card(instance_id: String) -> bool:
	_ensure_placeholder_state()
	return bool(_battle_state.call("discard_card", instance_id))

func consume_last_action_report() -> Dictionary:
	_ensure_placeholder_state()
	if _battle_state == null or not _battle_state.has_method("consume_last_action_report"):
		return {}
	var report: Variant = _battle_state.call("consume_last_action_report")
	return report.duplicate(true) if report is Dictionary else {}

func start_placeholder_battle(battle_context: Dictionary = {}) -> void:
	_battle_context = battle_context.duplicate(true)
	_battle_state = BATTLE_STATE_SCRIPT.new()
	_battle_state.setup_placeholder_battle(_battle_context.get("battle_cards", []), _battle_context)

func _ensure_placeholder_state() -> void:
	if _battle_state == null:
		start_placeholder_battle(_battle_context)

func _get_placeholder_deck_size() -> int:
	return _battle_state.draw_pile.size() + _battle_state.hand.size() + _battle_state.discard_pile.size() + _battle_state.consumed_cards.size()
