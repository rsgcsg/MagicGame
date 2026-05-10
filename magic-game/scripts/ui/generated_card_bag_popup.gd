extends PanelContainer

const ENTRY_ROW_SCENE := preload("res://scenes/ui/generated_card_bag_entry_row.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

@export var popup_title := "Generated Card Bag"
@export var selection_enabled := false

@onready var _title_label: Label = $Margin/PopupPanel/InnerMargin/Layout/Header/TitleLabel
@onready var _subtitle_label: Label = $Margin/PopupPanel/InnerMargin/Layout/Header/SubtitleLabel
@onready var _summary_label: Label = $Margin/PopupPanel/InnerMargin/Layout/SummaryLabel
@onready var _entry_list: VBoxContainer = $Margin/PopupPanel/InnerMargin/Layout/BodyScroll/EntryList
@onready var _status_label: Label = $Margin/PopupPanel/InnerMargin/Layout/FooterRow/StatusLabel
@onready var _clear_selection_button: Button = $Margin/PopupPanel/InnerMargin/Layout/FooterRow/ClearSelectionButton
@onready var _close_button: Button = $Margin/PopupPanel/InnerMargin/Layout/FooterRow/CloseButton
@onready var _card_manager = get_node_or_null("/root/CardManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

func _ready() -> void:
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	UI_BUTTON_FEEDBACK.wire_button(_clear_selection_button)
	_close_button.pressed.connect(_on_close_button_pressed)
	_clear_selection_button.pressed.connect(_on_clear_selection_pressed)
	if _card_manager != null and _card_manager.has_signal("cards_changed"):
		if not _card_manager.cards_changed.is_connected(_refresh):
			_card_manager.cards_changed.connect(_refresh)
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("draft_selection_changed"):
		if not _realm_loadout_manager.draft_selection_changed.is_connected(_refresh):
			_realm_loadout_manager.draft_selection_changed.connect(_refresh)
	_refresh()

func configure_for_view_mode() -> void:
	selection_enabled = false
	popup_title = "Generated Card Bag"
	if is_node_ready():
		_refresh()

func configure_for_loadout_selection() -> void:
	selection_enabled = true
	popup_title = "Realm Loadout Selection"
	if is_node_ready():
		_refresh()

func _refresh(_unused := {}) -> void:
	_title_label.text = popup_title
	_subtitle_label.text = _build_subtitle_text()
	_summary_label.text = _build_summary_text()
	_status_label.text = _build_status_text()
	_status_label.tooltip_text = _status_label.text
	_clear_selection_button.visible = selection_enabled
	_clear_selection_button.disabled = _get_selected_count() <= 0

	for child in _entry_list.get_children():
		child.queue_free()

	var cards: Array[GeneratedCardData] = _card_manager.get_cards() if _card_manager != null else []
	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No generated cards are stored in the external bag yet."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_entry_list.add_child(empty_label)
		return

	for card in cards:
		var entry = ENTRY_ROW_SCENE.instantiate()
		var runtime_instance_id := card.runtime_instance_id
		var is_selected := _is_selected(runtime_instance_id)
		entry.runtime_instance_id = runtime_instance_id
		entry.card_name = card.display_name
		entry.action_point_cost = card.action_point_cost
		entry.single_use = card.single_use
		entry.template_id = card.source_template_id if not card.source_template_id.is_empty() else "triangle"
		entry.card_body_text = _build_card_body_text(card)
		entry.effect_summary = _build_effect_summary(card)
		entry.meta_summary = _build_meta_summary(card)
		entry.action_enabled = selection_enabled
		entry.action_text = "Remove" if is_selected else "Add"
		entry.action_pressed.connect(_on_entry_action_pressed)
		_entry_list.add_child(entry)

func _on_entry_action_pressed(runtime_instance_id: String) -> void:
	if not selection_enabled or _realm_loadout_manager == null:
		return
	SceneManager.play_ui_button_click()
	_realm_loadout_manager.call("toggle_draft_card", runtime_instance_id)

func _on_clear_selection_pressed() -> void:
	SceneManager.play_ui_button_click()
	if _realm_loadout_manager != null:
		_realm_loadout_manager.call("clear_draft_selection")

func _on_close_button_pressed() -> void:
	SceneManager.play_ui_button_click()
	queue_free()

func _build_subtitle_text() -> String:
	if selection_enabled:
		return "Pick cards from the external bag to transfer into the next realm run."
	return "Workshop-facing generated cards stored outside battle and expedition state."

func _build_summary_text() -> String:
	var card_count: int = _card_manager.get_card_count() if _card_manager != null else 0
	if not selection_enabled:
		return "External bag: %s cards" % card_count
	return "External bag: %s cards | Draft realm loadout: %s/%s" % [
		card_count,
		_get_selected_count(),
		_get_selection_limit(),
	]

func _build_status_text() -> String:
	if selection_enabled:
		return "Draft selection is safe until expedition start. Starting the expedition transfers those cards out of the external bag."
	return "View-only popup. Use the Realm Guide to choose cards for a run."

func _build_effect_summary(card: GeneratedCardData) -> String:
	if not card.effect_lines.is_empty():
		return "\n".join(card.effect_lines)
	if not card.description.is_empty():
		return card.description
	return "No visible effect lines recorded."

func _build_card_body_text(card: GeneratedCardData) -> String:
	if not card.effect_lines.is_empty() and not card.description.is_empty():
		return "%s\n\n%s" % ["\n".join(card.effect_lines), card.description]
	if not card.effect_lines.is_empty():
		return "\n".join(card.effect_lines)
	if not card.description.is_empty():
		return card.description
	return "No visible effect lines recorded."

func _build_meta_summary(card: GeneratedCardData) -> String:
	return "Cost %s | Single Use %s | Template %s" % [
		card.action_point_cost,
		"Yes" if card.single_use else "No",
		card.source_template_id if not card.source_template_id.is_empty() else "unknown",
	]

func _get_selected_count() -> int:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("get_draft_selected_count"):
		return 0
	return int(_realm_loadout_manager.call("get_draft_selected_count"))

func _get_selection_limit() -> int:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("get_selection_limit"):
		return 0
	return int(_realm_loadout_manager.call("get_selection_limit"))

func _is_selected(runtime_instance_id: String) -> bool:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("is_draft_selected"):
		return false
	return bool(_realm_loadout_manager.call("is_draft_selected", runtime_instance_id))
