extends Node
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	for i in 8: await get_tree().physics_frame
	var ship := get_tree().current_scene as Ship
	var crew := ship.player
	var visual := crew.idle_sprite as CrewSprite
	check(visual != null, "New reusable sprite controller is installed")
	check(visual.texture == crew.character_appearance.walk_atlas, "Starts with walking atlas")
	# Render much faster than physics: regression for the frozen walking cycle.
	Engine.max_fps = 240
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	crew.set_overboard(true)
	crew.global_position = Vector2(1800, 1800)
	crew.update_land(true)
	ship.get_node("SwimAccess").set_physics_process(false)
	Input.action_press("move_right")
	var observed := {}
	for i in 48:
		await get_tree().physics_frame
		observed[visual.frame % crew.character_appearance.columns] = true
	Input.action_release("move_right")
	check(observed.has(1) and observed.has(2) and observed.has(3), "Real movement cycles both strides and passing pose at 240 render FPS")
	check(not ship.rowboat.visible, "Unused stern rowboat is hidden")
	crew.set_overboard(false)
	crew.update_land(false)
	ship.get_node("SwimAccess").set_physics_process(true)
	crew.position = Vector2.ZERO
	visual.refresh(0)
	crew.set_physics_process(false)
	visual.set_physics_process(false)
	for direction in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		var expected: int = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP].find(direction)
		var frames := {}
		for i in 8:
			crew.position += direction * 2
			visual.refresh(0.125)
			frames[visual.frame % crew.character_appearance.columns] = true
		check(visual.facing == expected, "Walk faces movement direction")
		check(frames.size() == crew.character_appearance.walk_cycle.size(), "Walk includes both strides and both arm passing poses")
	visual.refresh(0.1)
	check(visual.frame % crew.character_appearance.columns == crew.character_appearance.idle_column and not visual.moving, "Stopping holds idle frame")
	ship.global_position += Vector2(20, 0)
	visual.refresh(0.1)
	check(not visual.moving, "Sailing does not animate walking")
	ship.global_rotation = PI / 2
	crew.position += Vector2(3, 0)
	visual.refresh(0.1)
	check(visual.facing == 0, "Facing follows screen direction on a rotated ship")
	visual.facing = 1
	crew.position += Vector2(0, -3)
	visual.refresh(0.1)
	check(visual.facing == 2 and visual.flip_h and visual.frame / crew.character_appearance.columns == 1, "Right-facing side is the exact mirrored left row")
	ship.global_rotation = 0
	crew.set_overboard(true)
	crew.global_position = ship.global_position + Vector2(-180, 0)
	visual.refresh(0)
	check(visual.swimming and visual.texture == crew.character_appearance.swim_atlas, "Entering water selects swim artwork")
	var wake := crew.get_node("SwimWake") as SwimWake
	wake.set_process(false)
	wake.advance(0.016)
	for i in 100:
		crew.global_position += Vector2(8, 0)
		wake.advance(0.016)
	check(not wake.samples.is_empty() and wake.samples.size() <= wake.maximum_samples, "Swim wake emits with bounded sample count")
	var sample_position: Vector2 = wake.samples[0].position
	crew.global_position += Vector2(1, 0)
	wake.advance(0.016)
	check(wake.samples[0].position == sample_position, "Foam remains in world space behind swimmer")
	crew.global_position += Vector2(1000, 0)
	wake.advance(0.016)
	check(wake.samples.is_empty(), "Teleport clears wake without a streak across the map")
	crew.global_position += Vector2(10, 0)
	wake.advance(0.016)
	crew.update_land(true)
	wake.advance(2.0)
	check(wake.samples.is_empty(), "Landing stops emission and old foam expires")
	crew.update_land(false)
	visual.refresh(0)
	var before := visual.frame
	var water_position := crew.global_position
	var bob_start := visual.position.y
	visual.refresh(0.45)
	check(visual.frame != before and not visual.moving, "Stationary swimmer treads water")
	check(absf(visual.position.y - bob_start) > 0.1, "Swimming gently bobs between stroke poses")
	check(crew.global_position == water_position, "Swim bob never moves the gameplay body")
	var water_baseline: float = -crew.character_appearance.frame_world_size * (crew.character_appearance.water_anchor - 0.5)
	check(absf(visual.position.y - water_baseline) <= crew.character_appearance.swim_bob_height, "Swim bob stays within its configured height")
	for direction in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		crew.global_position += direction * 4
		visual.refresh(0.2)
		check(visual.facing == [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP].find(direction), "Swim faces movement direction")
	crew.update_land(true)
	check(not visual.swimming and visual.texture == crew.character_appearance.walk_atlas, "Shore restores walking without portrait cropping")
	check(is_equal_approx(visual.position.y, -crew.character_appearance.frame_world_size * (crew.character_appearance.feet_anchor - 0.5)), "Landing removes swimming bob")
	crew.set_overboard(false)
	crew.update_land(false)
	crew.position = Vector2(0, 70)
	visual.refresh(0)
	check(not visual.swimming and crew.collision_mask != 0, "Boarding restores deck collision and walk visuals")
	crew.play_fishing_animation()
	check(visual.visible and not crew.fishing_animation.visible, "Fishing preserves new sailor")
	if "--capture" in OS.get_cmdline_user_args():
		ship._view.view_offset = Vector2.ZERO
		ship._view._focus_offset = Vector2.ZERO
		ship._view.camera.global_position = ship.global_position
		ship._view.camera.reset_smoothing()
		ship._view.camera.force_update_scroll()
		visual.facing = 0
		visual.refresh(0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/sailor-deck.png")
		crew.set_overboard(true)
		crew.global_position = ship.to_global(Vector2(-270, 0))
		wake.advance(0.016)
		for i in 12:
			crew.global_position += Vector2(7, 0)
			wake.advance(0.08)
		visual.refresh(0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/sailor-swim.png")
	print("CHARACTER ANIMATION: ", checks, " checks, ", failures, " failures")
	GameWindow.shutdown_audio()
	get_tree().quit(0 if failures == 0 else 1)
