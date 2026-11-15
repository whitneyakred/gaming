extends Node
var failures: int = 0
func _ready() -> void:
	run.call_deferred()
func check(value: bool, caption: String) -> void:
	if not value:
		failures += 1
		push_error(caption)
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	if "--test-host" in OS.get_cmdline_user_args():
		NetworkSession.crew_title = "Discovery Test Crew"
		NetworkSession.host_session("Captain", 24685, "", false)
		await get_tree().create_timer(6).timeout
		check(NetworkSession.players.size() == 2, "Discovered crew accepts a player without entering an address")
		NetworkSession.leave()
	else:
		NetworkSession.save_player_name("Test Sailor")
		var config := ConfigFile.new()
		config.load(NetworkSession.profile_path)
		check(config.get_value("crew", "name") == "Test Sailor", "Player name persists with identity")
		await get_tree().create_timer(1).timeout
		NetworkSession.discovery.browse()
		await get_tree().create_timer(2).timeout
		var matches: Array = NetworkSession.discovery.crews.values().filter(func(d: Dictionary) -> bool: return d.title == "Discovery Test Crew")
		check(matches.size() == 1, "Broadcast and loopback results are deduplicated")
		if not matches.is_empty():
			var crew: Dictionary = matches[0]
			check(int(crew.count) == 1, "Crew advertises current count")
			NetworkSession.join_session(crew.address, int(crew.port), NetworkSession.local_name)
			await get_tree().create_timer(2).timeout
			check(NetworkSession.players.size() == 2, "Discovery address joins real ENet host")
		await get_tree().create_timer(9).timeout
		check(NetworkSession.discovery.crews.is_empty(), "Closed crews expire from browser")
	print("CREW DISCOVERY failures=", failures)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(failures)
