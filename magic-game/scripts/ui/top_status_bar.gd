extends HBoxContainer

const BACKPACK_POPUP_SCENE := preload("res://scenes/ui/backpack_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")
const SCOPE_EXPEDITION := "expedition"
const SCOPE_EXTERNAL := "external"
const BATTLE_SCENE_SUFFIX := "battle_scene.tscn"
const EXPEDITION_SCOPE_SCENE_SUFFIXES := [
	"realm_map_scene.tscn",
	"rest_site_scene.tscn",
]

@onready var _mana_label: Label = $ManaLabel
@onready var _materials_label: Label = $MaterialsLabel
@onready var _generated_cards_label: Label = $GeneratedCardsLabel
@onready var _gold_label: Label = $GoldLabel
@onready var _card_bag_button: Button = $CardBagButton
@onready var _game_manager: Node = get_node_or_null("/root/GameManager")
@onready var _card_manager: Node = get_node_or_null("/root/CardManager")
@onready var _inventory_manager: Node = get_node_or_null("/root/InventoryManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

var _runtime_status_override: Dictionary = {}

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_card_bag_button)
	_card_bag_button.pressed.connect(_on_card_bag_button_pressed)
	_refresh_card_bag_button_visibility()
	_refresh()
	if _game_manager != null and not _game_manager.profile_changed.is_connected(_refresh):
		_game_manager.profile_changed.connect(_refresh)
	if _card_manager != null and not _card_manager.cards_changed.is_connected(_refresh):
		_card_manager.cards_changed.connect(_refresh)
	if _inventory_manager != null and not _inventory_manager.materials_changed.is_connected(_refresh):
		_inventory_manager.materials_changed.connect(_refresh)
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("active_loadout_changed"):
		if not _realm_loadout_manager.active_loadout_changed.is_connected(_refresh):
			_realm_loadout_manager.active_loadout_changed.connect(_refresh)

func _refresh(_dummy_arg = null) -> void:
	var status := _build_status_snapshot()
	_set_status_label(
		_mana_label,
		str(status.get("mana_label", "Mana 0/0"))
	)
	_set_status_label(
		_materials_label,
		str(status.get("materials_label", "Materials 0"))
	)
	_set_status_label(
		_generated_cards_label,
		str(status.get("cards_label", "Generated Cards 0"))
	)
	_set_status_label(_gold_label, "Gold %s" % status.get("gold", 0))
	_refresh_card_bag_button_visibility()

func _build_status_snapshot() -> Dictionary:
	var base_status: Dictionary = _game_manager.call("get_status_snapshot") if _game_manager != null else {}
	var status_snapshot := {}
	if _is_battle_scene():
		status_snapshot = {
			"mana_label": "Battle Mana",
			"materials_label": "Realm Materials",
			"cards_label": "Realm Cards",
			"gold": base_status.get("gold", 0),
		}
	elif _should_use_expedition_scope():
		var expedition_summary: Dictionary = _realm_loadout_manager.call("get_active_loadout_summary") if _realm_loadout_manager != null and _realm_loadout_manager.has_method("get_active_loadout_summary") else {}
		status_snapshot = {
			"mana_label": "Mana %s/%s" % [base_status.get("current_mana", 0), base_status.get("max_mana", 0)],
			"materials_label": "Realm Materials %s" % int(expedition_summary.get("material_total_count", 0)),
			"cards_label": "Realm Cards %s" % int(expedition_summary.get("selected_card_count", 0)),
			"gold": base_status.get("gold", 0),
		}
	else:
		status_snapshot = {
			"mana_label": "Mana %s/%s" % [base_status.get("current_mana", 0), base_status.get("max_mana", 0)],
			"materials_label": "Materials %s" % base_status.get("material_total_count", 0),
			"cards_label": "Generated Cards %s" % base_status.get("generated_card_count", base_status.get("card_count", 0)),
			"gold": base_status.get("gold", 0),
		}
	for key in _runtime_status_override.keys():
		status_snapshot[key] = _runtime_status_override[key]
	return status_snapshot

func set_runtime_status_override(status_override: Dictionary) -> void:
	_runtime_status_override = status_override.duplicate(true)
	if is_node_ready():
		_refresh()

func clear_runtime_status_override() -> void:
	if _runtime_status_override.is_empty():
		return
	_runtime_status_override = {}
	if is_node_ready():
		_refresh()

func _set_status_label(label: Label, text_value: String) -> void:
	label.text = text_value
	label.tooltip_text = text_value

func _on_card_bag_button_pressed() -> void:
	SceneManager.play_ui_button_click()
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	for child in current_scene.get_children():
		if child.scene_file_path == BACKPACK_POPUP_SCENE.resource_path:
			return
	var popup = BACKPACK_POPUP_SCENE.instantiate()
	var default_scope := SCOPE_EXTERNAL
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("has_active_expedition"):
		if bool(_realm_loadout_manager.call("has_active_expedition")):
			default_scope = SCOPE_EXPEDITION
	popup.configure_default_scope(default_scope)
	current_scene.add_child(popup)

func _refresh_card_bag_button_visibility() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		_card_bag_button.visible = true
		return
	var scene_path := str(current_scene.scene_file_path)
	_card_bag_button.visible = not scene_path.ends_with(BATTLE_SCENE_SUFFIX)

func _should_use_expedition_scope() -> bool:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("has_active_expedition"):
		return false
	if not bool(_realm_loadout_manager.call("has_active_expedition")):
		return false
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	var scene_path := str(current_scene.scene_file_path)
	for suffix in EXPEDITION_SCOPE_SCENE_SUFFIXES:
		if scene_path.ends_with(suffix):
			return true
	return false

func _is_battle_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return str(current_scene.scene_file_path).ends_with(BATTLE_SCENE_SUFFIX)
