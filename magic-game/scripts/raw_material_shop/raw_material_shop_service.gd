class_name RawMaterialShopService
extends RefCounted

const SHOP_STOCK_PATH := "res://data/shops/raw_material_shop_stock.json"
const MAGIC_MATERIAL_CATALOG := preload("res://scripts/magic_circle/magic_material_catalog.gd")

static func load_stock_entries() -> Array[Dictionary]:
	var raw_json := FileAccess.get_file_as_string(SHOP_STOCK_PATH)
	if raw_json.is_empty():
		return []
	var parsed: Variant = JSON.parse_string(raw_json)
	if not (parsed is Dictionary):
		return []
	var raw_entries: Variant = (parsed as Dictionary).get("entries", [])
	if not (raw_entries is Array):
		return []

	var stock_entries: Array[Dictionary] = []
	for raw_entry in raw_entries:
		if not (raw_entry is Dictionary):
			continue
		var material_id := str(raw_entry.get("material_id", ""))
		if material_id.is_empty() or not MAGIC_MATERIAL_CATALOG.has_material(material_id):
			continue
		var material_data := MAGIC_MATERIAL_CATALOG.get_material(material_id)
		stock_entries.append({
			"material_id": material_id,
			"display_name": str(material_data.get("display_name", material_id)),
			"short_label": str(material_data.get("short_label", material_id)),
			"descriptor": str(material_data.get("descriptor", "")),
			"rarity": str(material_data.get("rarity", "common")).capitalize(),
			"stability": str(material_data.get("stability", "stable")).capitalize(),
			"buy_price": int(raw_entry.get("buy_price", material_data.get("shop_buy_price", 0))),
			"sell_price": int(raw_entry.get("sell_price", material_data.get("shop_sell_price", 0))),
			"stock": maxi(int(raw_entry.get("stock", 0)), 0),
			"vector_summary": _build_vector_summary(material_data.get("vector", {})),
		})
	return stock_entries

static func build_stock_lookup(stock_entries: Array[Dictionary]) -> Dictionary:
	var lookup: Dictionary = {}
	for entry in stock_entries:
		lookup[str(entry.get("material_id", ""))] = entry.duplicate(true)
	return lookup

static func list_sellable_material_ids(stock_lookup: Dictionary, inventory_manager: Node) -> Array[String]:
	var material_ids: Array[String] = []
	for material_id in MAGIC_MATERIAL_CATALOG.get_material_ids():
		if _get_owned_count(material_id, inventory_manager) <= 0:
			continue
		material_ids.append(material_id)
	return material_ids

static func build_sell_entry(material_id: String, stock_lookup: Dictionary, inventory_manager: Node) -> Dictionary:
	var material_data := MAGIC_MATERIAL_CATALOG.get_material(material_id)
	var stock_entry: Dictionary = stock_lookup.get(material_id, {})
	return {
		"material_id": material_id,
		"display_name": str(material_data.get("display_name", material_id)),
		"short_label": str(material_data.get("short_label", material_id)),
		"descriptor": str(material_data.get("descriptor", "")),
		"rarity": str(material_data.get("rarity", "common")).capitalize(),
		"stability": str(material_data.get("stability", "stable")).capitalize(),
		"buy_price": int(stock_entry.get("buy_price", material_data.get("shop_buy_price", 0))),
		"sell_price": int(stock_entry.get("sell_price", material_data.get("shop_sell_price", 0))),
		"stock": maxi(int(stock_entry.get("stock", 0)), 0),
		"owned": _get_owned_count(material_id, inventory_manager),
		"vector_summary": _build_vector_summary(material_data.get("vector", {})),
	}

static func try_buy_one(material_id: String, stock_lookup: Dictionary, inventory_manager: Node, game_manager: Node) -> Dictionary:
	var entry: Dictionary = stock_lookup.get(material_id, {})
	if entry.is_empty():
		return {"success": false, "message": "That material is not in the shop stock."}
	var stock := int(entry.get("stock", 0))
	var price := int(entry.get("buy_price", 0))
	if stock <= 0:
		return {"success": false, "message": "%s is sold out." % entry.get("display_name", material_id)}
	if game_manager == null or not game_manager.has_method("can_afford_gold"):
		return {"success": false, "message": "Gold state is unavailable."}
	if inventory_manager == null or not inventory_manager.has_method("add_material"):
		return {"success": false, "message": "Material bag is unavailable."}
	if not bool(game_manager.call("can_afford_gold", price)):
		return {"success": false, "message": "Not enough gold for %s." % entry.get("display_name", material_id)}
	if not bool(game_manager.call("spend_gold", price)):
		return {"success": false, "message": "The purchase could not be completed."}

	inventory_manager.call("add_material", material_id, 1)
	entry["stock"] = stock - 1
	stock_lookup[material_id] = entry
	return {
		"success": true,
		"message": "Bought 1 %s for %s gold." % [entry.get("display_name", material_id), price],
	}

static func try_sell_one(material_id: String, stock_lookup: Dictionary, inventory_manager: Node, game_manager: Node) -> Dictionary:
	var entry: Dictionary = stock_lookup.get(material_id, build_sell_entry(material_id, stock_lookup, inventory_manager))
	var owned := _get_owned_count(material_id, inventory_manager)
	var price := int(entry.get("sell_price", 0))
	if owned <= 0:
		return {"success": false, "message": "You do not own any %s." % entry.get("display_name", material_id)}
	if inventory_manager == null or not inventory_manager.has_method("remove_material"):
		return {"success": false, "message": "Material bag is unavailable."}
	if game_manager == null or not game_manager.has_method("add_gold"):
		return {"success": false, "message": "Gold state is unavailable."}
	if not bool(inventory_manager.call("remove_material", material_id, 1)):
		return {"success": false, "message": "The sale could not be completed."}

	game_manager.call("add_gold", price)
	entry["stock"] = maxi(int(entry.get("stock", 0)), 0) + 1
	stock_lookup[material_id] = entry
	return {
		"success": true,
		"message": "Sold 1 %s for %s gold." % [entry.get("display_name", material_id), price],
	}

static func _get_owned_count(material_id: String, inventory_manager: Node) -> int:
	if inventory_manager == null or not inventory_manager.has_method("get_material_count"):
		return 0
	return int(inventory_manager.call("get_material_count", material_id))

static func _build_vector_summary(vector_variant: Variant) -> String:
	if not (vector_variant is Dictionary):
		return ""
	var vector: Dictionary = vector_variant
	return "F%s W%s E%s A%s" % [
		int(vector.get("fire", 0)),
		int(vector.get("water", 0)),
		int(vector.get("earth", 0)),
		int(vector.get("wind", 0)),
	]
