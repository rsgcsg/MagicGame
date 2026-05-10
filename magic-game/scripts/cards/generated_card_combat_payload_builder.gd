class_name GeneratedCardCombatPayloadBuilder
extends RefCounted

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

const STATUS_STRENGTH := "strength"
const STATUS_DEXTERITY := "dexterity"
const STATUS_STRONG := "strong"
const STATUS_WEAK := "weak"
const STATUS_VULNERABLE := "vulnerable"
const STATUS_FORTITUDE := "fortitude"

static func build_from_visible_effects(visible_effects: Array) -> Dictionary:
	var effects: Array[Dictionary] = []
	for visible_effect_variant in visible_effects:
		if not (visible_effect_variant is Dictionary):
			continue
		var effect_entry := _map_visible_effect(visible_effect_variant)
		if effect_entry.is_empty():
			continue
		effects.append(effect_entry)
	return {
		"target": _derive_primary_target(effects),
		"effects": effects,
	}

static func build_from_effect_lines_legacy(effect_lines: Array[String], fallback_damage: int = 4) -> Dictionary:
	var effect_entries: Array[Dictionary] = []
	for effect_line in effect_lines:
		var parsed_entry := _parse_effect_line(str(effect_line))
		if not parsed_entry.is_empty():
			effect_entries.append(parsed_entry)

	if effect_entries.is_empty():
		return {
			"target": TARGET_ENEMY,
			"effects": [
				{"type": EFFECT_DAMAGE, "target": TARGET_ENEMY, "value": maxi(1, fallback_damage)},
			],
		}

	return {
		"target": _derive_primary_target(effect_entries),
		"effects": effect_entries,
	}

static func _map_visible_effect(visible_effect: Dictionary) -> Dictionary:
	var dimension := str(visible_effect.get("dimension", ""))
	var sign := str(visible_effect.get("sign", "positive"))
	var value := maxi(1, int(visible_effect.get("final_value", 0)))

	match dimension:
		"Q01":
			return {"type": EFFECT_DAMAGE if sign == "positive" else EFFECT_ENEMY_HEAL, "target": TARGET_ENEMY, "value": value}
		"Q02":
			return {"type": EFFECT_ACTION_POINTS, "target": TARGET_SELF, "value": value if sign == "positive" else -value}
		"Q03":
			return {"type": EFFECT_BLOCK, "target": TARGET_SELF, "value": value if sign == "positive" else -value}
		"Q04":
			return {"type": EFFECT_DRAW if sign == "positive" else EFFECT_DISCARD, "target": TARGET_SELF, "value": value}
		"Q05":
			return {"type": EFFECT_STATUS, "target": TARGET_SELF, "status_id": STATUS_STRENGTH, "value": value if sign == "positive" else -value}
		"Q06":
			return {"type": EFFECT_STATUS, "target": TARGET_ENEMY, "status_id": STATUS_VULNERABLE if sign == "positive" else STATUS_FORTITUDE, "value": value}
		"Q07":
			return {"type": EFFECT_MANA, "target": TARGET_SELF, "value": value if sign == "positive" else -value}
		"Q11":
			return {"type": EFFECT_STATUS, "target": TARGET_SELF, "status_id": STATUS_DEXTERITY, "value": value if sign == "positive" else -value}
		"Q12":
			return {"type": EFFECT_STATUS, "target": TARGET_ENEMY, "status_id": STATUS_WEAK if sign == "positive" else STATUS_STRONG, "value": value}
		"Q25":
			return {"type": EFFECT_STATUS, "target": TARGET_ENEMY, "status_id": STATUS_STRENGTH, "value": -value if sign == "positive" else value}
		"Q26":
			return {"type": EFFECT_STATUS, "target": TARGET_SELF, "status_id": STATUS_FORTITUDE if sign == "positive" else STATUS_VULNERABLE, "value": value}
		"Q31":
			return {"type": EFFECT_STATUS, "target": TARGET_ENEMY, "status_id": STATUS_DEXTERITY, "value": -value if sign == "positive" else value}
		"Q32":
			return {"type": EFFECT_STATUS, "target": TARGET_SELF, "status_id": STATUS_STRONG if sign == "positive" else STATUS_WEAK, "value": value}
		_:
			return {}

