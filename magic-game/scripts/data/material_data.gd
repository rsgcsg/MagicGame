class_name MaterialData
extends Resource

@export var sort_order := 0
@export var material_id := ""
@export var display_name := ""
@export var button_label := ""
@export var short_label := ""
@export_multiline var descriptor := ""
@export var icon_path := ""
@export var rarity := "common"
@export var stability := "stable"
@export var shop_buy_price := 0
@export var shop_sell_price := 0
@export var fire := 0
@export var water := 0
@export var earth := 0
@export var wind := 0

func get_element_vector() -> Dictionary:
	return {
		"fire": fire,
		"water": water,
		"earth": earth,
		"wind": wind,
	}

func to_catalog_entry() -> Dictionary:
	return {
		"material_id": material_id,
		"display_name": display_name,
		"button_label": button_label if not button_label.is_empty() else display_name,
		"short_label": short_label if not short_label.is_empty() else display_name,
		"descriptor": descriptor,
		"icon_path": icon_path,
		"rarity": rarity,
		"stability": stability,
		"shop_buy_price": shop_buy_price,
		"shop_sell_price": shop_sell_price,
		"sort_order": sort_order,
		"vector": get_element_vector(),
	}
