extends Node

const MATERIAL_RESOURCE_DIR := "res://data/materials"

var materials_by_id: Dictionary = {}

func _ready() -> void:
	load_materials()

func load_materials() -> void:
	materials_by_id.clear()
	var dir := DirAccess.open(MATERIAL_RESOURCE_DIR)
	if dir == null:
		push_warning("MaterialManager could not open %s" % MATERIAL_RESOURCE_DIR)
		return
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir() or not file_name.ends_with(".tres"):
			continue
		var material = load("%s/%s" % [MATERIAL_RESOURCE_DIR, file_name])
		if material != null:
			materials_by_id[material.material_id] = material
	dir.list_dir_end()

func get_material(material_id: String) -> Resource:
	return materials_by_id.get(material_id)

func get_all_materials() -> Array:
	return materials_by_id.values()
