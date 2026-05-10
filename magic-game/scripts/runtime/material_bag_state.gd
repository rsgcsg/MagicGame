class_name MaterialBagState
extends RefCounted

signal changed(change: Dictionary)

var _quantities: Dictionary = {}
var _default_quantities: Dictionary = {}
var _last_change: Dictionary = {}

func configure_defaults(default_quantities: Dictionary) -> void:
	_default_quantities = _sanitize_quantities(default_quantities)

func reset_to_defaults() -> void:
	_quantities = _default_quantities.duplicate(true)
	_emit_changed("reset_to_defaults", {"quantities": get_quantities()})

func clear() -> void:
	_quantities.clear()
	_emit_changed("clear", {"quantities": {}})

func has_material(material_id: String, amount := 1) -> bool:
	return get_material_count(material_id) >= maxi(amount, 0)

func can_remove_material(material_id: String, amount := 1) -> bool:
	return has_material(material_id, amount)

func can_remove_many(requirements: Dictionary) -> bool:
	for material_id in requirements.keys():
		if not can_remove_material(str(material_id), int(requirements[material_id])):
			return false
	return true

func get_material_count(material_id: String) -> int:
	return int(_quantities.get(material_id, 0))

func get_quantities() -> Dictionary:
	return _quantities.duplicate(true)

func get_total_quantity() -> int:
	var total := 0
	for amount in _quantities.values():
		total += int(amount)
	return total

func get_last_change() -> Dictionary:
	return _last_change.duplicate(true)

func list_entries(material_order: Array = []) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen_ids: Dictionary = {}

	for raw_material_id in material_order:
		var material_id := str(raw_material_id)
		entries.append({
			"material_id": material_id,
			"quantity": get_material_count(material_id),
		})
		seen_ids[material_id] = true

	var remaining_ids := _quantities.keys()
	remaining_ids.sort()
	for raw_material_id in remaining_ids:
		var material_id := str(raw_material_id)
		if seen_ids.has(material_id):
			continue
		entries.append({
			"material_id": material_id,
			"quantity": get_material_count(material_id),
		})

	return entries

func set_material_count(material_id: String, amount: int) -> void:
	var sanitized_amount := maxi(amount, 0)
	if sanitized_amount == 0:
		_quantities.erase(material_id)
	else:
		_quantities[material_id] = sanitized_amount
	_emit_changed("set_material_count", {
		"material_id": material_id,
		"quantity": sanitized_amount,
		"quantities": get_quantities(),
	})

func add_material(material_id: String, amount := 1) -> int:
	var sanitized_amount := maxi(amount, 0)
	if sanitized_amount == 0:
		return get_material_count(material_id)

	var next_amount := get_material_count(material_id) + sanitized_amount
	_quantities[material_id] = next_amount
	_emit_changed("add_material", {
		"material_id": material_id,
		"amount": sanitized_amount,
		"quantity": next_amount,
		"quantities": get_quantities(),
	})
	return next_amount

func remove_material(material_id: String, amount := 1) -> bool:
	var sanitized_amount := maxi(amount, 0)
	if sanitized_amount == 0:
		return true
	if not can_remove_material(material_id, sanitized_amount):
		return false

	var next_amount := get_material_count(material_id) - sanitized_amount
	if next_amount <= 0:
		_quantities.erase(material_id)
	else:
		_quantities[material_id] = next_amount
	_emit_changed("remove_material", {
		"material_id": material_id,
		"amount": sanitized_amount,
		"quantity": next_amount,
		"quantities": get_quantities(),
	})
	return true

func remove_many(requirements: Dictionary) -> bool:
	var sanitized_requirements := _sanitize_quantities(requirements)
	if not can_remove_many(sanitized_requirements):
		return false

	for material_id in sanitized_requirements.keys():
		var amount := int(sanitized_requirements[material_id])
		var next_amount := get_material_count(material_id) - amount
		if next_amount <= 0:
			_quantities.erase(material_id)
		else:
			_quantities[material_id] = next_amount

	_emit_changed("remove_many", {
		"requirements": sanitized_requirements,
		"quantities": get_quantities(),
	})
	return true

func _sanitize_quantities(raw_quantities: Dictionary) -> Dictionary:
	var sanitized: Dictionary = {}
	for raw_material_id in raw_quantities.keys():
		var amount := maxi(int(raw_quantities[raw_material_id]), 0)
		if amount <= 0:
			continue
		sanitized[str(raw_material_id)] = amount
	return sanitized

func _emit_changed(reason: String, payload: Dictionary = {}) -> void:
	_last_change = {"reason": reason}
	for payload_key in payload.keys():
		_last_change[payload_key] = payload[payload_key]
	changed.emit(get_last_change())
