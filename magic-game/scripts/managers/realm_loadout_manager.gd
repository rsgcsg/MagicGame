extends Node

signal draft_selection_changed(summary: Dictionary)
signal active_loadout_changed(summary: Dictionary)

const TARGET_NONE := "none"
const TARGET_SELF := "self"
const TARGET_ENEMY := "enemy"
const MATERIAL_BAG_STATE := preload("res://scripts/runtime/material_bag_state.gd")
const MAGIC_MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const GENERATED_CARD_EFFECT_ADAPTER := preload("res://scripts/battle/generated_card_effect_adapter.gd")

@export_range(1, 20) var selection_limit := 15

@onready var _card_manager = get_node_or_null("/root/CardManager")
@onready var _inventory_manager = get_node_or_null("/root/InventoryManager")

var _draft_selected_runtime_ids: Array[String] = []
var _active_run_cards: Array[GeneratedCardData] = []
var _active_realm_context: Dictionary = {}
var _active_material_bag: MaterialBagState
var _internal_runtime_sequence := 0
var _cumulative_lost_card_count := 0
var _expedition_reward_materials: Dictionary = {}
var _expedition_spent_materials: Dictionary = {}
var _expedition_reward_card_count := 0
var _expedition_crafted_card_count := 0

func _ready() -> void:
	_active_material_bag = MATERIAL_BAG_STATE.new()
	_active_material_bag.changed.connect(_on_active_material_bag_changed)
	if _card_manager != null and _card_manager.has_signal("cards_changed"):
		if not _card_manager.cards_changed.is_connected(_on_external_card_bag_changed):
			_card_manager.cards_changed.connect(_on_external_card_bag_changed)
	_emit_draft_selection_changed()
	_emit_active_loadout_changed()

func get_selection_limit() -> int:
	return selection_limit

func get_draft_selected_runtime_ids() -> Array[String]:
	return _draft_selected_runtime_ids.duplicate()

func get_draft_selected_count() -> int:
	return _draft_selected_runtime_ids.size()

func is_draft_selected(runtime_instance_id: String) -> bool:
	return _draft_selected_runtime_ids.has(runtime_instance_id)

func select_draft_card(runtime_instance_id: String) -> bool:
	if runtime_instance_id.is_empty() or is_draft_selected(runtime_instance_id):
		return false
	if _draft_selected_runtime_ids.size() >= selection_limit:
		return false
	if _get_card_from_external_bag(runtime_instance_id) == null:
		return false
	_draft_selected_runtime_ids.append(runtime_instance_id)
	_emit_draft_selection_changed()
	return true

func deselect_draft_card(runtime_instance_id: String) -> bool:
	if not _draft_selected_runtime_ids.has(runtime_instance_id):
		return false
	_draft_selected_runtime_ids.erase(runtime_instance_id)
	_emit_draft_selection_changed()
	return true

func toggle_draft_card(runtime_instance_id: String) -> bool:
	if is_draft_selected(runtime_instance_id):
		deselect_draft_card(runtime_instance_id)
		return false
	select_draft_card(runtime_instance_id)
	return is_draft_selected(runtime_instance_id)

func clear_draft_selection() -> void:
	if _draft_selected_runtime_ids.is_empty():
		return
	_draft_selected_runtime_ids.clear()
	_emit_draft_selection_changed()

func get_draft_selected_cards() -> Array[GeneratedCardData]:
	var selected_cards: Array[GeneratedCardData] = []
	for runtime_instance_id in _draft_selected_runtime_ids:
		var card := _get_card_from_external_bag(runtime_instance_id)
		if card != null:
			selected_cards.append(card)
	return selected_cards

func get_draft_selection_summary() -> Dictionary:
	return {
		"selected_count": get_draft_selected_count(),
		"selection_limit": selection_limit,
		"selected_runtime_ids": get_draft_selected_runtime_ids(),
	}

