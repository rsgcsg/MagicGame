extends PanelContainer

const TEMPLATE_CATALOG := preload("res://scripts/magic_circle/magic_circle_template_catalog.gd")
const MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")
const PLACEHOLDER_EVALUATOR := preload("res://scripts/magic_circle/placeholder_card_evaluator.gd")
const GENERATED_CARD_BUILDER := preload("res://scripts/cards/generated_card_builder.gd")
const TEMPLATE_BUTTON_SCENE := preload("res://scenes/lab/alchemy_template_button.tscn")
const MATERIAL_BUTTON_SCENE := preload("res://scenes/lab/alchemy_material_button.tscn")
const GENERATED_CARD_RESULT_POPUP_SCENE := preload("res://scenes/lab/generated_card_result_popup.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")
const STORAGE_SCOPE_EXTERNAL := "external_workshop"
const STORAGE_SCOPE_EXPEDITION := "expedition_internal"

@export_range(1, 6) var recipe_summary_entry_limit := 3
@export_range(24, 120) var status_message_character_limit := 56

@onready var _close_button: Button = $Margin/PopupPanel/InnerMargin/Layout/Header/CloseButton
@onready var _magic_circle_editor = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/MagicCircleEditor
@onready var _selected_template_label: Label = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/RightRail/PreviewPanel/PreviewMargin/PreviewScroll/PreviewLayout/SelectedTemplateLabel
@onready var _selected_materials_label: Label = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/RightRail/PreviewPanel/PreviewMargin/PreviewScroll/PreviewLayout/SelectedMaterialsLabel
@onready var _circle_status_label: Label = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/RightRail/PreviewPanel/PreviewMargin/PreviewScroll/PreviewLayout/CircleStatusLabel
@onready var _generated_result_label: Label = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/RightRail/PreviewPanel/PreviewMargin/PreviewScroll/PreviewLayout/GeneratedResultLabel
@onready var _status_label: Label = $Margin/PopupPanel/InnerMargin/Layout/ButtonRow/StatusLabel
@onready var _generate_card_button: Button = $Margin/PopupPanel/InnerMargin/Layout/ButtonRow/GenerateCardButton
@onready var _reset_circle_button: Button = $Margin/PopupPanel/InnerMargin/Layout/ButtonRow/ResetCircleButton
@onready var _popup_layer: Control = $PopupLayer
@onready var _template_list: VBoxContainer = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/TemplateLibraryPanel/TemplateMargin/TemplateLayout/TemplateScroll/TemplateList
@onready var _material_list: GridContainer = $Margin/PopupPanel/InnerMargin/Layout/MainColumns/RightRail/MaterialBagPanel/MaterialMargin/MaterialLayout/MaterialScroll/MaterialList
@onready var _inventory_manager = get_node_or_null("/root/InventoryManager")
@onready var _card_manager = get_node_or_null("/root/CardManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

var _selected_template_id := "triangle"
var _selected_node_id := ""
var _node_assignments := {}
var _last_evaluation := {}
var _storage_scope := STORAGE_SCOPE_EXTERNAL
var _template_buttons: Dictionary = {}
var _material_buttons: Dictionary = {}

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	UI_BUTTON_FEEDBACK.wire_button(_generate_card_button)
	UI_BUTTON_FEEDBACK.wire_button(_reset_circle_button)
	_close_button.pressed.connect(_on_close_pressed)
	if _inventory_manager != null and _inventory_manager.has_signal("materials_changed"):
		_inventory_manager.materials_changed.connect(_on_material_bag_changed)
	if _card_manager != null and _card_manager.has_signal("cards_changed"):
		_card_manager.cards_changed.connect(_on_generated_card_bag_changed)
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("active_loadout_changed"):
		if not _realm_loadout_manager.active_loadout_changed.is_connected(_on_realm_loadout_changed):
			_realm_loadout_manager.active_loadout_changed.connect(_on_realm_loadout_changed)
	_magic_circle_editor.node_selected.connect(_on_editor_node_selected)
	_magic_circle_editor.node_clear_requested.connect(_on_editor_node_clear_requested)
	_magic_circle_editor.material_drop_requested.connect(_on_editor_material_drop_requested)
	_generate_card_button.pressed.connect(_on_generate_card_pressed)
	_reset_circle_button.pressed.connect(_on_reset_circle_pressed)
	_rebuild_template_buttons()
	_rebuild_material_buttons()
	_load_template(_get_default_template_id())

func configure_for_realm_expedition() -> void:
	_storage_scope = STORAGE_SCOPE_EXPEDITION
	if is_node_ready():
		_refresh_preview("Expedition crafting uses current-realm materials and stores cards in the current realm backpack.")

func _load_template(template_id: String) -> void:
	if template_id.is_empty() or not TEMPLATE_CATALOG.has_template(template_id):
		return

	_selected_template_id = template_id
	_selected_node_id = ""
	_node_assignments = {}
	var template_data := TEMPLATE_CATALOG.get_template(template_id)
	_magic_circle_editor.load_template(template_data, _node_assignments, _selected_node_id)
	_update_template_buttons()
	_refresh_preview("Select a node, then choose a material.")

func _on_close_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func _on_template_pressed(template_id: String) -> void:
	SceneManager.play_ui_button_click()
	_load_template(template_id)

func _on_editor_node_selected(node_id: String) -> void:
	_selected_node_id = node_id
	_refresh_preview("Selected node %s. Choose a material to place." % node_id)

func _on_editor_node_clear_requested(node_id: String) -> void:
	_node_assignments.erase(node_id)
	_selected_node_id = node_id
	_magic_circle_editor.set_assignments(_node_assignments, _selected_node_id)
	_refresh_preview("Cleared node %s." % node_id)

func _on_editor_material_drop_requested(node_id: String, material_id: String) -> void:
	_assign_material_to_node(material_id, node_id)

func _on_material_pressed(material_id: String) -> void:
	SceneManager.play_ui_button_click()
	_assign_material_to_node(material_id, _selected_node_id)

func _on_reset_circle_pressed() -> void:
	SceneManager.play_ui_button_click()
	_clear_current_assignments()
	_refresh_preview("Circle reset.")

func _on_generate_card_pressed() -> void:
	SceneManager.play_ui_button_click()
	_last_evaluation = _build_evaluation_result()
	if not bool(_last_evaluation.get("valid", false)):
		_refresh_preview(str(_last_evaluation.get("message", "Circle is incomplete.")))
		return

	var material_requirements: Dictionary = _last_evaluation.get("source_material_counts", {})
	if not _has_material_requirements(material_requirements):
		_refresh_preview("The current material scope no longer has enough stock for this recipe.")
		return

	var generated_card := GENERATED_CARD_BUILDER.build_from_alchemy_evaluation(_last_evaluation)
	if not _spend_material_requirements(material_requirements):
		_refresh_preview("Material spend failed. The bag changed before generation completed.")
		return
	generated_card = _store_generated_card(generated_card)

	var generated_name := generated_card.display_name if generated_card != null else "Generated Card"
	_show_generated_card_result(generated_card, _last_evaluation)
	_clear_current_assignments()
	_refresh_preview("%s was generated and stored in %s." % [generated_name, _get_generated_card_scope_label()])

func _on_material_bag_changed() -> void:
	_refresh_preview("Material Bag updated.")

func _on_generated_card_bag_changed() -> void:
	_refresh_generated_card_bag_label()

func _on_realm_loadout_changed(_summary := {}) -> void:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		_refresh_preview("Expedition backpack updated.")

func _refresh_preview(status_text: String) -> void:
	_last_evaluation = _build_evaluation_result()
	_set_safe_label_text(_status_label, _compact_status(status_text))
	_reset_circle_button.disabled = _node_assignments.is_empty()
	_generate_card_button.disabled = not _can_generate_current_recipe()
	_refresh_material_buttons()
	_refresh_live_preview_labels()
	_refresh_generated_card_bag_label()

func _refresh_live_preview_labels() -> void:
	# Keep the right rail compact: short authored labels only, no long preview blocks.
	var template_data := TEMPLATE_CATALOG.get_template(_selected_template_id)
	_set_safe_label_text(_selected_template_label, "Template: %s" % str(template_data.get("display_name", "Magic Circle")))
	_set_safe_label_text(_selected_materials_label, "Materials: %s" % _format_recipe_summary(_get_reserved_material_counts()))

	if bool(_last_evaluation.get("valid", false)):
		var material_requirements: Dictionary = _last_evaluation.get("source_material_counts", {})
		var can_generate := _has_material_requirements(material_requirements)
		var ready_text := "Ready to generate" if can_generate else "Ready, but bag stock is short"
		_set_safe_label_text(_circle_status_label, "Status: %s" % ready_text)
		return

	_set_safe_label_text(
		_circle_status_label,
		"Status: %s" % _compact_status(str(_last_evaluation.get("message", "Awaiting complete circle")))
	)

func _build_evaluation_result() -> Dictionary:
	return PLACEHOLDER_EVALUATOR.evaluate_circle(_build_circle_input())

func _build_circle_input() -> Dictionary:
	return PLACEHOLDER_EVALUATOR.build_circle_input(
		_selected_template_id,
		TEMPLATE_CATALOG.get_template(_selected_template_id),
		_node_assignments
	)

func _can_generate_current_recipe() -> bool:
	if not bool(_last_evaluation.get("valid", false)):
		return false
	return _has_material_requirements(_last_evaluation.get("source_material_counts", {}))

func _has_material_requirements(requirements: Dictionary) -> bool:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("can_spend_active_materials"):
			return false
		return bool(_realm_loadout_manager.call("can_spend_active_materials", requirements))
	if _inventory_manager == null or not _inventory_manager.has_method("can_spend_materials"):
		return false
	return bool(_inventory_manager.call("can_spend_materials", requirements))

func _refresh_generated_card_bag_label() -> void:
	var card_count := _get_generated_card_count()
	if card_count < 0:
		_set_safe_label_text(_generated_result_label, "%s: unavailable" % _get_generated_card_scope_label())
		return

	if card_count <= 0:
		_set_safe_label_text(_generated_result_label, "%s: 0 cards" % _get_generated_card_scope_label())
		return

	var latest_card := _get_latest_generated_card()
	var latest_name := latest_card.display_name if latest_card != null else "Generated Card"
	_set_safe_label_text(
		_generated_result_label,
		"%s: %s | Latest: %s" % [
			_get_generated_card_scope_label(),
			card_count,
			_compact_status(latest_name, 34),
		]
	)

func _refresh_material_buttons() -> void:
	var reserved_counts := _get_reserved_material_counts()
	for material_id in _material_buttons.keys():
		var material_data := MATERIAL_CATALOG.get_material(material_id)
		var material_button = _material_buttons[material_id]
		var bag_count := _get_material_bag_count(material_id)
		var reserved_elsewhere := int(_get_reserved_material_counts(_selected_node_id).get(material_id, 0))
		var free_count := maxi(bag_count - reserved_elsewhere, 0)
		var selected_assignment: Dictionary = _node_assignments.get(_selected_node_id, {})
		var selected_material_id := str(selected_assignment.get("material_id", ""))
		var label_text := "%s\nx%s free" % [
			material_data.get("button_label", material_data.get("display_name", material_id)),
			free_count,
		]
		var action_enabled: bool = free_count > 0 or selected_material_id == material_id
		var tooltip := _format_material_tooltip(
			material_data,
			bag_count,
			int(reserved_counts.get(material_id, 0)),
			free_count
		)
		material_button.configure_button(material_id, label_text, action_enabled, tooltip)

func _get_reserved_material_counts(excluded_node_id := "") -> Dictionary:
	var counts := {}
	for node_id in _node_assignments.keys():
		if not excluded_node_id.is_empty() and node_id == excluded_node_id:
			continue
		var assignment: Dictionary = _node_assignments[node_id]
		var material_id := str(assignment.get("material_id", ""))
		if material_id.is_empty():
			continue
		counts[material_id] = int(counts.get(material_id, 0)) + 1
	return counts

func _can_assign_material_to_selected_node(material_id: String) -> bool:
	return _can_assign_material_to_node(material_id, _selected_node_id)

func _get_material_bag_count(material_id: String) -> int:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("get_active_material_count"):
			return 0
		return int(_realm_loadout_manager.call("get_active_material_count", material_id))
	if _inventory_manager == null or not _inventory_manager.has_method("get_material_count"):
		return 0
	return int(_inventory_manager.call("get_material_count", material_id))

func _clear_current_assignments() -> void:
	_node_assignments = {}
	_selected_node_id = ""
	_magic_circle_editor.load_template(TEMPLATE_CATALOG.get_template(_selected_template_id), _node_assignments, _selected_node_id)

func _assign_material_to_node(material_id: String, node_id: String) -> void:
	if node_id.is_empty():
		_set_safe_label_text(_status_label, _compact_status("Select a circle node before placing a material."))
		return
	if not _can_assign_material_to_node(material_id, node_id):
		_refresh_preview("Not enough %s left in the Material Bag for this recipe." % _get_material_display_name(material_id))
		return

	var material_data := MATERIAL_CATALOG.get_material(material_id)
	if material_data.is_empty():
		return

	_selected_node_id = node_id
	material_data["material_id"] = material_id
	_node_assignments[node_id] = material_data
	_magic_circle_editor.set_assignments(_node_assignments, _selected_node_id)
	_refresh_preview("Placed %s on node %s." % [material_data["display_name"], node_id])

func _show_generated_card_result(card: GeneratedCardData, evaluation: Dictionary) -> void:
	for child in _popup_layer.get_children():
		child.queue_free()
	var popup = GENERATED_CARD_RESULT_POPUP_SCENE.instantiate()
	_popup_layer.add_child(popup)
	popup.configure_popup(card, evaluation, _get_generated_card_scope_label())

func _format_effect_lines(effect_lines: Array) -> String:
	if effect_lines.is_empty():
		return "No visible effects."
	var formatted_lines: Array[String] = []
	for effect_line in effect_lines:
		formatted_lines.append("- %s" % str(effect_line))
	return "\n".join(formatted_lines)

func _format_recipe_summary(material_counts: Dictionary) -> String:
	var summary_parts: Array[String] = []
	var extra_entries := 0
	for material_id in MATERIAL_CATALOG.get_material_ids():
		var quantity := int(material_counts.get(material_id, 0))
		if quantity <= 0:
			continue
		if summary_parts.size() >= recipe_summary_entry_limit:
			extra_entries += 1
			continue
		summary_parts.append(_format_compact_material_entry(material_id, quantity))
	if summary_parts.is_empty():
		return "None"
	if extra_entries > 0:
		summary_parts.append("+%s more" % extra_entries)
	return ", ".join(summary_parts)

func _format_compact_material_entry(material_id: String, quantity: int) -> String:
	var material_data := MATERIAL_CATALOG.get_material(material_id)
	var short_label := str(material_data.get("short_label", material_data.get("display_name", material_id)))
	return "%s x%s" % [short_label, quantity]

func _compact_status(message: String, max_length := -1) -> String:
	if max_length < 0:
		max_length = status_message_character_limit
	if message.length() <= max_length:
		return message
	return "%s..." % message.substr(0, max_length - 3)

func _set_safe_label_text(label: Label, text_value: String) -> void:
	label.text = text_value
	label.tooltip_text = text_value

func _format_material_tooltip(material_data: Dictionary, bag_count: int, reserved_count: int, free_count: int) -> String:
	var vector_data: Dictionary = material_data.get("vector", {})
	return "%s\nBag: %s | Reserved: %s | Free: %s\nF:%s W:%s E:%s A:%s" % [
		material_data.get("display_name", "Material"),
		bag_count,
		reserved_count,
		free_count,
		vector_data.get("fire", 0),
		vector_data.get("water", 0),
		vector_data.get("earth", 0),
		vector_data.get("wind", 0),
	]

func _get_material_display_name(material_id: String) -> String:
	var material_data := MATERIAL_CATALOG.get_material(material_id)
	return str(material_data.get("display_name", material_id))

func _can_assign_material_to_node(material_id: String, node_id: String) -> bool:
	var bag_count := _get_material_bag_count(material_id)
	var reserved_elsewhere := int(_get_reserved_material_counts(node_id).get(material_id, 0))
	return bag_count > reserved_elsewhere

func _spend_material_requirements(requirements: Dictionary) -> bool:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("spend_active_materials"):
			return false
		return bool(_realm_loadout_manager.call("spend_active_materials", requirements))
	if _inventory_manager == null or not _inventory_manager.has_method("spend_materials"):
		return false
	return bool(_inventory_manager.call("spend_materials", requirements))

func _store_generated_card(card: GeneratedCardData) -> GeneratedCardData:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("add_generated_card_to_active_run"):
			return _realm_loadout_manager.call("add_generated_card_to_active_run", card, "craft")
		return card
	if _card_manager != null and _card_manager.has_method("add_generated_card"):
		return _card_manager.call("add_generated_card", card)
	return card

func _get_generated_card_count() -> int:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("get_active_run_card_count"):
			return int(_realm_loadout_manager.call("get_active_run_card_count"))
		return -1
	if _card_manager != null and _card_manager.has_method("get_card_count"):
		return int(_card_manager.call("get_card_count"))
	return -1

func _get_latest_generated_card() -> GeneratedCardData:
	if _storage_scope == STORAGE_SCOPE_EXPEDITION:
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("get_active_run_cards"):
			var cards: Array = _realm_loadout_manager.call("get_active_run_cards")
			if not cards.is_empty():
				return cards.back()
		return null
	if _card_manager != null and _card_manager.has_method("get_latest_card"):
		return _card_manager.call("get_latest_card")
	return null

func _get_generated_card_scope_label() -> String:
	return "Expedition Cards" if _storage_scope == STORAGE_SCOPE_EXPEDITION else "Generated Card Bag"

func _update_template_buttons() -> void:
	for template_id in _template_buttons.keys():
		var template_data := TEMPLATE_CATALOG.get_template(template_id)
		var template_button = _template_buttons[template_id]
		template_button.configure_button(template_data, template_id == _selected_template_id)

func _rebuild_template_buttons() -> void:
	for child in _template_list.get_children():
		child.queue_free()
	_template_buttons.clear()
	for template_id in TEMPLATE_CATALOG.get_lab_template_ids():
		var template_button = TEMPLATE_BUTTON_SCENE.instantiate()
		_template_list.add_child(template_button)
		template_button.configure_button(TEMPLATE_CATALOG.get_template(template_id), template_id == _selected_template_id)
		template_button.template_pressed.connect(_on_template_pressed)
		_template_buttons[template_id] = template_button

func _rebuild_material_buttons() -> void:
	for child in _material_list.get_children():
		child.queue_free()
	_material_buttons.clear()
	for material_id in MATERIAL_CATALOG.get_material_ids():
		var material_button = MATERIAL_BUTTON_SCENE.instantiate()
		_material_list.add_child(material_button)
		material_button.material_pressed.connect(_on_material_pressed)
		_material_buttons[material_id] = material_button
	_refresh_material_buttons()

func _get_default_template_id() -> String:
	if TEMPLATE_CATALOG.has_template("triangle"):
		return "triangle"
	var lab_template_ids := TEMPLATE_CATALOG.get_lab_template_ids()
	return lab_template_ids[0] if not lab_template_ids.is_empty() else ""
