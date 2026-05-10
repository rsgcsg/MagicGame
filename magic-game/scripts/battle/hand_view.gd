class_name HandView
extends HBoxContainer

signal card_play_requested(instance_id: String)
signal card_discard_requested(instance_id: String)

const CARD_VIEW_SCENE := preload("res://scenes/battle/card_view.tscn")

var _card_names_by_instance_id: Dictionary = {}

func display_cards(hand_cards: Array) -> void:
	_clear_cards()
	_card_names_by_instance_id.clear()

	for card_data in hand_cards:
		if not (card_data is Dictionary):
			continue

		var instance_id := str(card_data.get("instance_id", ""))
		_card_names_by_instance_id[instance_id] = str(card_data.get("name", "Card"))
		var card_view := CARD_VIEW_SCENE.instantiate()
		card_view.set("instance_id", instance_id)
		card_view.set("card_name", str(card_data.get("name", "Card")))
		card_view.set("cost", int(card_data.get("cost", 0)))
		card_view.set("effect_text", str(card_data.get("effect_text", "")))
		card_view.set("template_id", str(card_data.get("template_id", "triangle")))
		card_view.play_requested.connect(_on_card_play_requested)
		card_view.discard_requested.connect(_on_card_discard_requested)
		add_child(card_view)

func get_card_name(instance_id: String) -> String:
	return str(_card_names_by_instance_id.get(instance_id, "Card"))

func _clear_cards() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _on_card_play_requested(instance_id: String) -> void:
	card_play_requested.emit(instance_id)

func _on_card_discard_requested(instance_id: String) -> void:
	card_discard_requested.emit(instance_id)
