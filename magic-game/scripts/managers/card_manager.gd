extends Node

signal cards_changed
signal generated_card_bag_changed(change: Dictionary)

const GENERATED_CARD_BAG_STATE := preload("res://scripts/runtime/generated_card_bag_state.gd")
const STARTER_STRIKE_CARD := preload("res://data/cards/starter_strike.tres")

var _generated_card_bag

func _ready() -> void:
	_generated_card_bag = GENERATED_CARD_BAG_STATE.new()
	_generated_card_bag.changed.connect(_on_generated_card_bag_changed)
	_generated_card_bag.reset_with_cards([STARTER_STRIKE_CARD])

func add_generated_card(card: GeneratedCardData) -> GeneratedCardData:
	return _generated_card_bag.add_card(card)

func add_card(card: Resource) -> void:
	if card is GeneratedCardData:
		_generated_card_bag.add_card(card)

func get_card_count() -> int:
	return _generated_card_bag.get_card_count()

func get_cards() -> Array[GeneratedCardData]:
	return _generated_card_bag.get_cards()

func get_latest_card() -> GeneratedCardData:
	return _generated_card_bag.get_latest_card()

func get_card_by_instance_id(runtime_instance_id: String) -> GeneratedCardData:
	return _generated_card_bag.get_card_by_runtime_id(runtime_instance_id)

func has_card_instance_id(runtime_instance_id: String) -> bool:
	return _generated_card_bag.has_card(runtime_instance_id)

func remove_card_by_instance_id(runtime_instance_id: String) -> bool:
	return _generated_card_bag.remove_card_by_runtime_id(runtime_instance_id)

func remove_cards_by_instance_ids(runtime_instance_ids: Array[String]) -> bool:
	for runtime_instance_id in runtime_instance_ids:
		if not has_card_instance_id(runtime_instance_id):
			return false
	for runtime_instance_id in runtime_instance_ids:
		if not remove_card_by_instance_id(runtime_instance_id):
			return false
	return true

func remove_latest_card() -> bool:
	return _generated_card_bag.remove_latest_card()

func clear_cards() -> void:
	_generated_card_bag.clear()

func reset_generated_cards() -> void:
	_generated_card_bag.reset_with_cards([STARTER_STRIKE_CARD])

func list_card_entries(limit := -1) -> Array[Dictionary]:
	return _generated_card_bag.list_card_entries(limit)

func get_last_card_change() -> Dictionary:
	return _generated_card_bag.get_last_change()

func _on_generated_card_bag_changed(change: Dictionary) -> void:
	cards_changed.emit()
	generated_card_bag_changed.emit(change)
