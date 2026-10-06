extends SceneTree
## Run with Godot --headless --path . --script res://tests/sailing_integration.gd

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await physics_frame
	await process_frame
	event = InputEventAction.new()
	event.action = action
	Input.parse_input_event(event)
	await physics_frame

func _run() -> void:
	Engine.time_scale = 8.0
	create_timer(240.0).timeout.connect(func() -> void:
		push_error("Integration test timed out")
		quit(1))
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
	var player := ship.player
	var sail := ship.get_node("Sail") as SailStation
	var helm := ship.get_node("Helm") as HelmStation
	var cooking = ship.get_node("Cooking")
	var initial_position := ship.global_position
	await _wait(7.0)
	_check(ship.global_position.is_equal_approx(initial_position), "Stowed sails must not automatically move the ship")
	_check(ship.get_islands().size() == 2, "Both islands must be placed on the map")
	_check(ship.status_label.text.begins_with("Nearest island:"), "The status line must name the nearest island")
	_check(get_first_node_in_group("crew") == player, "Main must keep the cooking-compatible player")
	ship.wind_velocity = Vector2.UP
	player.position = Vector2(-20, 0)
	await _wait(0.2)
	await _press("interact")
	_check(player.active_station == sail, "E must enter the sail station")
	for level in range(1, 4):
		await _press("move_up")
		_check(ship.sail_level == level, "Each W press must advance exactly one sail level")
	Input.action_press("move_right")
	await _wait(0.3)
	Input.action_release("move_right")
	_check(ship.sail_angle_degrees > 0, "Sail trim must respond to input")
	if not cooking.crew_nearby.has(player):
		cooking.crew_nearby.append(player)
	cooking.interact()
	_check(cooking.state == cooking.State.IDLE, "Cooking cannot claim a player using the sail")
	await _press("interact")
	_check(not player.using_station, "E must release the sail station")
	cooking.interact()
	_check(player.active_station == cooking, "Cooking must claim the shared station lock")
	_check(not sail.try_take_control(player), "Sailing must not steal control from cooking")
	cooking._on_preparation_cancelled()
	await process_frame
	_check(not player.using_station and cooking.raw_fish == 3, "Cancelling cooking must release movement and preserve stock")
	cooking.interact()
	cooking._on_preparation_completed(2)
	await process_frame
	_check(cooking.state == cooking.State.READY and cooking.raw_fish == 2, "Cooking completion must preserve the meal flow")
	cooking.interact()
	_check(cooking.cooked_fish == 1 and not player.using_station, "Meal collection must still work")
	# Remove the synthetic overlapping reach used to exercise exclusive ownership.
	cooking.crew_nearby.erase(player)
	player.position = helm.position
	await _wait(0.2)
	await _press("interact")
	_check(player.active_station == helm, "E must enter the helm")
	Input.action_press("move_right")
	await _wait(0.5)
	Input.action_release("move_right")
	_check(ship.wheel_angle_degrees > 0 and ship.global_rotation > 0, "Helm input must turn the moving ship")
	_check(ship.get_node("SailingDemo/HUD/HelmWheel").visible, "Wheel indicator must appear at the helm")
	await _press("interact")
	ship.set_wheel_angle(0)
	ship.turn_rate = 0
	ship.global_rotation = 0
	ship.set_sail_angle(0)
	# Put the ship just south of Coconut Island's docking circle and let it sail in.
	var coconut_island := ship.get_island(&"CoconutIsland")
	var land_position := coconut_island.global_position
	ship.docking_distance = 30
	ship.global_position = coconut_island.get_dock_position() + Vector2(0, 120)
	await _wait(0.3)
	_check(coconut_island.global_position.is_equal_approx(land_position), "Islands must stay fixed on the map as the ship sails")
	_check(ship.get_nearest_island() == coconut_island, "The nearest island must be tracked")
	for frame in range(300):
		await physics_frame
		if ship._state == Ship.State.ANCHORED:
			break
	_check(ship._state == Ship.State.ANCHORED, "Reaching the docking marker must anchor the ship")
	_check(ship.speed == 0 and ship.sail_level == 0 and not ship.stations_enabled, "Docking must stop sailing")
	_check(ship.global_position.distance_to(ship._dock_position) < 1, "Docking must align the rowboat route with land")
	player.position = ship.stern_zone.position
	await _wait(0.3)
	_check(ship._player_at_stern, "The stern must remain reachable after docking")
	ship.row_speed = 3000
	await _press("interact")
	_check(ship._state == Ship.State.ROWING and not player.visible, "E at the stern must start the rowboat cutscene")
	for frame in range(300):
		await process_frame
		if is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/island.tscn":
			break
	_check(current_scene.scene_file_path == "res://scenes/island.tscn", "Rowing must open the playable island scene")
	if current_scene.scene_file_path != "res://scenes/island.tscn":
		quit(1)
		return
	var island_game = current_scene
	for coconut in get_nodes_in_group("coconuts"):
		island_game._on_item_collected(&"coconut")
	island_game.try_escape()
	for frame in range(600):
		await process_frame
		if current_scene is Ship:
			break
	_check(current_scene is Ship, "Winning the island game must return to the integrated ship")
	if not current_scene is Ship:
		quit(1)
		return
	ship = current_scene as Ship
	for frame in range(600):
		await physics_frame
		if ship._state == Ship.State.SAILING:
			break
	_check(ship._state == Ship.State.SAILING, "Return cutscene must finish")
	_check(ship.global_position.distance_to(ship.get_island(&"CoconutIsland").get_dock_position()) < 1, "Returning must put the ship back at the island it left from")
	_check(ship.get_nearest_island() == ship.get_island(&"TreasureIsland"), "A finished island must no longer count as the nearest island")
	_check(ship.player.visible and not ship.player.using_station, "Returning must restore player movement")
	_check(ship.has_node("Cooking") and ship.has_node("Sail") and ship.has_node("Helm"), "All stations must survive the island round trip")
	_check(ship.get_node("Camera2D").is_current(), "Returning directly to the ship must retain the camera")
	initial_position = ship.global_position
	await _wait(0.5)
	_check(ship.global_position.is_equal_approx(initial_position), "Returning must wait for manual sailing")
	ship.player.position = Vector2(-20, 0)
	await _wait(0.2)
	await _press("interact")
	_check(ship.player.active_station == ship.get_node("Sail"), "Sail controls must work after returning")
	await _press("move_up")
	await _wait(0.5)
	_check(ship.global_position.distance_to(initial_position) > 0, "The player must be able to leave the island under sail")
	print("Sailing integration: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
