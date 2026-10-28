extends SceneTree
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var state := root.get_node("VoyageState")
	state.reset()
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
	ship.set_physics_process(false)
	var repairs := ship.get_node("ShipRepairs")
	var wreckage := ship.get_node("FloatingWreckage")
	repairs.set_physics_process(false)
	wreckage.set_physics_process(false)
	wreckage._physics_process(0)
	check(not wreckage.planks.is_empty(), "Water should contain visible salvage")
	var cell: Vector2i = wreckage.planks.keys()[0]
	var point: Vector2 = wreckage.planks[cell]
	ship.player.global_position = point
	wreckage._physics_process(0)
	check(state.salvaged_wood == 0, "Deck players cannot collect water salvage")
	ship.player.set_overboard(true)
	ship.player.global_position = point
	wreckage._physics_process(0)
	wreckage._physics_process(0)
	check(state.salvaged_wood == 1 and not wreckage.planks.has(cell), "Swimming collects each plank only once")
	check(wreckage.plank_position(cell) == point, "Cell positions must be deterministic")
	state.next_hole_seconds = 0
	repairs._physics_process(0.1)
	check(state.ship_holes.size() == 1, "Timer should open a hole")
	check(state.next_hole_seconds >= 35 and state.next_hole_seconds <= 60, "Damage interval must stay bounded")
	for i in 10:
		repairs.open_hole()
	check(state.ship_holes.size() == 3, "Holes must be capped")
	var slot: int = state.ship_holes[0]
	ship.player.global_position = ship.to_global(repairs.hole_positions[slot])
	check(not repairs.repair_nearest(), "Cannot repair from water")
	ship.player.set_overboard(false)
	ship.player.position = repairs.hole_positions[slot]
	ship.player.try_use_station(ship.get_node("Helm"))
	check(not repairs.repair_nearest(), "Cannot repair while operating a station")
	ship.player.leave_station(ship.get_node("Helm"))
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	check(state.ship_holes.size() == 2, "Interact should repair the nearby hole")
	check(state.salvaged_wood == 1, "Unlimited repairs must not spend collected wood")
	ship.player.position = Vector2(500, 500)
	check(not repairs.repair_nearest(), "Cannot repair a distant hole")
	reload_current_scene()
	await scene_changed
	check(state.ship_holes.size() == 2 and state.salvaged_wood == 1 and state.collected_wreckage.has(cell), "Damage and pickups must survive scene replacement")
	state.reset()
	check(state.ship_holes.is_empty() and state.collected_wreckage.is_empty() and state.salvaged_wood == 0, "New voyage clears damage and salvage")
	print("Wreckage / repairs: %d failures" % failures)
	quit(1 if failures else 0)
