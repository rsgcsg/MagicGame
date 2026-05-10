extends SceneTree

const RAW_MATERIAL_SHOP_SERVICE := preload("res://scripts/raw_material_shop/raw_material_shop_service.gd")
const INVENTORY_MANAGER_SCRIPT := preload("res://scripts/managers/inventory_manager.gd")

var _failures: Array[String] = []

class MockGameManager extends Node:
	var gold := 0

	func can_afford_gold(amount: int) -> bool:
		return gold >= maxi(amount, 0)

	func add_gold(amount: int) -> void:
		gold = maxi(0, gold + amount)

	func spend_gold(amount: int) -> bool:
		var sanitized_amount := maxi(amount, 0)
		if gold < sanitized_amount:
			return false
		gold -= sanitized_amount
		return true

func _initialize() -> void:
	var game_manager: MockGameManager = MockGameManager.new()
	game_manager.name = "GameManager"
	root.add_child(game_manager)

	var inventory_manager: Node = Node.new()
	inventory_manager.name = "InventoryManager"
	inventory_manager.set_script(INVENTORY_MANAGER_SCRIPT)
	root.add_child(inventory_manager)

	await process_frame

	_run_checks(inventory_manager, game_manager)

	game_manager.queue_free()
	inventory_manager.queue_free()
	await process_frame

	if _failures.is_empty():
		print("Raw material shop sanity check passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)

func _run_checks(inventory_manager: Node, game_manager: MockGameManager) -> void:
	var stock_entries := RAW_MATERIAL_SHOP_SERVICE.load_stock_entries()
	_expect(stock_entries.size() >= 8, "Shop stock should include an expanded material lineup.")

	var stock_lookup := RAW_MATERIAL_SHOP_SERVICE.build_stock_lookup(stock_entries)
	var buy_target := "stormglass_prism"
	var buy_price := int(stock_lookup.get(buy_target, {}).get("buy_price", 0))
	game_manager.gold = buy_price + 10
	var owned_before_buy := int(inventory_manager.call("get_material_count", buy_target))
	var buy_result := RAW_MATERIAL_SHOP_SERVICE.try_buy_one(buy_target, stock_lookup, inventory_manager, game_manager)
	_expect(bool(buy_result.get("success", false)), "Buying a stocked material should succeed.")
	_expect(int(inventory_manager.call("get_material_count", buy_target)) == owned_before_buy + 1, "Buying should add one material to the bag.")
	_expect(game_manager.gold == 10, "Buying should spend the listed gold price.")

	game_manager.gold = buy_price - 1
	var failed_buy := RAW_MATERIAL_SHOP_SERVICE.try_buy_one(buy_target, stock_lookup, inventory_manager, game_manager)
	_expect(not bool(failed_buy.get("success", false)), "Buying without enough gold should fail.")

	var sell_target := "fire_crystal"
	inventory_manager.call("set_material_count", sell_target, 2)
	game_manager.gold = 0
	var sell_price := int(RAW_MATERIAL_SHOP_SERVICE.build_sell_entry(sell_target, stock_lookup, inventory_manager).get("sell_price", 0))
	var sell_result := RAW_MATERIAL_SHOP_SERVICE.try_sell_one(sell_target, stock_lookup, inventory_manager, game_manager)
	_expect(bool(sell_result.get("success", false)), "Selling an owned material should succeed.")
	_expect(int(inventory_manager.call("get_material_count", sell_target)) == 1, "Selling should remove one material from the bag.")
	_expect(game_manager.gold == sell_price, "Selling should add the listed gold price.")

	inventory_manager.call("set_material_count", "moss_amber", 0)
	var failed_sell := RAW_MATERIAL_SHOP_SERVICE.try_sell_one("moss_amber", stock_lookup, inventory_manager, game_manager)
	_expect(not bool(failed_sell.get("success", false)), "Selling a material the player does not own should fail.")

func _expect(condition: bool, failure_message: String) -> void:
	if not condition:
		_failures.append(failure_message)
