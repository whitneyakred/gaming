extends Node
## Opt-in, isolated packaged-build check; never runs during normal player startup.
var failures := 0
func check(value: bool, caption: String) -> void:
	print("HARBOR_CHECK ", "PASS " if value else "FAIL ", caption)
	if not value: failures += 1
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	var title := "Release check " + str(OS.get_process_id())
	await HarborService.host(title, "test")
	check(NetworkSession.online, "Packaged game connects and hosts")
	if NetworkSession.online:
		await get_tree().create_timer(1).timeout
		check(NetworkSession.world_ready, "World loads with relay peer")
		var response: Dictionary = await HarborService.call_api("/api/crews")
		var found := false
		for crew: Dictionary in response.get("crews", []):
			if crew.title == title:
				found = true
				check(int(crew.count) == 1 and crew.locked, "Directory publishes occupancy and private state")
		check(found, "Hosted voyage is discoverable")
		NetworkSession.leave()
		await get_tree().create_timer(1).timeout
		response = await HarborService.call_api("/api/crews")
		found = false
		for crew: Dictionary in response.get("crews", []):
			if crew.title == title: found = true
		check(not found, "Leaving removes hosted voyage")
	print("HARBOR_CHECK failures=", failures)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(failures)