func commit_draft_selection_to_active_run(realm_context: Dictionary = {}) -> Dictionary:
	var selected_runtime_ids := get_draft_selected_runtime_ids()
	var selected_cards := get_draft_selected_cards()
	if selected_runtime_ids.size() != selected_cards.size():
		return {}

	var active_run_copies: Array[GeneratedCardData] = []
	for card in selected_cards:
		active_run_copies.append(card.duplicate(true) as GeneratedCardData)

	if not selected_runtime_ids.is_empty():
		if _card_manager == null or not _card_manager.has_method("remove_cards_by_instance_ids"):
			return {}
		if not bool(_card_manager.call("remove_cards_by_instance_ids", selected_runtime_ids)):
			return {}

	_active_run_cards.clear()
	for card_copy in active_run_copies:
		_active_run_cards.append(card_copy)
	_active_realm_context = realm_context.duplicate(true)
	_active_realm_context["selected_card_count"] = _active_run_cards.size()
	_active_realm_context["transferred_runtime_ids"] = selected_runtime_ids.duplicate()
	_internal_runtime_sequence = _active_run_cards.size()
	_cumulative_lost_card_count = 0
	_expedition_reward_materials = {}
	_expedition_spent_materials = {}
	_expedition_reward_card_count = 0
	_expedition_crafted_card_count = 0
	_active_material_bag.clear()
	_draft_selected_runtime_ids.clear()
	_emit_draft_selection_changed()
	_emit_active_loadout_changed()
	return get_active_loadout_summary()

func clear_active_run() -> void:
	_active_run_cards.clear()
	_active_realm_context = {}
	if _active_material_bag != null:
		_active_material_bag.clear()
	_internal_runtime_sequence = 0
	_cumulative_lost_card_count = 0
	_expedition_reward_materials = {}
	_expedition_spent_materials = {}
	_expedition_reward_card_count = 0
	_expedition_crafted_card_count = 0
	_emit_active_loadout_changed()

func has_active_expedition() -> bool:
	return not _active_realm_context.is_empty()

func has_active_run_loadout() -> bool:
	return not _active_run_cards.is_empty()

func get_active_run_card_count() -> int:
	return _active_run_cards.size()

func get_active_run_cards() -> Array[GeneratedCardData]:
	var copies: Array[GeneratedCardData] = []
	for card in _active_run_cards:
		copies.append(card.duplicate(true) as GeneratedCardData)
	return copies

func get_active_realm_context() -> Dictionary:
	return _active_realm_context.duplicate(true)

func get_active_loadout_summary() -> Dictionary:
	var summary := _active_realm_context.duplicate(true)
	summary["selected_card_count"] = _active_run_cards.size()
	summary["material_total_count"] = get_active_material_total_count()
	summary["has_active_expedition"] = has_active_expedition()
	summary["using_debug_fallback"] = _active_run_cards.is_empty()
	summary["scope"] = "internal_realm_run_snapshot"
	return summary

func get_active_material_count(material_id: String) -> int:
	if _active_material_bag == null:
		return 0
	return _active_material_bag.get_material_count(material_id)

func get_active_material_total_count() -> int:
	if _active_material_bag == null:
		return 0
	return _active_material_bag.get_total_quantity()

func get_active_material_snapshot() -> Dictionary:
	return {
		"entries": list_active_material_entries(),
		"quantities": _active_material_bag.get_quantities() if _active_material_bag != null else {},
		"total_quantity": get_active_material_total_count(),
	}

func list_active_material_entries() -> Array[Dictionary]:
	if _active_material_bag == null:
		return []
	return _active_material_bag.list_entries(MAGIC_MATERIAL_CATALOG.get_material_ids())

func can_spend_active_materials(requirements: Dictionary) -> bool:
	if _active_material_bag == null:
		return false
	return _active_material_bag.can_remove_many(requirements)

func spend_active_materials(requirements: Dictionary) -> bool:
	if _active_material_bag == null:
		return false
	if not _active_material_bag.remove_many(requirements):
		return false
	_merge_quantity_dictionary(_expedition_spent_materials, requirements)
	return true

func add_active_material(material_id: String, amount: int = 1, source: String = "reward") -> void:
	if _active_material_bag == null:
		return
	_active_material_bag.add_material(material_id, amount)
	if source == "reward":
		_merge_quantity_dictionary(_expedition_reward_materials, {material_id: amount})

func add_active_materials(materials: Dictionary, source: String = "reward") -> void:
	for material_id in materials.keys():
		add_active_material(str(material_id), int(materials[material_id]), source)

