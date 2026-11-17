extends Node
var failures: int = 0
var checks: int = 0
var main: Node
var service: InventoryService

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func drag_data(index: int, storage: bool = false) -> Dictionary:
	return {"inventory_drag": true, "index": index, "storage": storage, "revision": service.view_revision, "service_id": service.get_instance_id()}

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	get_tree().create_timer(30.0).timeout.connect(func() -> void: get_tree().quit(1))
	VoyageState.reset()
	var bag := PlayerInventory.new()
	bag.max_inv_space = 3
	check(bag.try_add(&"fish_cod", 23), "Overflow creates three independent stacks")
	check(bag.slots[0].quantity == 10 and bag.slots[1].quantity == 10 and bag.slots[2].quantity == 3, "Stack limits honored")
	check(not bag.try_add(&"fish_cod", 8) and bag.get_quantity(&"fish_cod") == 23, "Failed atomic add preserves all quantities")
	var chest := ShipInventory.new()
	chest.max_inv_space = 1
	chest.add_items(ItemDatabase.get_item(&"fish_cod"), 8)
	check(bag.transfer_to(0, chest) == 2 and bag.slots[0].quantity == 8, "Partial quick-transfer leaves remainder in source")
	check(bag.transfer_to(0, chest) == 0, "Full chest does not destroy items")
	chest.clear()
	chest.add_items(ItemDatabase.get_item(&"rope"), 1)
	check(bag.move_to(0, chest, 0), "Different items swap even between full containers")
	check(bag.slots[0].id == &"rope" and chest.slots[0].quantity == 8, "Swap preserves both stacks")
	bag.remove(1, 10)
	check(bag.slots[1].is_empty() and bag.slots[2].quantity == 3, "Removing a stack leaves a stable empty slot")
	var snapshot := bag.capture()
	bag.slots[2].quantity = 1
	check(snapshot[2].quantity == 3, "Snapshots are isolated")
	bag.restore(snapshot)
	check(bag.slots[2].quantity == 3, "Rollback restores exact slot placement")
	for item in ItemDatabase.get_all_items():
		check(item.icon != null, "Icon exists for %s" % item.id)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	service = main.get_node("Ship/InventorySystem") as InventoryService
	var player := service.player
	var hud := service.hud
	player.position = service.storage_position
	hud.storage_open = true
	await get_tree().process_frame
	check(service.chest_is_nearest(), "Chest can be opened at its position")
	var renderer := service.get_node("DeckItems")
	check(renderer.chest_texture().resource_path.ends_with("ship_chest_open.png"), "Open storage shows the open chest sprite")
	hud.close()
	check(renderer.chest_texture().resource_path.ends_with("ship_chest_closed.png"), "Closing storage restores closed chest sprite")
	hud.storage_open = true
	check(hud.buttons.size() == 4 and service.local_slots.size() == 4, "The four hotbar slots are the entire carried inventory")
	service.storage.clear() # Isolate slot-placement assertions from starter grill fuel.
	service.request("store", 0)
	check(service.inventory.get_quantity(&"fishing_rod") == 0 and service.storage.slots[0].id == &"fishing_rod", "Store starter rod in chest")
	player.call("_grant_starting_inventory")
	check(service.inventory.get_quantity(&"fishing_rod") == 0, "Starter grant cannot duplicate stored rod")
	service.request_drag(drag_data(0, true), 3)
	check(service.local_slots[3].id == &"fishing_rod", "Drag chest stack to exact hotbar slot")
	var stale := drag_data(3)
	service.inventory.try_add(&"rope", 3)
	service.request_drag(stale)
	check(service.drops.is_empty() and service.local_slots[3].id == &"fishing_rod", "Stale drags cannot move changed inventory")
	service.request_drag(drag_data(3))
	check(service.drops.size() == 1 and service.local_slots[3].is_empty(), "Outside drop creates floor item and empties slot")
	service._physics_process(0)
	check(service.drops.size() == 1, "Drop is not immediately picked up by dropper")
	hud.close()
	player.position += Vector2(-60, 0)
	service._physics_process(0)
	player.position = service.storage_position
	service._physics_process(0)
	check(service.drops.is_empty() and service.inventory.get_quantity(&"fishing_rod") == 1, "Leave and re-enter to pick up exactly once")
	service._physics_process(0)
	check(service.inventory.get_quantity(&"fishing_rod") == 1, "Pickup cannot duplicate")
	var carried := service.inventory.capture()
	service.inventory.clear()
	service.inventory.try_add(&"rope", 24)
	service.inventory.try_add(&"fishing_rod", 3)
	check(not service.inventory.try_add(&"coconut"), "A fifth item stack cannot be carried")
	service._spawn_drop({"id": &"rope", "quantity": 4}, player.position)
	player.position += Vector2(-60, 0)
	service._physics_process(0)
	player.position = service.storage_position
	service._physics_process(0)
	check(service.inventory.get_quantity(&"rope") == 25 and service.drops.values()[0].quantity == 3, "Partial pickup preserves the remainder on the floor")
	service.inventory.try_remove(&"rope", 1)
	service._physics_process(0)
	check(service.drops.values()[0].quantity == 3, "Partial pickup waits for a fresh radius entry")
	player.position += Vector2(-60, 0)
	service._physics_process(0)
	player.position = service.storage_position
	service._physics_process(0)
	check(service.drops.values()[0].quantity == 2, "Re-entering retries only available space")
	service.inventory.restore(carried)
	service.drops.clear()
	service.pickup_inside.clear()
	hud.storage_open = true
	service.inventory.move_item(&"fishing_rod", 3)
	service.request_drag(drag_data(3), 2, true)
	service.request_drag(drag_data(0))
	check(service.drops.size() == 1, "Rope dropped for persistence test")
	var saved_floor := service.drops.duplicate(true)
	var saved_chest := service.storage
	var ship := main.get_node("Ship") as Node2D
	ship.position += Vector2(150, -70)
	ship.rotation = 0.7
	check(service.drops == saved_floor, "Deck drops retain ship-local coordinates through motion")
	main.queue_free()
	await get_tree().process_frame
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	service = main.get_node("Ship/InventorySystem")
	check(service.storage == saved_chest and service.storage.slots[2].id == &"fishing_rod", "Chest survives scene replacement")
	check(service.drops == saved_floor and service.inventory.get_quantity(&"fishing_rod") == 0, "Floor items survive and rod does not respawn")
	service.player.position = service.storage_position + Vector2(100, 0)
	service.hud.storage_open = true
	service.request_drag(drag_data(2, true), 3)
	check(service.storage.slots[2].id == &"fishing_rod", "Out-of-range chest drag rejected")
	service.player.position = service.storage_position
	service.player.set("is_overboard", true)
	service.request_drag(drag_data(2, true), 3)
	check(service.storage.slots[2].id == &"fishing_rod", "Swimmer cannot access chest")
	service.player.set("is_overboard", false)
	main.queue_free()
	await get_tree().process_frame
	var island: Node = load("res://scenes/island.tscn").instantiate()
	add_child(island)
	await get_tree().process_frame
	service = island.get_node("InventorySystem")
	check(not service.chest_enabled and service.hud.buttons.size() == 4, "Island shares inventory UI without remote chest access")
	var original := service.inventory.capture()
	service.inventory.try_add(&"coconut", 2)
	service.request_drag(drag_data(0))
	island.call("_take_back_prizes")
	check(service.inventory.capture() == original, "Island failure restores carried inventory")
	check(VoyageState.floor_items[island.scene_file_path].is_empty(), "Island failure removes dropped prizes")
	island.queue_free()
	await get_tree().process_frame
	VoyageState.reset()
	check(VoyageState.floor_items.is_empty() and VoyageState.ship_storage == null, "New voyage clears chest and floor items")
	print("INVENTORY INTEGRATION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
