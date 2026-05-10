class_name MagicCircleTemplateCatalog
extends RefCounted

const TEMPLATE_RESOURCE_DIR := "res://data/circles"

static var _templates_by_id: Dictionary = {}
static var _template_order: Array[String] = []

static func get_template(template_id: String) -> Dictionary:
	_ensure_loaded()
	return _templates_by_id.get(template_id, {}).duplicate(true)

static func get_template_ids() -> Array[String]:
	_ensure_loaded()
	return _template_order.duplicate()

static func get_lab_template_ids() -> Array[String]:
	_ensure_loaded()
	var output: Array[String] = []
	for template_id in _template_order:
		var template_data: Dictionary = _templates_by_id.get(template_id, {})
		if bool(template_data.get("available_in_lab", true)):
			output.append(template_id)
	return output

static func has_template(template_id: String) -> bool:
	_ensure_loaded()
	return _templates_by_id.has(template_id)

static func _ensure_loaded() -> void:
	if not _template_order.is_empty():
		return

	_templates_by_id.clear()
	_template_order.clear()
	var resource_entries: Array[Dictionary] = []
	var dir := DirAccess.open(TEMPLATE_RESOURCE_DIR)
	if dir == null:
		push_warning("MagicCircleTemplateCatalog could not open %s" % TEMPLATE_RESOURCE_DIR)
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir() or not file_name.ends_with(".tres"):
			continue
		var template_resource = load("%s/%s" % [TEMPLATE_RESOURCE_DIR, file_name])
		if template_resource == null or not template_resource.has_method("to_catalog_entry"):
			continue
		var entry: Dictionary = template_resource.call("to_catalog_entry")
		var template_id := str(entry.get("template_id", ""))
		if template_id.is_empty():
			continue
		resource_entries.append({
			"template_id": template_id,
			"sort_order": int(entry.get("sort_order", 9999)),
			"display_name": str(entry.get("display_name", template_id)),
			"entry": entry,
		})
	dir.list_dir_end()

	resource_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("sort_order", 9999)) == int(b.get("sort_order", 9999)):
			return str(a.get("display_name", "")) < str(b.get("display_name", ""))
		return int(a.get("sort_order", 9999)) < int(b.get("sort_order", 9999))
	)

	for resource_entry in resource_entries:
		var template_id := str(resource_entry.get("template_id", ""))
		_template_order.append(template_id)
		_templates_by_id[template_id] = (resource_entry.get("entry", {}) as Dictionary).duplicate(true)
