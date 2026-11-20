extends Node
var failures: int = 0
func _ready() -> void:
	run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	var args := OS.get_cmdline_user_args()
	var statuses: Array[String] = []
	NetworkSession.status_changed.connect(func(message: String) -> void: statuses.append(message))
	var port := 24680 if "--export-test" in args else 24679
	if "--test-host" in args:
		NetworkSession.dedicated = true
		NetworkSession.host_session("Dedicated", port, "test", false)
		await get_tree().create_timer(6).timeout
		check(NetworkSession.players.size() == 1 and not NetworkSession.players.has(1), "Dedicated server has one real client and no host ghost")
		NetworkSession.ship.global_position = Vector2(345, -678)
		var storage := VoyageState.get_ship_storage()
		var original_wood := 0
		for entry: Dictionary in storage.slots:
			if entry.get("id") == &"wood": original_wood += int(entry.quantity)
		storage.add_items(ItemDatabase.get_item(&"wood"), 7)
		NetworkSession.save_world()
		NetworkSession._restored.clear()
		NetworkSession.accounts.clear()
		NetworkSession.load_world()
		check(NetworkSession._restored.get("position") == Vector2(345, -678), "Saved ship position survives file reload")
		var saved_wood := 0
		for entry: Dictionary in NetworkSession._restored.storage:
			if entry.get("id") == &"wood": saved_wood += int(entry.quantity)
		check(NetworkSession.accounts.size() == 1 and saved_wood == original_wood + 7, "Saved accounts and chest survive reload, including starter supplies")
		await get_tree().create_timer(2).timeout
	else:
		await get_tree().create_timer(1).timeout
		NetworkSession.join_session("127.0.0.1", port, "WrongPassword", "wrong")
		await get_tree().create_timer(1.5).timeout
		check(not NetworkSession.online and "Incorrect session password." in statuses, "Wrong password rejected before entering world")
		NetworkSession.join_session("127.0.0.1", port, "ValidCrew", "test")
		await get_tree().create_timer(4).timeout
		check(NetworkSession.players.size() == 1 and NetworkSession.players.has(NetworkSession.local_id), "Valid player joins headless server")
		NetworkSession.command("drag", {"index": 0, "storage": true, "destination": -1, "revision": -999})
		await get_tree().create_timer(0.2).timeout
		check(NetworkSession.services.has(NetworkSession.local_id) and NetworkSession.services[NetworkSession.local_id].drops.is_empty(), "Stale forged inventory request cannot create items")
	print("NETWORK ACCESS failures=", failures)
	NetworkSession.leave()
	await get_tree().create_timer(0.2).timeout
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(failures)
