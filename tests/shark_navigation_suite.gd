extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameWindow.set_preference("fullscreen", false)
	GameWindow.set_preference("pause_unfocused", false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship = get_tree().current_scene.get_node("Ship")
	var world: SurvivalWorld = ship.survival
	world.set_physics_process(false)
	var player = ship.player
	player.set_overboard(true)
	player.update_land(false)
	player.swim_time = 11
	player.health = 1000
	player.global_position = ship.to_global(Vector2(-260, 0))
	world.advance_sharks(0.01, world.crew())
	check(world.sharks[0].target == 1 and world.sharks[1].target == 1, "Two sharks pursue one swimmer")
	var shark: Dictionary = world.sharks[0]
	shark.position = ship.to_global(Vector2(260, 0))
	shark.angle = PI
	shark.mode = "arrive"
	shark.size = 1.75
	var stayed_in_water := true
	var closest := INF
	for i in 1200:
		world.advance_sharks(1.0 / 60, world.crew())
		stayed_in_water = stayed_in_water and world.is_water(shark.position)
		closest = minf(closest, Vector2(shark.position).distance_to(player.global_position))
	check(stayed_in_water, "Shark routes around hull without crossing it")
	check(closest < 100, "Shark reaches swimmer on opposite side of hull")
	var before: Vector2 = shark.position
	shark.alpha = 1.0
	player.update_land(true)
	for i in 60: world.advance_sharks(1.0 / 60, world.crew())
	check(shark.target == 0 and shark.mode == "depart", "Land ends pursuit immediately")
	check(Vector2(shark.position).distance_to(before) > 35 and shark.alpha > 0.9, "Shark swims away visibly before fading")
	for i in 300: world.advance_sharks(1.0 / 60, world.crew())
	check(not shark.active and shark.alpha == 0, "Departing shark eventually fades out")
	var other = load("res://scenes/player.tscn").instantiate()
	add_child(other)
	other.set_overboard(true)
	other.update_land(false)
	other.swim_time = 11
	other.global_position = Vector2(1600, 0)
	player.update_land(false)
	player.swim_time = 11
	world.advance_sharks(0.01, {1: player, 2: other})
	var counts := {1: 0, 2: 0}
	for entry in world.sharks:
		if int(entry.target) in counts: counts[int(entry.target)] += 1
	check(world.sharks.size() == 4 and counts[1] == 2 and counts[2] == 2, "Two swimmers get four sharks with balanced nearest targets")
	var saved := world.capture()
	world.restore(saved)
	check(world.capture() == saved and world.shark_visuals.size() == 4, "Expanded shark pack and sizes survive snapshots")
	for entry in world.sharks: check(entry.size >= 1.0 and entry.size <= 1.75, "Shark size never below original")
	player.global_position = Vector2(0, -1200)
	shark = world.sharks[0]
	for body_size in [1.0, 1.75]:
		shark.size = body_size
		shark.position = player.global_position + Vector2(10, 0)
		shark.target = 1
		shark.mode = "lunge"
		shark.clock = 0.0
		shark.aim = player.global_position
		shark.bitten = false
		var health_before: int = player.health
		world.advance_sharks(0.01, world.crew())
		check(health_before - player.health == roundi(body_size * body_size), "Bite damage scales with body size")
	var replica := SurvivalWorld.new()
	ship.add_child(replica)
	replica.set_physics_process(false)
	replica.restore(saved)
	check(replica.sharks.size() == 4 and replica.shark_visuals.size() == 4, "Client expands visuals when receiving a larger pack")
	print("SHARK NAVIGATION: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)