func add_generated_card_to_active_run(card: GeneratedCardData, source: String = "reward") -> GeneratedCardData:
	if card == null:
		return null
	var internal_card := card.duplicate(true) as GeneratedCardData
	_assign_internal_runtime_id_if_needed(internal_card)
	_active_run_cards.append(internal_card)
	match source:
		"reward":
			_expedition_reward_card_count += 1
		"craft":
			_expedition_crafted_card_count += 1
	_emit_active_loadout_changed()
	return internal_card.duplicate(true) as GeneratedCardData

func apply_selected_reward(selected_reward: Dictionary, battle_result: Dictionary = {}) -> Dictionary:
	if not has_active_expedition():
		return {"reward_type": "skip", "applied": false}
	if selected_reward.is_empty():
		return {"reward_type": "skip", "applied": false}

	var reward_type := str(selected_reward.get("reward_type", "skip"))
	match reward_type:
		"material":
			var bundle: Dictionary = selected_reward.get("material_bundle", {}) if selected_reward.get("material_bundle", {}) is Dictionary else {}
			if bundle is Dictionary:
				add_active_materials(bundle, "reward")
			return {
				"reward_type": reward_type,
				"applied": true,
				"materials_added": bundle,
			}
		"card":
			var reward_card_variant = selected_reward.get("generated_card")
			var reward_card: GeneratedCardData = reward_card_variant if reward_card_variant is GeneratedCardData else null
			if reward_card == null:
				return {"reward_type": reward_type, "applied": false}
			var stored_card: GeneratedCardData = add_generated_card_to_active_run(reward_card, "reward")
			return {
				"reward_type": reward_type,
				"applied": stored_card != null,
				"card_name": stored_card.display_name if stored_card != null else "",
				"source_node_id": str(battle_result.get("source_node_id", "")),
			}
	return {"reward_type": reward_type, "applied": false}

func apply_battle_result_card_lifecycle(result_payload: Dictionary) -> Dictionary:
	var consumed_runtime_ids_variant = result_payload.get("consumed_source_runtime_ids", [])
	var consumed_runtime_ids: Array[String] = []
	if consumed_runtime_ids_variant is Array:
		for runtime_id in consumed_runtime_ids_variant:
			var runtime_id_text := str(runtime_id)
			if runtime_id_text.is_empty():
				continue
			consumed_runtime_ids.append(runtime_id_text)

	if consumed_runtime_ids.is_empty():
		return {
			"consumed_count": 0,
			"remaining_count": _active_run_cards.size(),
		}

	var remaining_cards: Array[GeneratedCardData] = []
	var consumed_count := 0
	for card in _active_run_cards:
		if consumed_runtime_ids.has(card.runtime_instance_id):
			consumed_count += 1
			continue
		remaining_cards.append(card)
	_active_run_cards = remaining_cards
	_cumulative_lost_card_count += consumed_count
	_emit_active_loadout_changed()
	return {
		"consumed_count": consumed_count,
		"remaining_count": _active_run_cards.size(),
		"consumed_runtime_ids": consumed_runtime_ids.duplicate(),
	}

func finalize_active_expedition(return_survivors := true) -> Dictionary:
	var returning_cards: Array[GeneratedCardData] = []
	if return_survivors:
		for card in _active_run_cards:
			returning_cards.append(card.duplicate(true) as GeneratedCardData)

	var recovered_count := 0
	if return_survivors and _card_manager != null:
		for card in returning_cards:
			if _card_manager.has_method("add_generated_card"):
				_card_manager.call("add_generated_card", card)
				recovered_count += 1

	var recovered_materials := _active_material_bag.get_quantities().duplicate(true) if _active_material_bag != null else {}
	var recovered_material_total := 0
	if return_survivors and _inventory_manager != null and _inventory_manager.has_method("add_material"):
		for material_id in recovered_materials.keys():
			var amount := int(recovered_materials[material_id])
			recovered_material_total += amount
			_inventory_manager.call("add_material", str(material_id), amount)

	var final_context := _active_realm_context.duplicate(true)
	var summary := {
		"recovered_card_count": recovered_count,
		"lost_card_count": _cumulative_lost_card_count,
		"recovered_material_total": recovered_material_total,
		"recovered_materials": recovered_materials,
		"reward_materials": _expedition_reward_materials.duplicate(true),
		"spent_materials": _expedition_spent_materials.duplicate(true),
		"reward_card_count": _expedition_reward_card_count,
		"crafted_card_count": _expedition_crafted_card_count,
		"returned_survivors": return_survivors,
		"final_context": final_context,
	}
	clear_active_run()
	return summary

