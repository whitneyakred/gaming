extends SceneTree
## Current continuous shoreline travel; scene transitions belong to explicit challenges.
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ship = main.get_node("Ship")
	var crew = ship.player
	var access = ship.get_node("SwimAccess")
	ship.set_physics_process(false)
	crew.set_physics_process(false)
	access.set_physics_process(false)
	crew.position = access.plank_end
	access.update_crew(crew)
	_check(crew.is_overboard and crew.access_motion == &"jump", "Plank begins water traversal")
	access._advance_access(crew, 2.0)
	_check(crew.access_motion == &"" and crew.is_overboard, "Traversal finishes in water")
	_check(crew.swim_speed < crew.walk_speed, "Swimming is slower")
	_check(not crew.try_use_station(ship.get_node("Sail")), "Swimming blocks station claims")
	var world: Vector2 = crew.global_position
	ship.global_position += Vector2(0, 30)
	_check(crew.global_position.is_equal_approx(world), "Ship movement does not tow a swimmer")
	crew.global_position = ship.to_global(access.ladder_water)
	access.update_crew(crew)
	_check(crew.is_overboard and crew.access_motion == &"align", "Ladder does not board instantly")
	access._advance_access(crew, 2.0)
	_check(not crew.is_overboard and crew.position == access.ladder_top, "Ladder finishes on deck")
	_check(crew.collision_mask != 0, "Boarding restores collisions")
	crew.set_overboard(true)
	var island = ship.get_islands()[0]
	crew.global_position = island.global_position
	access.update_crew(crew)
	_check(crew.on_land and crew.access_motion == &"", "Walking ashore stays in the voyage")
	_check(is_instance_valid(main) and is_instance_valid(ship), "Shoreline does not replace the scene")
	print("Swimming integration: %d failure(s)" % failures)
	quit(1 if failures else 0)
