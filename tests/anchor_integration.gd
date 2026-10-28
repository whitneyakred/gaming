extends SceneTree
## Run: Godot --headless --path . --script res://tests/anchor_integration.gd

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _press_interact() -> void:
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
	var anchor := ship.get_node("Anchor") as AnchorStation
	var player := ship.player
	ship.set_physics_process(false)
	ship.changing_wind_enabled = false
	ship.wind_velocity = Vector2.UP
	_check(not ship.anchor_deployed and anchor.artwork.visible, "The anchor must start raised")
	player.position = Vector2(0, -100)
	_check(not anchor.try_take_control(player), "The anchor must reject interaction from far away")
	player.position = anchor.position
	player.try_use_station(ship.get_node("Sail"))
	_check(not anchor.try_take_control(player), "The anchor must respect another station's crew lock")
	player.leave_station(ship.get_node("Sail"))
	await _press_interact()
	_check(ship.anchor_deployed and not player.using_station, "E must lower the anchor once and immediately release the crew")
	_check(not anchor.artwork.visible and anchor.prompt.text == "E: Raise anchor", "Artwork and prompt must follow the lowered anchor")
	ship.set_sail_level(3)
	ship.set_wheel_angle(360)
	ship.speed = ship.maximum_speed
	var heading := ship.global_rotation
	ship._physics_process(0.25)
	_check(ship.speed > 0 and ship.speed < ship.maximum_speed, "Lowering must brake gradually")
	_check(ship.get_target_speed() == 0, "A lowered anchor must prevent sail propulsion")
	for frame in range(240):
		ship._physics_process(1.0 / 60.0)
	var stopped_position := ship.global_position
	for frame in range(120):
		ship._physics_process(1.0 / 60.0)
	_check(ship.speed == 0 and ship.global_position == stopped_position, "The anchor must hold the ship stationary")
	_check(ship.global_rotation == heading, "The anchor must prevent turning even with the wheel turned")
	ship.set_wheel_angle(0)
	await _press_interact()
	_check(not ship.anchor_deployed and anchor.artwork.visible and not player.using_station, "E must raise the anchor and release the crew")
	ship._physics_process(0.5)
	_check(ship.speed > 0 and ship.global_position != stopped_position, "Raising must restore sailing with the existing sail setting")
	ship.anchor_deployed = true
	ship.speed = 0
	ship.global_position = ship.get_island(&"CoconutIsland").get_dock_position()
	ship._physics_process(0.1)
	_check(ship._state == Ship.State.SAILING, "Manual anchoring must prevent automatic docking")
	ship.anchor_deployed = false
	ship._physics_process(0.01)
	_check(ship._state == Ship.State.DOCKING and ship.anchor_deployed, "Raising near an island must allow docking to lower the anchor automatically")
	await create_timer(1.0).timeout
	_check(ship._state == Ship.State.ANCHORED and ship.speed == 0, "Docking must finish with the ship stopped")
	_check(not anchor.try_take_control(player), "A docked ship must not allow manual raising")
	print("Anchor integration: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
