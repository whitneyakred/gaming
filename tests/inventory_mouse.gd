extends Node
var failures: int = 0
var main: Node
var hud: Node
var service: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func mouse_button(point: Vector2, down: bool, shift: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	event.shift_pressed = shift
	get_viewport().push_input(event)

func motion(point: Vector2, relative: Vector2, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	get_viewport().push_input(event)

func drag(source: Vector2, destination: Vector2) -> void:
	motion(source, Vector2.ZERO, false)
	mouse_button(source, true)
	mouse_button(source, false)
	await get_tree().process_frame
	check(not hud.cursor_data.is_empty(), "Left-click starts persistent cursor carry")
	motion(destination, destination-source, false)
	await get_tree().process_frame
	mouse_button(destination, true)
	mouse_button(destination, false)
	await get_tree().process_frame
func run() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	VoyageState.reset()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	service = main.get_node("Ship/InventorySystem")
	hud = service.hud
	service.player.position = service.storage_position
	await get_tree().process_frame
	var interact := InputEventAction.new()
	interact.action = &"interact"
	interact.pressed = true
	get_viewport().push_input(interact)
	check(hud.storage_open, "E interaction opens the chest without claiming a station")
	await get_tree().process_frame
	service.inventory.clear()
	service.storage.clear() # Slot assertions use an empty chest, not starter fuel.
	service.storage.add_items(ItemDatabase.get_item(&"fish_cod"), 8)
	service.storage.add_items(ItemDatabase.get_item(&"fresh_water"), 5)
	await get_tree().process_frame
	await get_tree().process_frame
	var source: Vector2 = hud.chest_buttons[0].get_global_rect().get_center()
	var target: Vector2 = hud.buttons[2].get_global_rect().get_center()
	await drag(source, target)
	check(not service.local_slots[2].is_empty() and service.local_slots[2].get("id") == &"fish_cod", "Mouse drag places chest item in third slot")
	await drag(target, Vector2(100, 100))
	check(service.local_slots[2].is_empty() and service.drops.size() == 1, "Mouse drag outside drops to deck")
	source = hud.chest_buttons[1].get_global_rect().get_center()
	motion(source, Vector2.ZERO, false)
	mouse_button(source, true, true)
	mouse_button(source, false, true)
	await get_tree().process_frame
	check(service.local_slots[0].get("id") == &"fresh_water", "Shift-click quick transfers to available pocket")
	# Releasing over chest padding must cancel, never discard the stack.
	await drag(hud.buttons[0].get_global_rect().get_center(), hud.chest_panel.get_global_rect().position + Vector2(8, 8))
	check(service.local_slots[0].get("id") == &"fresh_water" and service.drops.size() == 1, "Panel padding cancels drop")
	var deck := service.get_node("DeckItems")
	check(deck.chest_texture().resource_path.ends_with("ship_chest_open.png"), "Chest sprite is open during storage interaction")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	get_viewport().push_input(cancel)
	check(not hud.storage_open and deck.chest_texture().resource_path.ends_with("ship_chest_closed.png"), "Escape closes storage and its chest sprite")
	get_viewport().push_input(interact)
	service.player.position += Vector2(100, 0)
	await get_tree().process_frame
	await get_tree().process_frame
	check(not hud.storage_open and deck.chest_texture().resource_path.ends_with("ship_chest_closed.png"), "Leaving interaction range closes the chest")
	service.player.position = service.storage_position
	get_viewport().push_input(interact)
	print("INVENTORY MOUSE: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	if "--capture" in OS.get_cmdline_user_args():
		service.inventory.try_add(&"fishing_rod")
		service.inventory.try_add(&"rope", 12)
		service.inventory.try_add(&"coconut", 5)
		for item in ItemDatabase.get_all_items():
			service.storage.add_items(item, 1)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/four-slot-chest-open.png")
		hud.close()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/four-slot-chest-closed.png")
	get_tree().quit(failures)
