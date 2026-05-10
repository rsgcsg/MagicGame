class_name GeneratedCardBagState
extends RefCounted

signal changed(change: Dictionary)

var _cards: Array[GeneratedCardData] = []
var _last_change: Dictionary = {}
var _runtime_sequence := 0

func clear() -> void:
	_cards.clear()
	_runtime_sequence = 0
	_emit_changed("clear", {"card_count": 0})

func reset_with_cards(seed_cards: Array = []) -> void:
	_cards.clear()
	_runtime_sequence = 0
	for card in seed_cards:
		if card is GeneratedCardData:
			_store_card(card)
	_emit_changed("reset_with_cards", {"card_count": _cards.size()})

func add_card(card: GeneratedCardData) -> GeneratedCardData:
	return _store_card(card)

func remove_card_by_runtime_id(runtime_instance_id: String) -> bool:
	for card_index in range(_cards.size()):
		if _cards[card_index].runtime_instance_id != runtime_instance_id:
			continue
		_cards.remove_at(card_index)
		_emit_changed("remove_card", {
			"runtime_instance_id": runtime_instance_id,
			"card_count": _cards.size(),
		})
		return true
	return false

func remove_latest_card() -> bool:
	if _cards.is_empty():
		return false
	var latest_card: GeneratedCardData = _cards.pop_back()
	_emit_changed("remove_latest_card", {
		"runtime_instance_id": latest_card.runtime_instance_id,
		"card_count": _cards.size(),
	})
	return true

func has_card(runtime_instance_id: String) -> bool:
	for card in _cards:
		if card.runtime_instance_id == runtime_instance_id:
			return true
	return false

func get_card_count() -> int:
	return _cards.size()

func get_cards() -> Array[GeneratedCardData]:
	var copies: Array[GeneratedCardData] = []
	for card in _cards:
		copies.append(_clone_card(card))
	return copies

func get_latest_card() -> GeneratedCardData:
	if _cards.is_empty():
		return null
	return _clone_card(_cards.back())

func get_card_by_runtime_id(runtime_instance_id: String) -> GeneratedCardData:
	for card in _cards:
		if card.runtime_instance_id == runtime_instance_id:
			return _clone_card(card)
	return null

func get_last_change() -> Dictionary:
	return _last_change.duplicate(true)

func list_card_entries(limit := -1) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var start_index := 0
	if limit > -1:
		start_index = maxi(_cards.size() - limit, 0)

	for card_index in range(start_index, _cards.size()):
		var card: GeneratedCardData = _cards[card_index]
		entries.append({
			"runtime_instance_id": card.runtime_instance_id,
			"card_id": card.card_id,
			"display_name": card.display_name,
			"effect_lines": card.effect_lines.duplicate(),
		})
	return entries

func _store_card(card: GeneratedCardData) -> GeneratedCardData:
	var stored_card: GeneratedCardData = _clone_card(card)
	if stored_card.runtime_instance_id.is_empty():
		_runtime_sequence += 1
		stored_card.runtime_instance_id = "generated_card_%04d" % _runtime_sequence
	_cards.append(stored_card)
	_emit_changed("add_card", {
		"runtime_instance_id": stored_card.runtime_instance_id,
		"card_count": _cards.size(),
		"display_name": stored_card.display_name,
	})
	return _clone_card(stored_card)

func _clone_card(card: GeneratedCardData) -> GeneratedCardData:
	return card.duplicate(true) as GeneratedCardData

func _emit_changed(reason: String, payload: Dictionary = {}) -> void:
	_last_change = {"reason": reason}
	for payload_key in payload.keys():
		_last_change[payload_key] = payload[payload_key]
	changed.emit(get_last_change())
