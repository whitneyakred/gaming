extends SceneTree
## Run with Godot --headless --path . --script res://tests/anchor_station_test.gd

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_offline()
	var ship: ShipMotion = game.ship
	var anchor: AnchorStation = ship.get_node("Anchor")
	var crew: CharacterBody2D = game.players[1]
	assert(game.stations.has("Anchor"), "Anchor must be discovered for multiplayer")
	crew.position = Vector2(0, -120)
	assert(not anchor.try_take_control(crew), "Remote interaction must be rejected")
	crew.position = anchor.position
	ship.set_sail_level(3)
	ship.wind_velocity = Vector2.UP
	ship.speed = 110.0
	ship.set_wheel_angle(360.0)
	game.inputs[1].interact = true
	game.inputs[1].received = Time.get_ticks_msec() / 1000.0
	game._simulate(1.0 / 60.0)
	assert(ship.anchor_deployed, "Server interaction must lower anchor")
	assert(crew.get("active_station") == null, "Anchor must not lock crew into a station")
	ship.simulate_movement(0.1)
	assert(ship.speed > 0.0 and ship.speed < 110.0, "Anchor must brake gradually")
	for tick in range(180):
		ship.simulate_movement(1.0 / 60.0)
	assert(ship.speed == 0.0 and ship.turn_rate == 0.0)
	var stopped_position := ship.position
	var stopped_rotation := ship.rotation
	for tick in range(180):
		ship.simulate_movement(1.0 / 60.0)
	assert(ship.position == stopped_position and ship.rotation == stopped_rotation, "Full sail and helm must not move an anchored ship")
	var state := anchor.capture_state()
	assert(anchor.try_take_control(crew))
	assert(not ship.anchor_deployed)
	ship.simulate_movement(0.1)
	assert(ship.speed > 0.0, "Raising anchor must restore propulsion")
	anchor.restore_state(state)
	assert(ship.anchor_deployed and not anchor.artwork.visible, "Snapshot restore must restore braking and hide the submerged anchor")
	game.end_session("")
	assert(not ship.anchor_deployed and anchor.artwork.visible, "New sessions must reset anchor")
	game.queue_free()
	await process_frame
	print("Anchor station tests passed")
	quit()
