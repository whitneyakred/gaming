extends Node
var failures := 0
func check(value: bool, caption: String) -> void:
	print("EOS_TEST ", "PASS " if value else "FAIL ", caption)
	if not value: failures += 1
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	NetworkSession.status_changed.connect(func(value): print("EOS_TEST status=", value))
	GameWindow.set_preference("pause_unfocused", false)
	get_tree().create_timer(100).timeout.connect(func(): print("EOS_TEST TIMEOUT"); EOSGRuntime.shutdown(); get_tree().quit(1))
	if "--test-host" in OS.get_cmdline_user_args():
		await EOSGRuntime.host("Relay test crew", "test", false)
		check(NetworkSession.online, "Online host created")
		if NetworkSession.online:
			var until := Time.get_ticks_msec() + 50000
			while NetworkSession.players.size() < 2 and Time.get_ticks_msec() < until: await get_tree().create_timer(0.2).timeout
			check(NetworkSession.players.size() == 2, "Second player reached host over relay")
			await get_tree().create_timer(6).timeout
	else:
		await get_tree().create_timer(6).timeout
		for attempt in 6:
			await EOSGRuntime.browse()
			if not EOSGRuntime.crews.is_empty(): break
			await get_tree().create_timer(2).timeout
		var matches: Array = EOSGRuntime.crews.values().filter(func(d): return d.title == "Relay test crew")
		check(matches.size() > 0, "Live lobby found by name")
		if not matches.is_empty():
			await EOSGRuntime.join_crew(matches[0].id, "test")
			var until := Time.get_ticks_msec() + 25000
			while NetworkSession.players.size() < 2 and Time.get_ticks_msec() < until: await get_tree().create_timer(0.2).timeout
			check(NetworkSession.players.size() == 2, "Replicated world arrived over relay")
			if NetworkSession.players.has(NetworkSession.local_id):
				var player: Node2D = NetworkSession.players[NetworkSession.local_id]
				var before := player.position
				Input.action_press("move_right")
				await get_tree().create_timer(0.5).timeout
				Input.action_release("move_right")
				await get_tree().create_timer(0.5).timeout
				check(player.position.distance_to(before) > 10, "Input and snapshots travel through relay")
	NetworkSession.leave()
	await EOSGRuntime.leave_lobby()
	await get_tree().create_timer(0.5).timeout
	EOSGRuntime.shutdown()
	print("EOS_TEST failures=", failures)
	GameWindow.shutdown_audio()
	get_tree().quit(failures)
