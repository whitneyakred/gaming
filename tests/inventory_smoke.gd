extends Node
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func reenter(main: Node, service: Node) -> void:
	var position: Vector2 = main.players[1].position
	main.players[1].position += Vector2(1000, 0)
	service.collect_nearby(0.1)
	main.players[1].position = position
	service.collect_nearby(0.1)

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
	service.collect_nearby(0.1)
	check(service.drops.size() == 1, "Spawning inside does not trigger pickup")
	service.collect_nearby(100.0)
	check(service.drops.size() == 1, "Waiting indefinitely inside never reabsorbs a drop")
	var drop_position: Vector2 = service.drops[1].position
	main.ship.position += Vector2(500, 200)
	main.ship.rotation = 0.6
	check(service.drops[1].position == drop_position, "Drops retain deck-local coordinates")
	service.last_request.clear()
	reenter(main, service)
	check(service.drops.is_empty() and service.local_slots[0].quantity == 8, "Pickup restores stack exactly once")
	service.last_request.clear()
	reenter(main, service)
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
	key.physical_keycode = KEY_E
	main._unhandled_input(key)
	check(hud.storage_open and not main.pending_interact, "E opens chest without activating a station")
	key.physical_keycode = KEY_SPACE
	main._unhandled_input(key)
	check(not hud.storage_open, "Space closes chest")
	main._unhandled_input(key)
	check(hud.storage_open, "Space opens chest")
	key.physical_keycode = KEY_ESCAPE
	hud._unhandled_input(key)
	check(not hud.storage_open, "Escape closes storage")
	service.last_request.clear()
	service.request_drag({"index": 0, "storage": true, "revision": service.view_revision}, 3, false)
	check(service.local_slots[3].id == &"fish_cod" and service.local_slots[0].is_empty(), "Drag targets exact pocket")
	service.last_request.clear()
	service.request_drag({"index": 1, "storage": true, "revision": service.view_revision}, 3, false)
	check(service.local_slots[3].id == &"water" and service.storage_view[1].id == &"fish_cod", "Unlike stacks swap")
	service.last_request.clear()
	var stale_drag := {"index": 3, "storage": false, "revision": service.view_revision - 1}
	service.request_drag(stale_drag)
	check(service.local_slots[3].id == &"water" and service.drops.is_empty(), "Stale drag cannot drop replacement item")
	service.last_request.clear()
	service.request_drag({"index": 3, "storage": false, "revision": service.view_revision})
	check(service.local_slots[3].is_empty() and service.drops.size() == 1, "Dragging outside drops stack")
	var merging := ShipInventory.new(3)
	merging.slots[0] = {"id": &"water", "quantity": 4}
	merging.slots[1] = {"id": &"water", "quantity": 3}
	check(merging.move_to(1, merging, 0), "Matching stacks merge")
	check(merging.slots[0].quantity == 5 and merging.slots[1].quantity == 2, "Merge leaves remainder in source")
	check(not merging.move_to(1, merging, 0), "Full destination does not discard source")
	check(not merging.move_to(-1, merging, 0), "Invalid drag slot rejected")
	main.end_session("Reset after drag tests")
	main.start_offline()
	main.players[1].position = Vector2.ZERO
	service.crew[1].add(&"shovel", 4)
	service._spawn_drop({"id": &"water", "quantity": 8}, Vector2.ZERO)
	reenter(main, service)
	check(service.drops.size() == 1 and service.drops[1].quantity == 8, "Full pockets leave ground items untouched")
	service.crew[1].remove(0, 1)
	service.collect_nearby(0.1)
	check(service.crew[1].slots[0].is_empty(), "Making room inside trigger still requires a new entry")
	reenter(main, service)
	check(service.local_slots[0].quantity == 5 and service.drops[1].quantity == 3, "Freeing one slot collects only what fits")
	service.crew[1].remove(0, 2)
	reenter(main, service)
	check(service.local_slots[0].quantity == 5 and service.drops[1].quantity == 1, "Matching stack room also counts as capacity")
	main.players[1].position = Vector2(100, 0)
	service.crew[1].remove(1, 1)
	service.collect_nearby(0.1)
	check(service.drops.size() == 1, "Distant player cannot collect items")
	main.players[1].position = Vector2.ZERO
	main._add_player(2, 1)
	main.players[2].position = Vector2.ZERO
	service.collect_nearby(0.1)
	check(service.drops.is_empty() and service.crew[1].slots[1].quantity == 1 and service.crew[2].slots[0].is_empty(), "Competing players cannot duplicate pickup")
	main.end_session("Reset after proximity tests")
	main.start_offline()
	main._add_player(2, 1)
	for angle in [PI / 2, PI, -PI / 2]:
		main.ship.rotation = angle
		for id: int in main.players:
			var sprite: Node2D = main.players[id].get_node("Sprite2D")
			sprite._process(0.0)
			check(absf(wrapf(sprite.get_global_transform_with_canvas().get_rotation(), -PI, PI)) < 0.001, "All player art remains screen-upright")
			check(sprite.global_position.distance_to(main.players[id].global_position + Vector2(0, -18)) < 0.01, "Art stays above feet as boat rotates")
		var artwork: Node2D = main.ship.get_node("DeckItems")
		check(absf(wrapf(artwork.get_global_transform_with_canvas().get_rotation() + UprightVisual.draw_rotation(artwork), -PI, PI)) < 0.001, "Ground item drawing counteracts ship rotation")
	main.end_session("Reset after visual tests")
	main.start_offline()
	if "--capture" in OS.get_cmdline_user_args():
		main.players[1].position = service.storage_position
		for index in [0, 1, 3, 5]:
			service.last_request.clear()
			service.request("take", index)
		hud.storage_open = true
		if "--capture-turn" in OS.get_cmdline_user_args():
			main.ship.rotation = 0.8
			service.last_request.clear()
			service.request("drop", 0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/inventory-preview.png")
	print("INVENTORY SMOKE: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	get_tree().quit(failures)
