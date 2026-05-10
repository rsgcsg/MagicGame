class_name GeneratedCardEffectAdapter
extends RefCounted

const COMBAT_PAYLOAD_BUILDER := preload("res://scripts/cards/generated_card_combat_payload_builder.gd")

static func build_effect_data(card: GeneratedCardData) -> Dictionary:
	return COMBAT_PAYLOAD_BUILDER.build_from_effect_lines_legacy(card.effect_lines, _build_fallback_damage(card))

static func _build_fallback_damage(card: GeneratedCardData) -> int:
	return maxi(4 + card.action_point_cost * 2, 4)
