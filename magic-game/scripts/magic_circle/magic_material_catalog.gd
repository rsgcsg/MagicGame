class_name MagicMaterialCatalog
extends RefCounted

const MATERIAL_RESOURCE_DIR := "res://data/materials"

static var _materials_by_id: Dictionary = {}
static var _material_order: Array[String] = []

static func get_material(material_id: String) -> Dictionary:
	_ensure_loaded()
	return _materials_by_id.get(material_id, {}).duplicate(true)

static func get_material_ids() -> Array[String]:
	_ensure_loaded()
	return _material_order.duplicate()

static func list_materials() -> Array[Dictionary]:
	_ensure_loaded()
	var output: Array[Dictionary] = []
	for material_id in _material_order:
		var material_data := get_material(material_id)
		output.append(material_data)
	return output

static func has_material(material_id: String) -> bool:
	_ensure_loaded()
	return _materials_by_id.has(material_id)

static func _ensure_loaded() -> void:
	if not _material_order.is_empty():
		return

	_materials_by_id.clear()
	_material_order.clear()
	var resource_entries: Array[Dictionary] = []
	var dir := DirAccess.open(MATERIAL_RESOURCE_DIR)
	if dir == null:
		push_warning("MagicMaterialCatalog could not open %s" % MATERIAL_RESOURCE_DIR)
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir() or not file_name.ends_with(".tres"):
			continue
		var path := "%s/%s" % [MATERIAL_RESOURCE_DIR, file_name]
		var material_resource = load(path)
		if material_resource == null or not material_resource.has_method("to_catalog_entry"):
			continue
		var entry: Dictionary = material_resource.call("to_catalog_entry")
		var material_id := str(entry.get("material_id", ""))
		if material_id.is_empty():
			continue
		resource_entries.append({
			"material_id": material_id,
			"sort_order": int(entry.get("sort_order", 9999)),
			"display_name": str(entry.get("display_name", material_id)),
			"entry": entry,
		})
	dir.list_dir_end()

	resource_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("sort_order", 9999)) == int(b.get("sort_order", 9999)):
			return str(a.get("display_name", "")) < str(b.get("display_name", ""))
		return int(a.get("sort_order", 9999)) < int(b.get("sort_order", 9999))
	)

	for resource_entry in resource_entries:
		var material_id := str(resource_entry.get("material_id", ""))
		_material_order.append(material_id)
		_materials_by_id[material_id] = (resource_entry.get("entry", {}) as Dictionary).duplicate(true)