func build_active_battle_cards() -> Array[Dictionary]:
	var battle_cards: Array[Dictionary] = []
	for card_index in range(_active_run_cards.size()):
		var generated_card := _active_run_cards[card_index]
		battle_cards.append(_build_battle_card(generated_card, card_index))
	return battle_cards

func _on_external_card_bag_changed() -> void:
	var new_ids: Array[String] = []
	var changed := false
	for runtime_instance_id in _draft_selected_runtime_ids:
		if _get_card_from_external_bag(runtime_instance_id) == null:
			changed = true
			continue
		new_ids.append(runtime_instance_id)
	_draft_selected_runtime_ids = new_ids
	if changed:
		_emit_draft_selection_changed()

func _get_card_from_external_bag(runtime_instance_id: String) -> GeneratedCardData:
	if _card_manager == null or not _card_manager.has_method("get_card_by_instance_id"):
		return null
	return _card_manager.call("get_card_by_instance_id", runtime_instance_id)

func _assign_internal_runtime_id_if_needed(card: GeneratedCardData) -> void:
	if card == null:
		return
	if card.runtime_instance_id.is_empty() or _has_internal_runtime_id(card.runtime_instance_id):
		_internal_runtime_sequence += 1
		card.runtime_instance_id = "expedition_card_%04d" % _internal_runtime_sequence

func _has_internal_runtime_id(runtime_instance_id: String) -> bool:
	for card in _active_run_cards:
		if card.runtime_instance_id == runtime_instance_id:
			return true
	return false

func _build_battle_card(card: GeneratedCardData, card_index: int) -> Dictionary:
	var instance_id := "realm_%s_%03d" % [_sanitize_runtime_id(card.runtime_instance_id), card_index + 1]
	var effect_lines: Array[String] = card.effect_lines.duplicate()
	return {
		"instance_id": instance_id,
		"card_id": card.card_id,
		"name": card.display_name,
		"cost": card.action_point_cost,
		"template_id": card.source_template_id if not card.source_template_id.is_empty() else "triangle",
		"consumable": card.single_use,
		"effect_text": _build_effect_text(card),
		"art_label": _build_art_label(card.display_name),
		"effect_data": _derive_effect_data(card),
		"source_runtime_id": card.runtime_instance_id,
		"source_scope": "internal_realm_run_snapshot",
		"source_effect_lines": effect_lines,
	}

func _build_effect_text(card: GeneratedCardData) -> String:
	if not card.effect_lines.is_empty():
		return "\n".join(card.effect_lines)
	if not card.description.is_empty():
		return card.description
	return "Generated card placeholder effect."

func _build_art_label(display_name: String) -> String:
	if display_name.length() <= 10:
		return display_name
	return "%s..." % display_name.substr(0, 7)

func _derive_effect_data(card: GeneratedCardData) -> Dictionary:
	if not card.combat_payload.is_empty():
		return card.combat_payload.duplicate(true)
	return GENERATED_CARD_EFFECT_ADAPTER.build_effect_data(card)

func _sanitize_runtime_id(runtime_instance_id: String) -> String:
	if runtime_instance_id.is_empty():
		return "generated_card"
	return runtime_instance_id.replace(":", "_").replace("/", "_")

func _merge_quantity_dictionary(target: Dictionary, source: Dictionary) -> void:
	for material_id in source.keys():
		var amount := int(source[material_id])
		if amount <= 0:
			continue
		target[str(material_id)] = int(target.get(material_id, 0)) + amount

func _on_active_material_bag_changed(_change: Dictionary) -> void:
	_emit_active_loadout_changed()

func _emit_draft_selection_changed() -> void:
	draft_selection_changed.emit(get_draft_selection_summary())

func _emit_active_loadout_changed() -> void:
	active_loadout_changed.emit(get_active_loadout_summary())
