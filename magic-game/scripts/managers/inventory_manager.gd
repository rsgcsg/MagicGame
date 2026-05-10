extends Node

signal materials_changed
signal material_bag_changed(change: Dictionary)

const MATERIAL_BAG_STATE := preload("res://scripts/runtime/material_bag_state.gd")
const MAGIC_MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")

const DEFAULT_MATERIAL_QUANTITIES := {
	"fire_crystal": 10,
	"water_dew": 10,
	"earth_stone": 10,
	"wind_feather": 10,
	"fire_earth_ore": 10,
	"water_wind_mist": 10,
	"unstable_mixture": 10,
	"ashvine_fiber": 10,
	"cinder_petal": 10,
	"moonwell_pearl": 10,
	"emberglass_shard": 10,
	"moss_amber": 10,
	"stormglass_prism": 10,
	"gravebloom_pollen": 10,
}

var _material_bag

func _ready() -> void:
	_material_bag = MATERIAL_BAG_STATE.new()
	_material_bag.changed.connect(_on_material_bag_changed)
	_material_bag.configure_defaults(DEFAULT_MATERIAL_QUANTITIES)
	_material_bag.reset_to_defaults()

func get_material_count(material_id: String) -> int:
	return _material_bag.get_material_count(material_id)

func get_material_quantities() -> Dictionary:
	return _material_bag.get_quantities()

func get_material_snapshot() -> Dictionary:
	return {
		"entries": list_material_entries(),
		"quantities": get_material_quantities(),
		"total_quantity": _material_bag.get_total_quantity(),
	}

func get_total_material_count() -> int:
	return _material_bag.get_total_quantity()

func list_material_entries() -> Array[Dictionary]:
	return _material_bag.list_entries(MAGIC_MATERIAL_CATALOG.get_material_ids())

func has_material(material_id: String, amount := 1) -> bool:
	return _material_bag.has_material(material_id, amount)

func can_remove_material(material_id: String, amount := 1) -> bool:
	return _material_bag.can_remove_material(material_id, amount)

func can_spend_materials(requirements: Dictionary) -> bool:
	return _material_bag.can_remove_many(requirements)

func spend_materials(requirements: Dictionary) -> bool:
	return _material_bag.remove_many(requirements)

func set_material_count(material_id: String, amount: int) -> void:
	_material_bag.set_material_count(material_id, amount)

func add_material(material_id: String, amount: int = 1) -> void:
	_material_bag.add_material(material_id, amount)

func remove_material(material_id: String, amount: int = 1) -> bool:
	return _material_bag.remove_material(material_id, amount)

func clear_materials() -> void:
	_material_bag.clear()

func reset_to_default_loadout() -> void:
	_material_bag.reset_to_defaults()

func get_last_material_change() -> Dictionary:
	return _material_bag.get_last_change()

func _on_material_bag_changed(change: Dictionary) -> void:
	materials_changed.emit()
	material_bag_changed.emit(change)
