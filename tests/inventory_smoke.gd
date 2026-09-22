extends Node
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var inventory := ShipInventory.new(4)
	check(inventory.add(&"water", 23) == 3, "Capacity must reject overflow")
	check(inventory.slots.size() == 4, "Four starting slots")
	for entry in inventory.slots:
		check(entry.quantity == 5, "Stack limit enforced")
	var target := ShipInventory.new(1)
	target.add(&"water", 4)
	check(inventory.transfer_to(0, target) == 1, "Partial transfer only moves available space")
	check(inventory.slots[0].quantity == 4 and target.slots[0].quantity == 5, "No loss on partial transfer")
	check(inventory.add(&"unknown", 1) == 1, "Unknown item rejected")
	var snapshot := inventory.capture()
	snapshot[0].quantity = 99
	check(inventory.slots[0].quantity == 4, "Snapshots must not share mutable entries")
	var tools := ShipInventory.new(4)
	check(tools.add(&"shovel", 5) == 1, "Tools each take one slot")
	tools.add_capacity(2)
	check(tools.slots.size() == 6 and tools.slots[0].id == &"shovel", "Bag extension preserves existing items")
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_offline()
	var service: Node = main.get_node("InventorySystem")
	var hud: Node = main.get_node("InventoryHUD")
	check(service.local_slots.size() == 4, "Offline player receives inventory")
	main.players[1].position = service.storage_position
	service.request("take", 0)
	check(service.local_slots[0].id == &"fish_cod", "Take from chest")
	service.last_request.clear()
	service.request("drop", 0)
	check(service.local_slots[0].is_empty() and service.drops.size() == 1, "Drop removes carried stack")
	var drop_position: Vector2 = service.drops[1].position
	main.ship.position += Vector2(500, 200)
	main.ship.rotation = 0.6
	check(service.drops[1].position == drop_position, "Drops retain deck-local coordinates")
	service.last_request.clear()
	service.request("pickup", 1)
	check(service.drops.is_empty() and service.local_slots[0].quantity == 8, "Pickup restores stack exactly once")
	service.last_request.clear()
	service.request("pickup", 1)
	check(service.local_slots[0].quantity == 8, "Repeated pickup cannot duplicate")
	main.players[1].position = Vector2(-70, -90)
	service.last_request.clear()
	service.request("store", 0)
	check(service.local_slots[0].quantity == 8, "Reject distant storage access")
	main.players[1].position = service.storage_position
	service.last_request.clear()
	service._execute(1, "store", 0, service.revision - 1)
	check(service.local_slots[0].quantity == 8, "Reject stale action")
	service.last_request.clear()
	service.request("store", 0)
	check(service.local_slots[0].is_empty(), "Store into chest")
	main._add_player(2, 1)
	service.crew[2].add(&"rope", 3)
	main._remove_player(2)
	check(service.drops.size() == 1, "Disconnect leaves carried items aboard")
	main.end_session("Test reset")
	main.start_offline()
	check(service.drops.is_empty() and service.local_slots[0].is_empty(), "New session clears old inventory")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_4
	hud._unhandled_input(key)
	check(hud.selected == 3, "Number key selects fourth slot")
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	hud._unhandled_input(wheel)
	check(hud.selected == 0, "Wheel wraps to first slot")
	main.players[1].position = service.storage_position
	key.physical_keycode = KEY_F
	hud._unhandled_input(key)
	check(hud.storage_open, "F opens nearby storage")
	key.physical_keycode = KEY_ESCAPE
	hud._unhandled_input(key)
	check(not hud.storage_open, "Escape closes storage")
	if "--capture" in OS.get_cmdline_user_args():
		main.players[1].position = service.storage_position
		for index in [0, 1, 3, 5]:
			service.last_request.clear()
			service.request("take", index)
		hud.storage_open = true
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/inventory-preview.png")
	print("INVENTORY SMOKE: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	get_tree().quit(failures)
