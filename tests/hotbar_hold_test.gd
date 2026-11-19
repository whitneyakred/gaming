extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event)
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var service = main.get_node("Ship/InventorySystem")
	var hud = service.hud
	service.inventory.clear()
	service.inventory.try_add(&"wood", 4)
	await process_frame
	var button = hud.buttons[0]
	check(is_equal_approx(button.pickup_hold_seconds, 0.15), "Default hold is 0.15 seconds")
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion)
	hud.selected = 2
	mouse(point, true)
	mouse(point, false)
	await create_timer(0.35).timeout
	check(hud.selected == 0 and hud.cursor_data.is_empty(), "Tap equips without carrying, even after delay")
	mouse(point, true)
	await create_timer(0.20).timeout
	check(not hud.cursor_data.is_empty(), "Hold picks up stack")
	mouse(point, false)
	check(not hud.cursor_data.is_empty(), "Release keeps stack on cursor")
	hud.cancel_cursor()
	mouse(point, true)
	motion.position = Vector2(20, 20)
	root.push_input(motion)
	await create_timer(0.35).timeout
	check(hud.cursor_data.is_empty(), "Leaving slot cancels hold")
	mouse(point, false)
	for panel in ["storage_open", "grill_open"]:
		hud.set(panel, true)
		mouse(point, true)
		check(not hud.cursor_data.is_empty(), "Open panel picks up immediately: " + panel)
		mouse(point, false)
		hud.cancel_cursor()
		hud.set(panel, false)
	var player = service.player
	var ship = main.get_node("Ship")
	for angle in [0.0, PI / 2.0]:
		ship.global_rotation = angle
		var boundary: PackedVector2Array = ship.get_swimming_hull_polygon()
		check(not Geometry2D.is_point_in_polygon(ship.to_global(Vector2(2, -260)), boundary), "Raised bow spar allows swimming underneath")
		check(Geometry2D.is_point_in_polygon(ship.to_global(Vector2(2, 220)), boundary), "Stern keeps swimmer head outside artwork")
		check(Geometry2D.is_point_in_polygon(ship.to_global(Vector2(0, -200)), boundary), "Solid bow remains blocked")
	ship.global_rotation = 0.0
	player._process(0)
	check(player.z_index > 0, "Deck crew renders above props")
	player.set_overboard(true)
	player._process(0)
	check(player.z_index < 0 and player.z_index > -20, "Swimmer renders between sea and ship")
	player.update_land(true)
	player._process(0)
	check(player.z_index > 0, "Shore restores foreground layer")
	player.set_overboard(false)
	player._process(0)
	check(player.z_index > 0, "Boarding restores foreground layer")
	print("HOTBAR HOLD / DRAW ORDER: ", failures, " failures")
	quit(failures)

