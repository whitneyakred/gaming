extends SceneTree
## Run with Godot --headless --path . --script res://tests/shared_chest_test.gd

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, name: String) -> void:
	checks += 1
	if condition:
		print("PASS: %s" % name)
	else:
		failures += 1
		push_error("Shared chest test failed: %s" % name)


func _run() -> void:
	var voyage_state := root.get_node_or_null("VoyageState")
	var item_database := root.get_node_or_null("ItemDatabase")
	_check(voyage_state != null and item_database != null, "Required autoloads are available")
	if voyage_state == null or item_database == null:
		quit(1)
		return
	voyage_state.clear_voyage()
	var chest := voyage_state.get_shared_inventory(&"test_shared_chest", 12) as PlayerInventory
	var same_chest := voyage_state.get_shared_inventory(&"test_shared_chest", 6) as PlayerInventory
	_check(chest != null and chest.max_inv_space == 12, "Chest receives configured 12-slot capacity")
	_check(chest == same_chest, "Chest ID resolves to one shared inventory instance")
	var cod := item_database.get_item(&"fish_cod") as ItemData
	var rope := item_database.get_item(&"rope") as ItemData
	_check(cod != null and rope != null, "Catalog provides transfer test items")
	if cod != null and rope != null:
		var player_inventory := PlayerInventory.new()
		player_inventory.max_inv_space = 1
		_check(player_inventory.add_item(cod), "Player inventory accepts source item")
		_check(chest.try_add(cod.id, 1), "Chest accepts matching stack")
		_check(player_inventory.try_remove(cod.id, 1), "Source removes after destination accepts item")
		_check(chest.get_quantity(cod.id) == 1 and player_inventory.get_quantity(cod.id) == 0, "Transfer updates both inventories")
		_check(player_inventory.add_item(rope), "Player inventory fills its only distinct slot")
		_check(not player_inventory.try_add(cod.id, 1), "Full player rejects a distinct chest item")
		_check(chest.get_quantity(cod.id) == 1, "Rejected destination add leaves chest unchanged")
	voyage_state.clear_voyage()
	_check(voyage_state.get_shared_inventory(&"test_shared_chest", 12).inventory.is_empty(), "New voyage clears shared chest contents")
	var ui_scene := load("res://scenes/ui/chest_inventory.tscn") as PackedScene
	var ui := ui_scene.instantiate() as Control if ui_scene != null else null
	_check(ui != null, "Chest inventory UI scene loads")
	if ui != null:
		root.add_child(ui)
		await process_frame
		var ui_player_inventory := PlayerInventory.new()
		ui_player_inventory.add_item(cod)
		var ui_chest_inventory: PlayerInventory = voyage_state.get_shared_inventory(&"test_shared_chest", 12)
		ui.call(&"open_for", ui_player_inventory, ui_chest_inventory)
		_check(ui.visible, "Chest inventory UI opens with two inventories")
		ui.call(&"_transfer_slot", true, 0)
		_check(ui_player_inventory.get_quantity(cod.id) == 0 and ui_chest_inventory.get_quantity(cod.id) == 1, "Chest UI transfers an item between inventories")
		ui.call(&"close")
		_check(not ui.visible, "Chest inventory UI closes")
		ui.queue_free()
	print("Shared chest test: %d check(s), %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
