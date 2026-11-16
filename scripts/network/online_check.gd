extends Node
var failures := 0
func check(value: bool, caption: String) -> void:
	print("EOS_LIFECYCLE ", "PASS " if value else "FAIL ", caption)
	if not value: failures += 1
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	NetworkSession.status_changed.connect(func(value): print("EOS_LIFECYCLE status=", value))
	await EOSGRuntime.host("Lifecycle " + str(OS.get_process_id()), "test", false)
	check(NetworkSession.online, "Create online crew and native host")
	if NetworkSession.online:
		await get_tree().create_timer(1).timeout
		check(NetworkSession.world_ready, "Game loads with native EOS peer")
		var backend: Node = EOSGRuntime.backend
		for attempt in 8:
			await backend.browse()
			if EOSGRuntime.crews.has(backend.lobby_id): break
			await get_tree().create_timer(2).timeout
		var found := false
		for crew in EOSGRuntime.crews.values():
			if crew.title == NetworkSession.crew_title:
				found = true
				check(int(crew.count) == 1 and crew.locked, "Published occupancy and password marker")
		check(found, "Published crew searchable through Epic")
		var id: String = backend.lobby_id
		NetworkSession.save_world()
		await backend.leave_lobby()
		check(backend.lobby_id.is_empty(), "Leave destroys hosted lobby")
		NetworkSession.leave()
		await get_tree().create_timer(1).timeout
		for attempt in 8:
			await backend.browse()
			if not EOSGRuntime.crews.has(id): break
			await get_tree().create_timer(2).timeout
		check(not EOSGRuntime.crews.has(id), "Closed crew disappears from online search")
	EOSGRuntime.shutdown()
	print("EOS_LIFECYCLE failures=", failures)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(failures)
