extends PanelContainer

const SCOPE_EXTERNAL := "external"
const SCOPE_EXPEDITION := "expedition"
const SECTION_CARDS := "cards"
const SECTION_MATERIALS := "materials"
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var popup_title := "Backpack"

@onready var _title_label: Label = $BackdropMargin/PopupPanel/InnerMargin/Layout/Header/TitleLabel
@onready var _summary_label: Label = $BackdropMargin/PopupPanel/InnerMargin/Layout/SummaryLabel
@onready var _external_scope_button: Button = $BackdropMargin/PopupPanel/InnerMargin/Layout/ToolbarRow/ScopePanel/ScopeMargin/ScopeLayout/ScopeRow/ExternalScopeButton
@onready var _expedition_scope_button: Button = $BackdropMargin/PopupPanel/InnerMargin/Layout/ToolbarRow/ScopePanel/ScopeMargin/ScopeLayout/ScopeRow/ExpeditionScopeButton
@onready var _cards_section_button: Button = $BackdropMargin/PopupPanel/InnerMargin/Layout/ToolbarRow/SectionPanel/SectionMargin/SectionLayout/SectionRow/CardsSectionButton
@onready var _materials_section_button: Button = $BackdropMargin/PopupPanel/InnerMargin/Layout/ToolbarRow/SectionPanel/SectionMargin/SectionLayout/SectionRow/MaterialsSectionButton
@onready var _card_panel = $BackdropMargin/PopupPanel/InnerMargin/Layout/BodyPanel/BodyMargin/Body/CardBackpackPanel
@onready var _material_panel = $BackdropMargin/PopupPanel/InnerMargin/Layout/BodyPanel/BodyMargin/Body/MaterialBagPanel
@onready var _status_label: Label = $BackdropMargin/PopupPanel/InnerMargin/Layout/FooterRow/StatusLabel
@onready var _close_button: Button = $BackdropMargin/PopupPanel/InnerMargin/Layout/Header/CloseButton
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

var _current_scope := SCOPE_EXTERNAL
var _current_section := SECTION_CARDS

func _ready() -> void:
	_title_label.text = popup_title
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	UI_BUTTON_FEEDBACK.wire_button(_external_scope_button)
	UI_BUTTON_FEEDBACK.wire_button(_expedition_scope_button)
	UI_BUTTON_FEEDBACK.wire_button(_cards_section_button)
	UI_BUTTON_FEEDBACK.wire_button(_materials_section_button)
	_close_button.pressed.connect(_on_close_button_pressed)
	_external_scope_button.pressed.connect(_on_scope_button_pressed.bind(SCOPE_EXTERNAL))
	_expedition_scope_button.pressed.connect(_on_scope_button_pressed.bind(SCOPE_EXPEDITION))
	_cards_section_button.pressed.connect(_on_section_button_pressed.bind(SECTION_CARDS))
	_materials_section_button.pressed.connect(_on_section_button_pressed.bind(SECTION_MATERIALS))
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("active_loadout_changed"):
		if not _realm_loadout_manager.active_loadout_changed.is_connected(_refresh):
			_realm_loadout_manager.active_loadout_changed.connect(_refresh)
	_refresh()

func configure_default_scope(scope_id: String) -> void:
	_current_scope = scope_id
	if is_node_ready():
		_refresh()

func _on_close_button_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func _on_scope_button_pressed(scope_id: String) -> void:
	SceneManager.play_ui_button_click()
	_current_scope = scope_id
	_refresh()

func _on_section_button_pressed(section_id: String) -> void:
	SceneManager.play_ui_button_click()
	_current_section = section_id
	_refresh()

func _refresh(_unused := {}) -> void:
	if _current_scope == SCOPE_EXPEDITION and not _has_active_expedition():
		_current_scope = SCOPE_EXTERNAL

	_external_scope_button.disabled = _current_scope == SCOPE_EXTERNAL
	_expedition_scope_button.disabled = _current_scope == SCOPE_EXPEDITION or not _has_active_expedition()
	_cards_section_button.disabled = _current_section == SECTION_CARDS
	_materials_section_button.disabled = _current_section == SECTION_MATERIALS

	_card_panel.visible = _current_section == SECTION_CARDS
	_material_panel.visible = _current_section == SECTION_MATERIALS

	_card_panel.title_text = "External Cards" if _current_scope == SCOPE_EXTERNAL else "Current Realm Cards"
	_card_panel.set_data_scope(_current_scope)
	_material_panel.title_text = "External Materials" if _current_scope == SCOPE_EXTERNAL else "Current Realm Materials"
	_material_panel.set_data_scope(_current_scope)

	_summary_label.text = _build_summary_text()
	_summary_label.tooltip_text = _summary_label.text
	_status_label.text = _build_status_text()
	_status_label.tooltip_text = _status_label.text

func _build_summary_text() -> String:
	if _current_scope == SCOPE_EXPEDITION:
		var active_summary: Dictionary = _realm_loadout_manager.call("get_active_loadout_summary") if _realm_loadout_manager != null else {}
		return "Current Realm: %s cards | %s materials" % [
			int(active_summary.get("selected_card_count", 0)),
			int(active_summary.get("material_total_count", 0)),
		]
	return "External Backpack: workshop cards and materials stored outside expedition state."

func _build_status_text() -> String:
	if _current_scope == SCOPE_EXPEDITION:
		return "Current realm resources stay internal until the expedition ends. Surviving cards and materials then return to the workshop bags."
	return "External resources are safe outside battle. Realm loadout transfer moves selected cards out only when the expedition starts."

func _has_active_expedition() -> bool:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("has_active_expedition"):
		return false
	return bool(_realm_loadout_manager.call("has_active_expedition"))
