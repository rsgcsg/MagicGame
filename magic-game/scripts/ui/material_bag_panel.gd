extends PanelContainer

const MATERIAL_SLOT_SCENE := preload("res://scenes/ui/material_slot.tscn")
const MAGIC_MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const SCOPE_EXTERNAL := "external"
const SCOPE_EXPEDITION := "expedition"

@export var title_text := "Material Bag"
@export_enum("external", "expedition") var data_scope := SCOPE_EXTERNAL

@onready var _title_label: Label = $Margin/Layout/TitleLabel
@onready var _list_scroll: ScrollContainer = $Margin/Layout/ListScroll
@onready var _material_grid: GridContainer = $Margin/Layout/ListScroll/MaterialGrid
@onready var _empty_label: Label = $Margin/Layout/EmptyLabel
@onready var _inventory_manager = get_node_or_null("/root/InventoryManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

func _ready() -> void:
	_rebuild()
	if _inventory_manager != null and not _inventory_manager.materials_changed.is_connected(_rebuild):
		_inventory_manager.materials_changed.connect(_rebuild)
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("active_loadout_changed"):
		if not _realm_loadout_manager.active_loadout_changed.is_connected(_rebuild):
			_realm_loadout_manager.active_loadout_changed.connect(_rebuild)

func set_data_scope(scope_id: String) -> void:
	data_scope = scope_id
	if is_node_ready():
		_rebuild()

func _rebuild() -> void:
	_title_label.text = _build_title_text()
	for child in _material_grid.get_children():
		child.queue_free()

	var entries: Array = _get_entries_for_scope()
	var total_count := _get_total_count_for_scope()
	_empty_label.visible = total_count <= 0
	_list_scroll.visible = total_count > 0
	if total_count <= 0:
		return

	for entry in entries:
		var material_id := str(entry.get("material_id", ""))
		var material_data := MAGIC_MATERIAL_CATALOG.get_material(material_id)
		var slot := MATERIAL_SLOT_SCENE.instantiate()
		slot.material_id = str(material_data.get("button_label", material_data.get("display_name", material_id)))
		slot.full_material_name = str(material_data.get("display_name", material_id))
		slot.quantity = int(entry.get("quantity", 0))
		_material_grid.add_child(slot)

func _build_title_text() -> String:
	return "%s (%s)" % [title_text, _get_total_count_for_scope()]

func _get_total_count_for_scope() -> int:
	if data_scope == SCOPE_EXPEDITION:
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("get_active_material_total_count"):
			return int(_realm_loadout_manager.call("get_active_material_total_count"))
		return 0
	if _inventory_manager != null and _inventory_manager.has_method("get_total_material_count"):
		return int(_inventory_manager.call("get_total_material_count"))
	return 0

func _get_entries_for_scope() -> Array:
	if data_scope == SCOPE_EXPEDITION:
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("list_active_material_entries"):
			return _realm_loadout_manager.call("list_active_material_entries")
		return []
	return _inventory_manager.list_material_entries() if _inventory_manager != null else []
