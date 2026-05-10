class_name BattleStatusRules
extends RefCounted

const STATUS_STRENGTH := "strength"
const STATUS_DEXTERITY := "dexterity"
const STATUS_STRONG := "strong"
const STATUS_WEAK := "weak"
const STATUS_VULNERABLE := "vulnerable"
const STATUS_FORTITUDE := "fortitude"

const STATUS_ORDER := [
	STATUS_STRENGTH,
	STATUS_DEXTERITY,
	STATUS_STRONG,
	STATUS_WEAK,
	STATUS_VULNERABLE,
	STATUS_FORTITUDE,
]

const STATUS_LABELS := {
	STATUS_STRENGTH: "Strength",
	STATUS_DEXTERITY: "Dexterity",
	STATUS_STRONG: "Strong",
	STATUS_WEAK: "Weak",
	STATUS_VULNERABLE: "Vulnerable",
	STATUS_FORTITUDE: "Fortitude",
}

const STATUS_SHORT_LABELS := {
	STATUS_STRENGTH: "STR",
	STATUS_DEXTERITY: "DEX",
	STATUS_STRONG: "STRONG",
	STATUS_WEAK: "WEAK",
	STATUS_VULNERABLE: "VULN",
	STATUS_FORTITUDE: "FORT",
}

const STATUS_BADGE_COLORS := {
	STATUS_STRENGTH: Color(1.18, 0.86, 0.68, 1.0),
	STATUS_DEXTERITY: Color(0.76, 1.06, 0.92, 1.0),
	STATUS_STRONG: Color(1.08, 0.94, 0.68, 1.0),
	STATUS_WEAK: Color(0.78, 0.82, 0.94, 1.0),
	STATUS_VULNERABLE: Color(1.12, 0.76, 0.76, 1.0),
	STATUS_FORTITUDE: Color(0.84, 0.96, 1.12, 1.0),
}

const VULNERABLE_DAMAGE_MULTIPLIER := 1.25
const WEAK_DAMAGE_REDUCTION_PER_STACK := 0.25
const STRONG_DAMAGE_BONUS_PER_STACK := 0.25
const FORTITUDE_DAMAGE_REDUCTION_PER_STACK := 0.20

static func build_empty_statuses() -> Dictionary:
	return {
		STATUS_STRENGTH: 0,
		STATUS_DEXTERITY: 0,
		STATUS_STRONG: 0,
		STATUS_WEAK: 0,
		STATUS_VULNERABLE: 0,
		STATUS_FORTITUDE: 0,
	}

static func build_status_rows(statuses: Dictionary) -> Array[String]:
	var rows: Array[String] = []
	for status_id in STATUS_ORDER:
		var amount := int(statuses.get(status_id, 0))
		if amount == 0:
			continue
		var label: String = str(STATUS_LABELS.get(status_id, status_id.capitalize()))
		rows.append("%s %s" % [label, amount if is_signed_status(status_id) else abs(amount)])
	return rows

static func build_status_entries(statuses: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for status_id in STATUS_ORDER:
		var amount := int(statuses.get(status_id, 0))
		if amount == 0:
			continue
		entries.append(_build_status_entry(status_id, amount))
	return entries

static func is_signed_status(status_id: String) -> bool:
	return status_id == STATUS_STRENGTH or status_id == STATUS_DEXTERITY

static func apply_outgoing_damage_modifiers(base_damage: int, statuses: Dictionary) -> int:
	var amount := base_damage + int(statuses.get(STATUS_STRENGTH, 0))
	amount = maxi(0, amount)
	amount = int(floor(amount * max(0.0, 1.0 - WEAK_DAMAGE_REDUCTION_PER_STACK * float(statuses.get(STATUS_WEAK, 0)))))
	amount = int(floor(amount * (1.0 + STRONG_DAMAGE_BONUS_PER_STACK * float(statuses.get(STATUS_STRONG, 0)))))
	return maxi(0, amount)

static func apply_incoming_damage_modifiers(base_damage: int, statuses: Dictionary) -> int:
	var amount := int(floor(base_damage * (1.0 + (VULNERABLE_DAMAGE_MULTIPLIER - 1.0) * float(statuses.get(STATUS_VULNERABLE, 0)))))
	amount = int(floor(amount * max(0.0, 1.0 - FORTITUDE_DAMAGE_REDUCTION_PER_STACK * float(statuses.get(STATUS_FORTITUDE, 0)))))
	return maxi(0, amount)

static func apply_block_delta(current_block: int, raw_delta: int, statuses: Dictionary) -> int:
	if raw_delta == 0:
		return current_block
	var adjusted_delta := raw_delta
	if raw_delta > 0:
		adjusted_delta += int(statuses.get(STATUS_DEXTERITY, 0))
		adjusted_delta = maxi(0, adjusted_delta)
	return maxi(0, current_block + adjusted_delta)

static func _build_status_entry(status_id: String, amount: int) -> Dictionary:
	var display_amount: int = amount if is_signed_status(status_id) else abs(amount)
	var label: String = str(STATUS_LABELS.get(status_id, status_id.capitalize()))
	return {
		"status_id": status_id,
		"label": label,
		"short_label": str(STATUS_SHORT_LABELS.get(status_id, label.substr(0, mini(label.length(), 4)).to_upper())),
		"amount": amount,
		"display_amount": display_amount,
		"badge_text": "%s %s" % [str(STATUS_SHORT_LABELS.get(status_id, label)), display_amount],
		"tooltip_text": _build_status_tooltip(status_id, label, amount, display_amount),
		"badge_modulate": STATUS_BADGE_COLORS.get(status_id, Color.WHITE),
	}

static func _build_status_tooltip(status_id: String, label: String, amount: int, display_amount: int) -> String:
	return "%s %s\n%s" % [label, display_amount, _build_status_effect_text(status_id, amount)]

static func _build_status_effect_text(status_id: String, amount: int) -> String:
	match status_id:
		STATUS_STRENGTH:
			return "Outgoing damage %+d flat." % amount
		STATUS_DEXTERITY:
			return "Positive block gain %+d." % amount
		STATUS_STRONG:
			return "Outgoing damage +%s%%." % int(round(STRONG_DAMAGE_BONUS_PER_STACK * 100.0 * float(abs(amount))))
		STATUS_WEAK:
			return "Outgoing damage -%s%%." % int(round(WEAK_DAMAGE_REDUCTION_PER_STACK * 100.0 * float(abs(amount))))
		STATUS_VULNERABLE:
			return "Takes %s%% more damage." % int(round((VULNERABLE_DAMAGE_MULTIPLIER - 1.0) * 100.0 * float(abs(amount))))
		STATUS_FORTITUDE:
			return "Takes %s%% less damage." % int(round(FORTITUDE_DAMAGE_REDUCTION_PER_STACK * 100.0 * float(abs(amount))))
	return "No combat effect description recorded."
