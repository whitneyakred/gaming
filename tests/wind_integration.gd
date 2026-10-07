extends SceneTree
## Run: Godot --headless --path . --script res://tests/wind_integration.gd

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
	var hud := ship.get_node("SailingDemo")
	var arrow := hud.get_node("HUD/Wind/Arrow") as Label
	ship.set_process(false)
	ship.set_physics_process(false)
	# Seed only the test; ordinary play keeps Godot's randomized generator.
	ship._wind_random.seed = 12345
	ship.wind_change_interval = 1.0
	ship._wind_change_left = 0.0
	ship._state = Ship.State.ANCHORED
	var initial_wind := ship.wind_velocity
	var largest_change := 0.0
	for frame in range(600):
		var previous := ship.wind_velocity
		ship._process(1.0 / 60.0)
		hud._process(1.0 / 60.0)
		largest_change = maxf(largest_change, absf(initial_wind.angle_to(ship.wind_velocity)))
		_check(absf(previous.angle_to(ship.wind_velocity)) < deg_to_rad(2.0), "Wind must turn smoothly, not snap")
		_check(absf(ship.wind_velocity.length() - initial_wind.length()) < 0.001, "Direction changes must preserve wind strength")
		_check(absf(wrapf(arrow.rotation - ship.wind_velocity.angle() - PI / 2.0, -PI, PI)) < 0.0001, "HUD arrow must follow actual wind")
	_check(largest_change > 0.05, "Wind must change over time even while anchored")
	# From the same starting direction, random targets must cover all four quadrants.
	var quadrants: Array[bool] = [false, false, false, false]
	for attempt in range(100):
		ship.wind_velocity = Vector2.RIGHT
		ship._wind_change_left = 0.0
		ship._process(0.0)
		var quadrant := mini(3, int((ship._target_wind_angle + PI) / (PI / 2.0)))
		quadrants[quadrant] = true
	_check(not quadrants.has(false), "New wind targets must cover the full circle from a fixed starting direction")
	ship.changing_wind_enabled = false
	ship.wind_velocity = Vector2.UP
	ship._process(10.0)
	_check(ship.wind_velocity == Vector2.UP, "Disabled random wind must preserve manual wind")
	ship.global_rotation = 0.0
	ship.set_sail_level(3)
	ship.set_sail_angle(0.0)
	_check(is_equal_approx(ship.get_target_speed(), ship.maximum_speed), "Following wind must still fill the sail")
	ship.wind_velocity = Vector2.DOWN
	_check(is_zero_approx(ship.get_target_speed()), "Headwind must not propel the ship")
	ship.changing_wind_enabled = true
	ship.wind_velocity = Vector2.ZERO
	ship._process(1.0)
	hud._process(1.0)
	_check(ship.wind_velocity.is_zero_approx() and not arrow.visible, "Calm wind must stay calm and hide the arrow")
	print("Wind integration: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
