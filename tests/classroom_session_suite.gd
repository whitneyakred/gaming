extends Node
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	get_tree().create_timer(70).timeout.connect(func(): get_tree().quit(1))
	GameWindow.set_preference("pause_unfocused", false)
	var args := OS.get_cmdline_user_args()
	var role := args[args.find("--class-role") + 1]
	NetworkSession.local_name = "Class " + role
	if role == "host":
		await HarborService.host("Four-player classroom regression", "class")
	else:
		await wait(2)
		for attempt in 6:
			await HarborService.browse()
			for crew: Dictionary in HarborService.crews.values():
				if crew.title == "Four-player classroom regression":
					await HarborService.join_crew(crew.id, "class")
					break
			if NetworkSession.online: break
			await wait(5.2)
	for attempt in 300:
		if NetworkSession.world_ready and NetworkSession.players.size() == 4: break
		await wait(0.1)
	check(NetworkSession.players.size() == 4, "All four actual Godot peers joined")
	if NetworkSession.players.size() != 4:
		get_tree().quit(1)
		return
	var transport := multiplayer.multiplayer_peer as HarborPeer
	var before := transport.packets_sent
	var started := Time.get_ticks_msec()
	var seen := {}
	var max_correction := 0.0
	for step in 600:
		if role != "host":
			# Long-held controls exercise refresh and prediction acknowledgements.
			if step % 36 == 0:
				Input.action_release("move_up")
				Input.action_release("move_down")
				Input.action_press("move_up" if step % 72 < 36 else "move_down")
			seen[NetworkSession._received_serial] = true
			max_correction = maxf(max_correction, NetworkSession._prediction_error.length())
		await wait(1.0 / 60.0)
	Input.action_release("move_up")
	Input.action_release("move_down")
	await wait(0.3)
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	var rate := (transport.packets_sent - before) / elapsed
	check(NetworkSession.online and NetworkSession.players.size() == 4, "Full crew stayed connected")
	check(rate < (12.0 if role == "host" else 6.0), "Actual four-player traffic fits the budget")
	if role != "host":
		check(seen.size() > elapsed * 6, "Guest receives regular host snapshots")
		check(max_correction < 50.0, "Held-input prediction remains bounded")
	print("CLASSROOM SESSION ", role, ": ", failures, " failures; ", snappedf(rate, 0.01), " packets/s; ", seen.size(), " snapshots; max correction ", max_correction)
	# Let all guests finish their measurements before the captain ends the room.
	await wait(2 if role == "host" else 1)
	NetworkSession.leave()
	await wait(0.2)
	GameWindow.shutdown_audio()
	await wait(0.2)
	get_tree().quit(failures)
