class_name BattlePlaceholderContent
extends RefCounted

const BATTLE_STATUS_RULES := preload("res://scripts/battle/battle_status_rules.gd")
const CINDER_SPRITE_ENEMY_DATA := preload("res://data/enemies/cinder_sprite.tres")
const BLUE_WISP_ENEMY_DATA := preload("res://data/enemies/blue_wisp.tres")
const HOLLOW_BLOOM_ENEMY_DATA := preload("res://data/enemies/hollow_bloom.tres")
const SLIME_ENEMY_DATA := preload("res://data/enemies/slime.tres")

const PLACEHOLDER_CARD_EFFECTS := {
	"debug_spark": {
		"target": "enemy",
		"effects": [
			{"type": "damage", "target": "enemy", "value": 6},
		],
	},
	"debug_guard": {
		"target": "self",
		"effects": [
			{"type": "block", "target": "self", "value": 5},
		],
	},
	"debug_focus": {
		"target": "none",
		"effects": [
			{"type": "draw", "target": "self", "value": 1},
			{"type": "action_points", "target": "self", "value": 1},
		],
	},
	"debug_bolt": {
		"target": "enemy",
		"effects": [
			{"type": "damage", "target": "enemy", "value": 10},
		],
	},
	"debug_rune": {
		"target": "self",
		"effects": [
			{"type": "mana", "target": "self", "value": 1},
		],
	},
}

const PLACEHOLDER_DECK := [
	{
		"instance_id": "debug_spark_001",
		"card_id": "debug_spark",
		"name": "Spark",
		"cost": 1,
		"template_id": "triangle",
		"consumable": true,
		"effect_text": "Deal 6 damage.",
		"art_label": "Spark",
	},
	{
		"instance_id": "debug_guard_001",
		"card_id": "debug_guard",
		"name": "Guard",
		"cost": 1,
		"template_id": "square",
		"consumable": true,
		"effect_text": "Gain 5 block.",
		"art_label": "Shield",
	},
	{
		"instance_id": "debug_focus_001",
		"card_id": "debug_focus",
		"name": "Focus",
		"cost": 0,
		"template_id": "ring",
		"consumable": true,
		"effect_text": "Draw 1 card. Gain 1 action point.",
		"art_label": "Focus",
	},
	{
		"instance_id": "debug_bolt_001",
		"card_id": "debug_bolt",
		"name": "Bolt",
		"cost": 2,
		"template_id": "triangle",
		"consumable": true,
		"effect_text": "Deal 10 damage.",
		"art_label": "Bolt",
	},
	{
		"instance_id": "debug_rune_001",
		"card_id": "debug_rune",
		"name": "Rune",
		"cost": 0,
		"template_id": "ring",
		"consumable": true,
		"effect_text": "Gain 1 mana.",
		"art_label": "Rune",
	},
]

static func build_draw_pile(starting_deck: Array, allow_debug_fallback := true) -> Array:
	if starting_deck.is_empty() and allow_debug_fallback:
		return PLACEHOLDER_DECK.duplicate(true)

	var copies: Array = []
	for card in starting_deck:
		if card is Dictionary:
			copies.append(card.duplicate(true))
	return copies

static func get_placeholder_card_effect(card_id: String) -> Dictionary:
	return PLACEHOLDER_CARD_EFFECTS.get(card_id, {}).duplicate(true)

static func build_enemy_state(enemy_id: String, battle_context: Dictionary) -> Dictionary:
	var enemy_data: EnemyData = _get_enemy_data(enemy_id)
	var max_hp := int(battle_context.get("enemy_max_hp", enemy_data.max_health if enemy_data != null else 50))
	var display_name := str(battle_context.get("enemy_name", enemy_data.display_name if enemy_data != null else enemy_id.capitalize()))
	var intent_data := _build_enemy_intent_data(enemy_id, enemy_data)
	return {
		"enemy_id": enemy_id,
		"name": display_name,
		"icon_path": str(battle_context.get("enemy_icon_path", enemy_data.icon_path if enemy_data != null else "")),
		"intent_data": intent_data,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"statuses": BATTLE_STATUS_RULES.build_empty_statuses(),
	}

static func _get_enemy_data(enemy_id: String) -> EnemyData:
	match enemy_id:
		"cinder_sprite":
			return CINDER_SPRITE_ENEMY_DATA
		"blue_wisp":
			return BLUE_WISP_ENEMY_DATA
		"hollow_bloom":
			return HOLLOW_BLOOM_ENEMY_DATA
		"slime":
			return SLIME_ENEMY_DATA
		_:
			return null

static func _build_enemy_intent_data(enemy_id: String, enemy_data: EnemyData) -> Dictionary:
	if enemy_data != null:
		for raw_intent in enemy_data.intent_cycle:
			var parsed_intent := _parse_enemy_intent(enemy_id, str(raw_intent))
			if not parsed_intent.is_empty():
				return parsed_intent
	return {
		"intent_id": "%s_attack_15" % enemy_id,
		"type": "attack",
		"display_name": "Attack 15",
		"value": 15,
	}

static func _parse_enemy_intent(enemy_id: String, raw_intent: String) -> Dictionary:
	var parts := raw_intent.split(":")
	if parts.is_empty():
		return {}
	var intent_type := str(parts[0])
	if intent_type == "attack":
		var amount := int(parts[1]) if parts.size() > 1 else 15
		return {
			"intent_id": "%s_attack_%s" % [enemy_id, amount],
			"type": "attack",
			"display_name": "Attack %s" % amount,
			"value": amount,
		}
	if intent_type == "defend":
		var block_amount := int(parts[1]) if parts.size() > 1 else 4
		return {
			"intent_id": "%s_defend_%s" % [enemy_id, block_amount],
			"type": "defend",
			"display_name": "Defend %s" % block_amount,
			"value": block_amount,
		}
	if intent_type == "charge":
		return {
			"intent_id": "%s_charge" % enemy_id,
			"type": "charge",
			"display_name": "Charge",
			"value": 0,
		}
	return {}
