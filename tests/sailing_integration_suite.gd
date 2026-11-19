extends Node
## Current sail/helm/anchor flow. Swimming and grill behavior have dedicated suites.
var failures: int = 0
var checks: int = 0

func _ready() -> void:
	get_tree().create_timer(45).timeout.connect(func() -> void: get_tree().quit(1))
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().physics_frame
	var ship: Ship = get_tree().current_scene.get_node("Ship")
	var crew = ship.player
	var sail: SailStation = ship.get_node("Sail")
	var helm: HelmStation = ship.get_node("Helm")
	var anchor: AnchorStation = ship.get_node("Anchor")
	ship.changing_wind_enabled = false
	ship.wind_velocity = Vector2.UP
	ship.anchor_deployed = false
	ship.set_sail_level(0)
	var start := ship.global_position
	await wait(0.2)
	check(ship.global_position.is_equal_approx(start), "Stowed sails leave ship still")
	check(ship.get_islands().size() == WorldLayout.ISLAND_COUNT + 4, "Ordinary and quest islands are present")
	crew.position = sail.position
	check(sail.try_take_control(crew), "Nearby crew can claim sail")
	for level in range(1, 4):
		Input.action_press("move_up")
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_release("move_up")
		await get_tree().physics_frame
		check(ship.sail_level == level, "One press advances one sail level")
	Input.action_press("move_right")
	await wait(0.2)
	Input.action_release("move_right")
	check(ship.sail_angle_degrees > 0, "Trim responds to input")
	# Overlap reach only to isolate the exclusive-owner rule from distance.
	var old_helm_position := helm.position
	helm.position = sail.position
	check(not helm.try_take_control(crew), "Helm cannot steal a sailor from the sail")
	helm.position = old_helm_position
	sail.release_control()
	check(not crew.using_station, "Leaving sail returns movement")
	crew.position = helm.position
	check(helm.try_take_control(crew), "Nearby crew can claim helm")
	var before_turn := ship.global_rotation
	Input.action_press("move_right")
	await wait(0.5)
	Input.action_release("move_right")
	check(ship.wheel_angle_degrees > 0 and ship.global_rotation > before_turn, "Helm turns moving ship")
	helm.release_control()
	check(ship.global_position.distance_to(start) > 0, "Raised sails propel ship")
	crew.position = anchor.position
	check(anchor.try_take_control(crew) and ship.anchor_deployed, "Anchor deploys on interaction")
	check(not crew.using_station and not anchor.artwork.visible, "Anchor releases crew and changes artwork")
	await wait(2.0)
	check(is_zero_approx(ship.speed), "Anchor stops ship despite deployed sail")
	var anchored := ship.global_position
	await wait(0.2)
	check(ship.global_position.is_equal_approx(anchored), "Anchored position stays fixed")
	check(anchor.try_take_control(crew) and not ship.anchor_deployed, "Second interaction raises anchor")
	await wait(0.3)
	check(ship.global_position.distance_to(anchored) > 0, "Sailing resumes after raising anchor")
	print("Sailing integration: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)