static func _derive_primary_target(effect_entries: Array[Dictionary]) -> String:
	for effect_entry in effect_entries:
		var target := str(effect_entry.get("target", TARGET_NONE))
		if target == TARGET_ENEMY:
			return TARGET_ENEMY
	for effect_entry in effect_entries:
		var target := str(effect_entry.get("target", TARGET_NONE))
		if target == TARGET_SELF:
			return TARGET_SELF
	return TARGET_NONE

static func _parse_effect_line(effect_line: String) -> Dictionary:
	var normalized := effect_line.strip_edges()
	if normalized.is_empty():
		return {}

	var lower_line := normalized.to_lower()
	var value := _extract_first_number(normalized, 0)
	if lower_line.begins_with("deal ") and lower_line.contains(" damage"):
		return {"type": EFFECT_DAMAGE, "target": TARGET_ENEMY, "value": maxi(1, value)}
	if lower_line.begins_with("heal enemy for ") and lower_line.contains(" hp"):
		return {"type": EFFECT_ENEMY_HEAL, "target": TARGET_ENEMY, "value": maxi(1, value)}
	if lower_line.begins_with("gain ") and lower_line.contains(" block"):
		return {"type": EFFECT_BLOCK, "target": TARGET_SELF, "value": maxi(1, value)}
	if lower_line.begins_with("lose ") and lower_line.contains(" block"):
		return {"type": EFFECT_BLOCK, "target": TARGET_SELF, "value": -maxi(1, value)}
	if lower_line.begins_with("draw ") and lower_line.contains(" card"):
		return {"type": EFFECT_DRAW, "target": TARGET_SELF, "value": maxi(1, value)}
	if lower_line.begins_with("discard ") and lower_line.contains(" card"):
		return {"type": EFFECT_DISCARD, "target": TARGET_SELF, "value": maxi(1, value)}
	if lower_line.begins_with("gain ") and lower_line.contains(" action point"):
		return {"type": EFFECT_ACTION_POINTS, "target": TARGET_SELF, "value": maxi(1, value)}
	if lower_line.begins_with("lose ") and lower_line.contains(" action point"):
		return {"type": EFFECT_ACTION_POINTS, "target": TARGET_SELF, "value": -maxi(1, value)}
	if lower_line.begins_with("gain ") and lower_line.contains(" mana"):
		return {"type": EFFECT_MANA, "target": TARGET_SELF, "value": maxi(1, value)}
	if lower_line.begins_with("lose ") and lower_line.contains(" mana"):
		return {"type": EFFECT_MANA, "target": TARGET_SELF, "value": -maxi(1, value)}
	if lower_line.begins_with("apply "):
		return _parse_status_line(lower_line, value)
	return {}

static func _parse_status_line(lower_line: String, value: int) -> Dictionary:
	var target := TARGET_SELF if lower_line.contains(" to self") else TARGET_ENEMY
	if lower_line.contains("strength down"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_STRENGTH, "value": -maxi(1, value)}
	if lower_line.contains("dexterity down"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_DEXTERITY, "value": -maxi(1, value)}
	if lower_line.contains("strength"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_STRENGTH, "value": maxi(1, value)}
	if lower_line.contains("dexterity"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_DEXTERITY, "value": maxi(1, value)}
	if lower_line.contains("strong"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_STRONG, "value": maxi(1, value)}
	if lower_line.contains("weak"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_WEAK, "value": maxi(1, value)}
	if lower_line.contains("vulnerable"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_VULNERABLE, "value": maxi(1, value)}
	if lower_line.contains("fortitude"):
		return {"type": EFFECT_STATUS, "target": target, "status_id": STATUS_FORTITUDE, "value": maxi(1, value)}
	return {}

static func _extract_first_number(text_value: String, fallback: int) -> int:
	var digits := ""
	for character in text_value:
		if character >= "0" and character <= "9":
			digits += character
		elif not digits.is_empty():
			return int(digits)
	if digits.is_empty():
		return fallback
	return int(digits)
