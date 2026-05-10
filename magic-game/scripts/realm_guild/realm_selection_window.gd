extends PanelContainer

const SCENE_PATHS := preload("res://scripts/common/scene_paths.gd")
const REALM_MAP_CONTROLLER := preload("res://scripts/exploration/realm_map_controller.gd")
const GENERATED_CARD_BAG_POPUP_SCENE := preload("res://scenes/ui/generated_card_bag_popup.tscn")
const GENERATED_CARD_VIEW_SCENE := preload("res://scenes/ui/generated_card_view.tscn")
const UI_BUTTON_FEEDBACK := preload("res://scripts/ui/ui_button_feedback.gd")

const REALM_ID := "training_realm"
const REALM_NAME := "Training Cavern"

@onready var _close_button: Button = $Margin/PopupPanel/InnerMargin/Layout/Header/CloseButton
@onready var _loadout_summary_label: Label = $Margin/PopupPanel/InnerMargin/Layout/BodyRow/RealmDetails/Margin/Layout/LoadoutSummaryLabel
@onready var _loadout_empty_label: Label = $Margin/PopupPanel/InnerMargin/Layout/BodyRow/RealmDetails/Margin/Layout/LoadoutScroll/LoadoutContent/LoadoutEmptyLabel
@onready var _selected_card_list: HFlowContainer = $Margin/PopupPanel/InnerMargin/Layout/BodyRow/RealmDetails/Margin/Layout/LoadoutScroll/LoadoutContent/SelectedCardList
@onready var _open_card_bag_button: Button = $Margin/PopupPanel/InnerMargin/Layout/BodyRow/RealmDetails/Margin/Layout/OpenCardBagButton
@onready var _status_label: Label = $Margin/PopupPanel/InnerMargin/Layout/StatusLabel
@onready var _start_expedition_button: Button = $Margin/PopupPanel/InnerMargin/Layout/StartExpedition
@onready var _popup_layer: Control = $PopupLayer
@onready var _scene_manager: Node = get_node("/root/SceneManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")
@onready var _game_manager = get_node_or_null("/root/GameManager")

func _ready() -> void:
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI_BUTTON_FEEDBACK.wire_button(_close_button)
	UI_BUTTON_FEEDBACK.wire_button(_open_card_bag_button)
	UI_BUTTON_FEEDBACK.wire_button(_start_expedition_button)
	_close_button.pressed.connect(_on_close_button_pressed)
	_open_card_bag_button.pressed.connect(_on_open_card_bag_pressed)
	_start_expedition_button.pressed.connect(_on_start_expedition_pressed)
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("draft_selection_changed"):
		if not _realm_loadout_manager.draft_selection_changed.is_connected(_refresh_loadout_view):
			_realm_loadout_manager.draft_selection_changed.connect(_refresh_loadout_view)
	_refresh_loadout_view()

func _on_start_expedition_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	var selected_card_count := _get_selected_card_count()
	var commit_result: Dictionary = {}
	if _realm_loadout_manager != null and _realm_loadout_manager.has_method("commit_draft_selection_to_active_run"):
		commit_result = _realm_loadout_manager.call("commit_draft_selection_to_active_run", {
			"realm_id": REALM_ID,
			"realm_name": REALM_NAME,
			"entry_source": "realm_selection_window",
		})
	if selected_card_count > 0 and commit_result.is_empty():
		_status_label.text = "Realm loadout transfer failed. The expedition did not start, and the external bag was left unchanged."
		_status_label.tooltip_text = _status_label.text
		return
	if _game_manager != null:
		_game_manager.active_expedition = {
			"realm_id": REALM_ID,
			"realm_name": REALM_NAME,
			"selected_card_count": int(commit_result.get("selected_card_count", selected_card_count)),
			"card_scope": "internal_realm_run_snapshot",
		}
	REALM_MAP_CONTROLLER.reset_placeholder_progress()
	_scene_manager.call("change_scene", SCENE_PATHS.REALM_MAP)

func _on_open_card_bag_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	for child in _popup_layer.get_children():
		child.queue_free()
	var popup = GENERATED_CARD_BAG_POPUP_SCENE.instantiate()
	popup.configure_for_loadout_selection()
	_popup_layer.add_child(popup)

func _on_close_button_pressed() -> void:
	_scene_manager.call("play_ui_button_click")
	queue_free()

func _refresh_loadout_view(_unused := {}) -> void:
	var selected_cards: Array = _get_selected_cards()
	var selection_limit := _get_selection_limit()
	_loadout_summary_label.text = "Realm Loadout: %s/%s selected" % [selected_cards.size(), selection_limit]

	for child in _selected_card_list.get_children():
		child.queue_free()

	_loadout_empty_label.visible = selected_cards.is_empty()
	if not selected_cards.is_empty():
		for card in selected_cards:
			var card_view = GENERATED_CARD_VIEW_SCENE.instantiate()
			card_view.compact_mode = true
			card_view.configure_from_generated_card(card)
			_selected_card_list.add_child(card_view)

	if selected_cards.is_empty():
		_status_label.text = "No cards selected yet. Starting now will enter the realm with an empty expedition card set."
	else:
		_status_label.text = "%s generated cards will transfer out of the external bag when the expedition starts. Battle will then use internal run copies." % selected_cards.size()
	_status_label.tooltip_text = _status_label.text

func _get_selected_cards() -> Array:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("get_draft_selected_cards"):
		return []
	return _realm_loadout_manager.call("get_draft_selected_cards")

func _get_selection_limit() -> int:
	if _realm_loadout_manager == null or not _realm_loadout_manager.has_method("get_selection_limit"):
		return 0
	return int(_realm_loadout_manager.call("get_selection_limit"))

func _get_selected_card_count() -> int:
	return _get_selected_cards().size()
