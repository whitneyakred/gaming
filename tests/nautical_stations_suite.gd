extends Node
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship: Ship = get_tree().current_scene
	ship.set_physics_process(false)
	ship.changing_wind_enabled = false
	var crew = ship.player
	crew.set_physics_process(false)
	var anchor: AnchorStation = ship.get_node("Anchor")
	var sail: SailStation = ship.get_node("Sail")
	var helm: HelmStation = ship.get_node("Helm")
	anchor.set_process(false)
	sail.set_process(false)
	ship.anchor_deployed = false
	anchor.deployment = 0
	anchor._process(0)
	ship.anchor_deployed = true
	check(anchor.deployment == 0, "Lowering begins on deck")
	anchor._process(anchor.lower_seconds * 0.4)
	check(anchor.anchor_point().x < anchor.stowed_offset.x and anchor.splash_count == 0, "Anchor travels over port rail before splashing")
	anchor._process(anchor.lower_seconds * 0.4)
	check(anchor.splash_count == 1, "Water impact emits exactly one splash")
	anchor._process(2)
	check(anchor.deployment == 1 and anchor.target_deployed, "Submerged anchor leaves connected rope and winch")
	anchor._update_artwork(true)
	anchor._process(2)
	check(anchor.splash_count == 1, "Repeated state cannot duplicate splash")
	ship.anchor_deployed = false
	anchor._process(anchor.raise_seconds)
	check(anchor.deployment == 0 and anchor.splash_count == 1, "Retrieval returns anchor without lowering splash")
	ship.anchor_deployed = true
	anchor._process(0.2)
	ship.anchor_deployed = false
	anchor._process(2)
	check(anchor.deployment == 0 and anchor.splash_count == 1, "Quick reversal settles without orphan effect")
	anchor._observed_state = false
	ship.anchor_deployed = true
	check(anchor.deployment == 1 and anchor.splash_count == 1, "Saved deployed anchor initializes silently")
	ship.anchor_deployed = false
	anchor._process(0)
	ship.wind_velocity = Vector2.UP
	var previous := -1.0
	for level in 4:
		ship.set_sail_level(level)
		sail._process(2)
		var speed := ship.get_target_speed()
		check(speed > previous and is_equal_approx(sail.cloth_height, sail.reef_heights[level]), "Distinct reef/speed setting %d" % level)
		previous = speed
	check(sail.z_index > crew.z_index, "Crew walks under sail artwork")
	crew.position = sail.position + Vector2(0, 25)
	crew.reset_walk_interpolation()
	check(sail.crew_under_sail(), "Sail detects local avatar's head")
	sail._process(1)
	check(sail.cloth_opacity < 0.41, "Sail fades like tree canopy")
	crew.position = Vector2(6, 175)
	crew.reset_walk_interpolation()
	sail._process(1)
	check(sail.cloth_opacity > 0.99, "Sail opacity restores outside cloth")
	ship.set_sail_angle(90)
	ship.rotation = 0.7
	crew.global_position = sail.to_global(Vector2(-7, 0)) + Vector2(0, 18)
	crew.reset_walk_interpolation()
	check(sail.crew_under_sail(), "Occlusion respects sail trim and ship rotation")
	ship.rotation = 0
	ship.set_sail_angle(0)
	ship.speed = 0
	sail.visual_speed = 0
	sail.wind_phase = 0
	sail._process(0.1)
	var slow_phase := sail.wind_phase
	ship.speed = ship.maximum_speed
	sail.visual_speed = ship.maximum_speed
	sail.wind_phase = 0
	sail._process(0.1)
	check(sail.wind_phase > slow_phase, "Faster sailing increases cloth motion")
	crew.position = Vector2(-55, 5)
	crew.reset_walk_interpolation()
	crew.move_crew(Vector2.RIGHT, 0.5)
	check(crew.position.x > 10, "Canvas does not act as a deck-wide collision wall")
	crew.set_physics_process(true)
	crew.position = Vector2(6, -100)
	var far_position: Vector2 = crew.position
	check(not helm.try_take_control(crew) and crew.position == far_position, "Distant helm requests cannot teleport crew")
	crew.position = helm.position + Vector2(23, 0)
	check(helm.try_take_control(crew), "Nearby crew takes helm")
	check(crew.global_position.is_equal_approx(helm.to_global(helm.operator_offset)), "Feet dock behind wheel")
	crew.idle_sprite.refresh(0)
	check(crew.idle_sprite.facing == 3, "Helmsman faces the wheel")
	var station_position: Vector2 = crew.position
	crew.move_crew(Vector2.RIGHT, 0.2)
	check(crew.position == station_position, "Steering cannot walk off operating pad")
	ship.set_wheel_angle(90)
	helm.get_node("Visual")._process(0)
	check(is_equal_approx(helm.get_node("Visual/Wheel").rotation, PI * 0.5), "New deck wheel follows rudder angle")
	check(helm.get_node("Visual/Wheel").texture == preload("res://assets/props/helm_wheel_pixel.tres"), "Deck and HUD share marked wheel texture")
	helm.release_control()
	crew.move_crew(Vector2.RIGHT, 0.1)
	check(crew.position.x > station_position.x, "Leaving helm restores walking")
	ship.rotation = 0.7
	crew.global_position = helm.to_global(Vector2(23, 0))
	check(helm.try_take_control(crew) and crew.global_position.is_equal_approx(helm.to_global(helm.operator_offset)), "Operating pad follows rotated ship")
	helm.release_control()
	ship.rotation = 0
	check(ship.get_node("Crafting").position.x == helm.position.x, "Workbench aligns with ship station centerline")
	if "--capture" in OS.get_cmdline_user_args():
		GameWindow.set_preference("camera_zoom", 1.4)
		ship.speed = 0
		ship.set_wheel_angle(0)
		ship.set_sail_angle(18)
		ship.set_sail_level(3)
		sail.set_process(true)
		anchor.set_process(true)
		crew.position = helm.position + Vector2(0, 28)
		helm.try_take_control(crew)
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/nautical-validation/ship-polish.png")
		ship.anchor_deployed = true
		await get_tree().create_timer(0.68).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/nautical-validation/anchor-splash.png")
		await get_tree().create_timer(0.5).timeout
	print("NAUTICAL STATIONS: %d checks, %d failures" % [checks, failures])
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(1 if failures else 0)
