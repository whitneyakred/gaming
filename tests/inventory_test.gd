extends SceneTree
## Run with bash ./test-inv-system.sh

const ITEM_DATA_SCRIPT := preload("res://scripts/item-system/item_data.gd")
const INVENTORY_USAGE_SCRIPT := preload("res://scripts/inventory-system/inventory_usage.gd")
const PLAYER_INVENTORY_SCRIPT := preload("res://scripts/inventory-system/player_inventory.gd")

var failures: int = 0
var passed: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, test_name: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % test_name)
		return

	failures += 1
	push_error("FAIL: %s" % test_name)

func _new_inventory() -> Variant:
	return PLAYER_INVENTORY_SCRIPT.new()

func _run() -> void:
	var item_database: Variant = get_root().get_node_or_null("ItemDatabase")
	if item_database == null:
		_check(false, "ItemDatabase autoload is available")
		quit(1)
		return

	var cod: Variant = item_database.call("get_item", &"fish_cod")
	var rope: Variant = item_database.call("get_item", &"rope")
	var coconut: Variant = item_database.call("get_item", &"coconut")
	var fishing_rod: Variant = item_database.call("get_item", &"fishing_rod")
	_check(cod != null and rope != null and coconut != null and fishing_rod != null, "Item catalog provides inventory test items")
	if cod == null or rope == null or coconut == null or fishing_rod == null:
		quit(1)
		return

	var inventory: Variant = _new_inventory()
	_check(inventory.max_inv_space == 4, "PlayerInventory keeps four distinct-item spaces")
	_check(inventory.add_item(cod), "add_item adds one valid item")
	_check(inventory.get_quantity(&"fish_cod") == 1, "get_quantity returns the stored amount")
	_check(inventory.try_add(&"fish_cod", 2), "try_add adds a valid amount")
	_check(inventory.get_quantity(&"fish_cod") == 3, "try_add updates the stored amount")
	_check(not inventory.try_add(&"fish_cod", 8), "try_add rejects an amount beyond the item stack limit")
	_check(inventory.get_quantity(&"fish_cod") == 3, "Rejected try_add does not partially change quantity")
	_check(not inventory.try_add(&"fish_cod", 0), "try_add rejects zero amount")
	_check(not inventory.try_add(&"missing_item", 1), "try_add rejects an unknown item ID")
	_check(inventory.remove_item(&"fish_cod", 1), "remove_item removes a valid amount")
	_check(inventory.get_quantity(&"fish_cod") == 2, "remove_item updates the stored amount")
	_check(inventory.try_remove(&"fish_cod", 2), "try_remove removes the requested amount")
	_check(inventory.get_quantity(&"fish_cod") == 0 and inventory.inventory.is_empty(), "Removing the last item frees its distinct-item space")
	_check(not inventory.try_remove(&"fish_cod", 1), "try_remove rejects an unavailable item")
	_check(not inventory.try_remove(&"rope", 0), "try_remove rejects zero amount")

	inventory.add_item(cod)
	inventory.add_item(rope)
	inventory.add_item(coconut)
	inventory.add_item(fishing_rod)
	_check(not inventory.add_item(ITEM_DATA_SCRIPT.new()), "add_item rejects an item when all four spaces are occupied")
	_check(inventory.move_item(&"fishing_rod", 0), "move_item reorders an owned item type")
	_check(inventory.inventory[0].id == &"fishing_rod", "move_item puts the item at the requested index")
	_check(not inventory.move_item(&"missing_item", 0), "move_item rejects an item that is not owned")
	_check(not inventory.move_item(&"fishing_rod", 4), "move_item rejects an index outside occupied entries")

	var signal_inventory: Variant = _new_inventory()
	var change_count := {"value": 0}
	signal_inventory.inventory_changed.connect(func() -> void: change_count["value"] += 1)
	signal_inventory.add_item(cod)
	signal_inventory.try_add(&"fish_cod", 1)
	signal_inventory.try_remove(&"fish_cod", 1)
	signal_inventory.move_item(&"fish_cod", 0)
	signal_inventory.clear()
	_check(change_count["value"] == 4, "inventory_changed emits once for each successful state mutation")
	signal_inventory.clear()
	signal_inventory.try_add(&"fish_cod", 99)
	_check(change_count["value"] == 4, "inventory_changed does not emit for no-op or rejected mutations")

	inventory.clear()
	_check(inventory.inventory.is_empty() and inventory.quantities.is_empty(), "clear empties all items and quantities")

	var usage: Variant = INVENTORY_USAGE_SCRIPT.new()
	usage.player_inventory = _new_inventory()
	_check(usage.add_item(cod), "InventoryUsage.add_item forwards to PlayerInventory")
	_check(usage.try_add(&"fish_cod", 2), "InventoryUsage.try_add forwards to PlayerInventory")
	_check(usage.get_quantity(&"fish_cod") == 3, "InventoryUsage.get_quantity forwards to PlayerInventory")
	_check(usage.try_remove(&"fish_cod", 1), "InventoryUsage.try_remove forwards to PlayerInventory")
	usage.add_item(rope)
	_check(usage.move_item(&"rope", 0), "InventoryUsage.move_item forwards to PlayerInventory")
	usage.clear()
	_check(usage.get_quantity(&"fish_cod") == 0, "InventoryUsage.clear forwards to PlayerInventory")

	var unassigned_usage: Variant = INVENTORY_USAGE_SCRIPT.new()
	_check(not unassigned_usage.add_item(cod), "InventoryUsage.add_item safely rejects a missing inventory")
	_check(not unassigned_usage.try_add(&"fish_cod", 1), "InventoryUsage.try_add safely rejects a missing inventory")
	_check(unassigned_usage.get_quantity(&"fish_cod") == 0, "InventoryUsage.get_quantity returns zero without an inventory")
	_check(not unassigned_usage.try_remove(&"fish_cod", 1), "InventoryUsage.try_remove safely rejects a missing inventory")
	_check(not unassigned_usage.move_item(&"fish_cod", 0), "InventoryUsage.move_item safely rejects a missing inventory")
	unassigned_usage.clear()
	_check(true, "InventoryUsage.clear safely handles a missing inventory")

	print("Inventory tests complete: %d passed, %d failed" % [passed, failures])
	quit(failures)
