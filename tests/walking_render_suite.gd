extends Node
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await get_tree().scene_changed
	var ship: Ship = get_tree().current_scene
	ship.set_physics_process(false)
	var crew = ship.player
	crew.set_physics_process(false)
	var view = ship.get_node("SailingDemo")
	view.set_process(false)
	crew.position = Vector2(-25, 90)
	for fps: int in [30, 60, 120, 144]:
		crew.reset_walk_interpolation()
		crew.capture_walk_sample()
		var origin: Vector2 = crew.position
		var tick := 0
		var previous := origin.x
		var largest_error := 0.0
		for frame in fps * 2:
			var time := float(frame) / fps
			var next_tick := int(floor(time * 60.0))
			while tick < next_tick:
				crew.position.x += crew.walk_speed / 60.0
				crew.capture_walk_sample()
				tick += 1
			var rendered: Vector2 = crew.global_position + crew.walking_render_offset(fmod(time * 60.0, 1.0))
			if frame > ceili(float(fps) / 30.0):
				largest_error = maxf(largest_error, absf(rendered.x - previous - crew.walk_speed / fps))
			previous = rendered.x
		check(largest_error < 0.002, "Uniform walking between physics ticks at %d FPS" % fps)
		print("WALK %d FPS: maximum step error %.6f px" % [fps, largest_error])
	crew.position = Vector2(-25, 90)
	crew.reset_walk_interpolation()
	crew.capture_walk_sample()
	crew.position.x += 2.0
	crew.capture_walk_sample()
	crew._walk_offset = crew.walking_render_offset(0.5)
	var before_ack: Vector2 = crew.visual_position()
	crew.smooth_correction(before_ack)
	check(crew.visual_position().is_equal_approx(before_ack) and crew.walking_render_offset(0.5).is_equal_approx(Vector2(-1, 0)), "Zero-error acknowledgement preserves walking phase")
	crew.position.x += 3.0
	crew.smooth_correction(before_ack)
	check(crew.visual_position().is_equal_approx(before_ack) and crew.walking_render_offset(0.5).is_equal_approx(Vector2(-1, 0)), "Replay correction preserves both displayed position and walking phase")
	crew.presentation_offset = Vector2.ZERO
	var authoritative: Vector2 = crew.position
	var halfway: Vector2 = crew.walking_render_offset(0.5)
	check(halfway.is_equal_approx(Vector2(-1, 0)), "Mid-frame interpolation lies between confirmed positions")
	check(crew.position == authoritative, "Rendering does not change collision state")
	crew.position += Vector2(900, 0)
	check(crew.walking_render_offset(0.5) == Vector2.ZERO, "Teleport does not streak")
	crew.capture_walk_sample()
	check(crew.walking_render_offset(0.5) == Vector2.ZERO, "Teleport resets sample history")
	crew.set_overboard(true)
	check(crew.walking_render_offset(0.5) == Vector2.ZERO, "Boarding coordinates never interpolate together")
	crew.set_overboard(false)
	crew.position = Vector2(-25, 90)
	crew.reset_walk_interpolation()
	crew.capture_walk_sample()
	crew.position += Vector2(2, 0)
	crew.capture_walk_sample()
	ship.rotation = PI * 0.5
	check(crew.walking_render_offset(0.5).is_equal_approx(Vector2(0, -1)), "Walking remains attached to a rotating deck")
	ship.rotation = 0
	NetworkSession.online = true
	NetworkSession.players.clear()
	check(crew.walking_render_offset(0.5) == Vector2.ZERO, "Remote crew is not double interpolated")
	crew.minigame_avatar = true
	check(crew.walking_render_offset(0.5).is_equal_approx(Vector2(-1, 0)), "Private minigame avatar interpolates during co-op")
	crew.minigame_avatar = false
	NetworkSession.online = false
	for fps: int in [30, 60, 144]:
		view.camera.global_position = Vector2.ZERO
		view.challenge_center = Vector2(100, 0)
		view._update_camera(1.0 / fps)
		check(view.camera.global_position.x > 0 and view.camera.global_position.x < 100, "Challenge camera follows without snapping")
		for frame in fps - 1: view._update_camera(1.0 / fps)
		check(absf(view.camera.global_position.x - 100.0 * (1.0 - exp(-Ship.VIEW_FOLLOW_SPEED))) < 0.001, "Camera response is frame-rate independent")
	view.challenge_center = Vector2.INF
	check(crew.process_priority < ship.process_priority and ship.process_priority < view.process_priority, "Camera reads current-frame visuals")
	var start := Time.get_ticks_usec()
	for i in 100000: crew.walking_render_offset(0.5)
	print("WALK render sampler: %.3f us/call" % ((Time.get_ticks_usec() - start) / 100000.0))
	print("Walking render: %d failure(s)" % failures)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(1 if failures else 0)

