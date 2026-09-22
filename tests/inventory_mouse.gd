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
	service.last_request.clear()
	motion(source, Vector2.ZERO, false)
	mouse_button(source, true)
	await get_tree().process_frame
	motion(source + Vector2(20, 0), Vector2(20, 0), true)
	await get_tree().process_frame
	check(get_viewport().gui_is_dragging(), "Mouse motion starts native drag")
	motion(destination, destination - source, true)
	await get_tree().process_frame
	mouse_button(destination, false)
	await get_tree().process_frame

func run() -> void:
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_offline()
	service = main.get_node("InventorySystem")
	hud = main.get_node("InventoryHUD")
	main.players[1].position = service.storage_position
	hud.handle_interact()
	await get_tree().process_frame
	await get_tree().process_frame
	var source: Vector2 = hud.chest_buttons[0].get_global_rect().get_center()
	var target: Vector2 = hud.buttons[2].get_global_rect().get_center()
	await drag(source, target)
	check(not service.local_slots[2].is_empty() and service.local_slots[2].get("id") == &"fish_cod", "Mouse drag places chest item in third slot")
	await drag(target, Vector2(300, 300))
	check(service.local_slots[2].is_empty() and service.drops.size() == 1, "Mouse drag outside drops to deck")
	service.last_request.clear()
	source = hud.chest_buttons[1].get_global_rect().get_center()
	motion(source, Vector2.ZERO, false)
	mouse_button(source, true, true)
	mouse_button(source, false, true)
	await get_tree().process_frame
	check(service.local_slots[0].get("id") == &"water", "Shift-click quick transfers to available pocket")
	# Releasing over chest padding must cancel, never discard the stack.
	await drag(hud.buttons[0].get_global_rect().get_center(), hud.chest_panel.get_global_rect().position + Vector2(8, 8))
	check(service.local_slots[0].get("id") == &"water" and service.drops.size() == 1, "Panel padding cancels drop")
	print("INVENTORY MOUSE: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	get_tree().quit(failures)
