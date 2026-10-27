extends SceneTree
## Islands are solid: the ship must never sail over land.
## Run with: godot --headless --path . --script res://tests/island_collision.gd

var failures: int = 0
var current_test: String = ""
var overlap_frames: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("[%s] %s" % [current_test, message])


func _hull_on_land(ship: Ship) -> bool:
	var hull := ship.get_hull_polygon(ship.global_position, ship.global_rotation)
	for island in ship.get_islands():
		if not Geometry2D.intersect_polygons(hull, island.get_coast()).is_empty():
			return true
	return false


## Runs physics for a while, counting frames where the hull is on land.
func _sail(ship: Ship, seconds: float) -> void:
	var frames := int(seconds * 60.0 / Engine.time_scale)
	for i in frames:
		await physics_frame
		if _hull_on_land(ship):
			overlap_frames += 1


func _fresh_ship() -> Ship:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	await physics_frame
	var ship := current_scene.get_node("Ship") as Ship
	ship.changing_wind_enabled = false
	return ship


## Puts the ship at `offset` from the island centre, pointing along `heading`,
## with full sail and the wind behind it.
func _launch(ship: Ship, island: WorldIsland, offset: Vector2, heading: Vector2) -> void:
	ship._leaving_island = null
	ship.global_position = island.global_position + offset
	ship.global_rotation = Vector2.UP.angle_to(heading)
	ship.wind_velocity = heading
	ship.set_sail_angle(0.0)
	ship.set_sail_level(3)
	ship.set_wheel_angle(0.0)
	ship.speed = ship.maximum_speed
	ship.turn_rate = 0.0


func _run() -> void:
	Engine.time_scale = 4.0
	create_timer(400.0).timeout.connect(func() -> void:
		push_error("Collision test timed out")
		quit(1))

	var ship := await _fresh_ship()
	var names: Array[StringName] = []
	for island in ship.get_islands():
		names.append(island.name)
	_check(not ship.hull_outline.is_empty(), "The ship needs a hull outline")
	for island in ship.get_islands():
		_check(island.get_coast().size() >= 3, "%s needs a coastline" % island.name)
		# The anchored pose must be clear of land, or docking would overlap it.
		_check(not ship._is_pose_blocked(island.get_dock_position(), island.global_rotation),
				"%s's anchoring spot must be clear of land" % island.name)

	# 1. Sail straight at the far side of every island (away from its dock):
	#    the ship must stop at the shore, not sail over, and not dock.
	for name in names:
		current_test = "far side of %s" % name
		ship = await _fresh_ship()
		var island := ship.get_island(name)
		overlap_frames = 0
		_launch(ship, island, Vector2(700, 0), Vector2.LEFT)
		await _sail(ship, 6.0)
		_check(overlap_frames == 0, "Hull overlapped land on %d frames" % overlap_frames)
		_check(ship._state == Ship.State.SAILING, "Hitting the far side must not dock")
		_check(ship.aground, "The ship must be pressed against the shore")
		_check(ship.status_label.visible and ship.status_label.text.begins_with("Ran aground"), "A 'Ran aground' line must show")
		_check(ship.global_position.x > island.global_position.x + 200, "The ship must stop at the east shore")

	# 2. Get away after running aground, with the wind still blowing onto the
	#    shore: turn the wheel toward open water and trim the sail.
	current_test = "steer away"
	var stuck_at := ship.global_position
	ship.set_wheel_angle(ship.maximum_wheel_turns * 360.0)
	overlap_frames = 0
	await _sail(ship, 6.0)
	ship.set_wheel_angle(0.0)
	ship.set_sail_angle(-60.0)
	await _sail(ship, 15.0)
	_check(overlap_frames == 0, "Hull overlapped land on %d frames while turning away" % overlap_frames)
	_check(not ship.aground, "Turning must free the ship")
	_check(ship.global_position.distance_to(stuck_at) > 150, "The ship must be able to sail off (moved %.0f px)" % ship.global_position.distance_to(stuck_at))

	# 3. Glancing blow: scrape along the shore instead of stopping dead.
	current_test = "scrape"
	ship = await _fresh_ship()
	var skull := ship.get_island(&"SkullRock")
	_launch(ship, skull, Vector2(560, -500), Vector2(-0.55, 1).normalized())
	overlap_frames = 0
	var aground_frames := 0
	var moved_while_aground := 0.0
	for i in int(8.0 * 60.0 / Engine.time_scale):
		var before := ship.global_position
		await physics_frame
		if _hull_on_land(ship):
			overlap_frames += 1
		if ship.aground:
			aground_frames += 1
			moved_while_aground += before.distance_to(ship.global_position)
	_check(overlap_frames == 0, "Hull overlapped land on %d frames" % overlap_frames)
	_check(aground_frames > 0, "The glancing course must touch the shore")
	_check(moved_while_aground > 20.0, "The ship must scrape along the shore (moved %.0f px)" % moved_while_aground)

	# 4. Bow-first at the dock side of every island: sailing in never docks by
	# itself, and lowering the anchor at the shore anchors there without the
	# hull ever touching land.
	for name in names:
		current_test = "dock side of %s" % name
		ship = await _fresh_ship()
		var island := ship.get_island(name)
		overlap_frames = 0
		_launch(ship, island, island.dock_offset + Vector2(-500, 0), Vector2.RIGHT)
		for i in int(10.0 * 60.0 / Engine.time_scale):
			await physics_frame
			if _hull_on_land(ship):
				overlap_frames += 1
			if ship.aground or ship.global_position.distance_to(island.get_dock_position()) < 30.0:
				break
		_check(ship._state == Ship.State.SAILING, "Reaching the shore must not anchor on its own")
		ship.anchor_deployed = true
		_check(ship._state == Ship.State.ANCHORED and ship._docked_island == island, "Lowering the anchor at the shore must anchor there")
		for i in int(4.0 * 60.0 / Engine.time_scale):
			await physics_frame
			if _hull_on_land(ship):
				overlap_frames += 1
		_check(ship.speed == 0, "The anchor must stop the ship")
		_check(overlap_frames == 0, "Hull overlapped land on %d frames" % overlap_frames)

	# 5. The rowboat rows around each island to its dock without crossing land
	# or the ship, even when the ship anchors on the far side.
	for name in names:
		current_test = "rowing route around %s" % name
		ship = await _fresh_ship()
		var island := ship.get_island(name)
		var landing := Transform2D(island.global_rotation, island.get_dock_position()) * Ship.DOCK_LANDING
		var away := (island.global_position - landing).normalized()
		var spot := island.global_position
		while ship._is_pose_blocked(spot, 0.0) or Geometry2D.is_point_in_polygon(spot, island.get_coast()):
			spot += away * 20.0
		ship.global_position = spot + away * 60.0
		ship.global_rotation = 0.0
		var route: Array[Vector2] = []
		for point in ship._rowing_route(island):
			route.append(ship.to_global(point))
		var hull := ship.get_hull_polygon(ship.global_position, ship.global_rotation)
		_check(route.size() > 3 and route[route.size() - 1].is_equal_approx(landing), "The route must go around the island and end at the dock")
		for i in route.size() - 1:
			var leg := PackedVector2Array([route[i], route[i + 1]])
			_check(Geometry2D.intersect_polyline_with_polygon(leg, hull).is_empty(), "Rowing leg %d must not cross the ship" % i)
			if i < route.size() - 2:
				_check(Geometry2D.intersect_polyline_with_polygon(leg, island.get_coast()).is_empty(), "Rowing leg %d must stay off the land" % i)

	print("Island collision: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
