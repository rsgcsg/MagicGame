extends PanelContainer

const GENERATED_CARD_VIEW_SCENE := preload("res://scenes/ui/generated_card_view.tscn")
const SCOPE_EXTERNAL := "external"
const SCOPE_EXPEDITION := "expedition"

@export var title_text := "Generated Cards"
@export_enum("external", "expedition") var data_scope := SCOPE_EXTERNAL
@export_range(1, 5, 1) var max_columns := 4

@onready var _title_label: Label = $Margin/Layout/TitleLabel
@onready var _list_scroll: ScrollContainer = $Margin/Layout/ListScroll
@onready var _card_grid: GridContainer = $Margin/Layout/ListScroll/Centering/CardGrid
@onready var _empty_label: Label = $Margin/Layout/EmptyLabel
@onready var _card_manager = get_node_or_null("/root/CardManager")
@onready var _realm_loadout_manager = get_node_or_null("/root/RealmLoadoutManager")

func _ready() -> void:
	_rebuild()
	if _card_manager != null and not _card_manager.cards_changed.is_connected(_rebuild):
		_card_manager.cards_changed.connect(_rebuild)
	if _realm_loadout_manager != null and _realm_loadout_manager.has_signal("active_loadout_changed"):
		if not _realm_loadout_manager.active_loadout_changed.is_connected(_rebuild):
			_realm_loadout_manager.active_loadout_changed.connect(_rebuild)

func set_data_scope(scope_id: String) -> void:
	data_scope = scope_id
	if is_node_ready():
		_rebuild()

func _rebuild() -> void:
	for child in _card_grid.get_children():
		child.queue_free()
	var cards := _get_cards_for_scope()
	var card_count := cards.size()
	_title_label.text = "%s (%s)" % [title_text, card_count]
	_card_grid.columns = maxi(1, mini(card_count, max_columns))
	_empty_label.visible = card_count == 0
	_list_scroll.visible = card_count > 0

	if card_count == 0:
		return

	for card in cards:
		var card_view = GENERATED_CARD_VIEW_SCENE.instantiate()
		card_view.compact_mode = true
		card_view.configure_from_generated_card(card)
		_card_grid.add_child(card_view)

func _get_cards_for_scope() -> Array:
	if data_scope == SCOPE_EXPEDITION:
		if _realm_loadout_manager != null and _realm_loadout_manager.has_method("get_active_run_cards"):
			return _realm_loadout_manager.call("get_active_run_cards")
		return []
	return _card_manager.get_cards() if _card_manager != null else []
