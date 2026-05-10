extends Node

const TEMPLATE_RESOURCE_DIR := "res://data/circles"

var templates_by_id: Dictionary = {}

func _ready() -> void:
	load_templates()

func load_templates() -> void:
	templates_by_id.clear()
	var dir := DirAccess.open(TEMPLATE_RESOURCE_DIR)
	if dir == null:
		push_warning("MagicCircleManager could not open %s" % TEMPLATE_RESOURCE_DIR)
		return
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir() or not file_name.ends_with(".tres"):
			continue
		var template = load("%s/%s" % [TEMPLATE_RESOURCE_DIR, file_name])
		if template != null and template.has_method("to_catalog_entry"):
			var entry: Dictionary = template.call("to_catalog_entry")
			var template_id := str(entry.get("template_id", ""))
			if not template_id.is_empty():
				templates_by_id[template_id] = template
	dir.list_dir_end()

func get_template(template_id: String) -> Resource:
	return templates_by_id.get(template_id)

func get_all_templates() -> Array:
	return templates_by_id.values()
