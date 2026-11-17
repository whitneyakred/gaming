extends Node
var failures := 0
var checks := 0
var role := ""
var manager: IslandChallenges
const PHASE := "res://.godot/totem-network-phase.txt"

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(role + ": " + message)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func phase(value: String) -> void:
	var file := FileAccess.open(PHASE, FileAccess.WRITE)
	file.store_string(value)

func await_phase(value: String) -> void:
	for i in 300:
		if FileAccess.file_exists(PHASE) and FileAccess.get_file_as_string(PHASE) == value: return
		await wait(0.05)
	check(false, "Timed out waiting for " + value)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	get_tree().create_timer(45).timeout.connect(func() -> void: get_tree().quit(1))
	GameWindow.set_preference("pause_unfocused", false)
	role = "host" if "--test-host" in OS.get_cmdline_user_args() else "guest"
	if role == "host":
		phase("")
		check(NetworkSession.host_session("Captain", 24781, "", false) == OK, "Host starts")
		for i in 100:
			if NetworkSession.players.size() == 2: break
			await wait(0.1)
		check(NetworkSession.players.size() == 2, "Guest joined")
		if NetworkSession.players.size() == 2: await host_tests()
	else:
		await wait(0.8)
		check(NetworkSession.join_session("127.0.0.1", 24781, "Guest") == OK, "Guest connects")
		await guest_tests()
	print("TOTEM NETWORK ", role, ": ", checks, " checks, ", failures, " failures")
	NetworkSession.leave()
	await wait(0.2)
	GameWindow.shutdown_audio()
	get_tree().quit(0 if failures == 0 else 1)

func host_tests() -> void:
	var ship := NetworkSession.ship as Ship
	manager = ship.get_node("IslandChallenges")
	var guest_id: int = NetworkSession.players.keys().filter(func(id): return id != 1)[0]
	var island := ship.get_islands()[0]
	var totem: Node2D = island.get_node("MinigameTotem")
	for player in NetworkSession.players.values():
		player.set_overboard(true)
		player.global_position = totem.global_position
		player.update_land(true)
	await wait(0.3)
	phase("start")
	for i in 100:
		if manager.locks.has(str(island.name)): break
		await wait(0.05)
	check(manager.locks.has(str(island.name)), "Guest reserves via server")
	check(not manager.try_start(1, str(island.name)), "Host cannot steal guest's island")
	var other := ship.get_islands()[1]
	ship.player.global_position = other.get_node("MinigameTotem").global_position
	check(manager.try_start(1, str(other.name)), "Different island runs concurrently")
	await wait(0.2)
	check(manager.locks.size() == 2, "Independent per-island locks")
	manager._finished_local(false)
	await wait(0.2)
	check(manager.locks.size() == 1, "Host cancel leaves guest running")
	phase("win")
	await await_phase("won")
	await wait(0.3)
	var bag: PlayerInventory = NetworkSession.players[guest_id].player_inventory
	check(bag.get_quantity(&"coconut") == 2, "Guest prizes reach authoritative inventory")
	check(manager.locks.is_empty(), "Guest completion releases lock")
	check(ship.player.player_inventory.get_quantity(&"coconut") == 0, "Host never receives guest prizes")
	phase("restart")
	await await_phase("disconnecting")
	await wait(0.8)
	check(manager.locks.is_empty(), "Disconnect frees island")
	check(NetworkSession.players.size() == 1, "Disconnected guest removed")
	phase("done")

func guest_tests() -> void:
	await await_phase("start")
	var ship := NetworkSession.ship as Ship
	manager = ship.get_node("IslandChallenges")
	NetworkSession.command("interact")
	var original_scene := get_tree().current_scene
	for i in 100:
		if is_instance_valid(manager.game): break
		await wait(0.05)
	check(is_instance_valid(manager.game), "Host starts private original game on guest")
	if not is_instance_valid(manager.game): return
	var avatar := manager.game.player
	var before := avatar.position
	var world_before: Vector2 = ship.player.global_position
	Input.action_press("move_right")
	await wait(0.2)
	Input.action_release("move_right")
	check(avatar.position.x > before.x, "Guest controls challenge avatar")
	check(ship.player.global_position.distance_to(world_before) < 1, "Guest inputs do not move world avatar")
	check(get_tree().current_scene == original_scene and ship.is_inside_tree(), "World scene stays loaded")
	await await_phase("win")
	manager.game.give_item(&"coconut", 2)
	manager.game.win_delay_seconds = 0.01
	manager.game.win()
	await wait(0.4)
	check(not is_instance_valid(manager.game), "Host acknowledges result and closes challenge")
	check(ship.player.player_inventory.get_quantity(&"coconut") == 2, "Prizes replicate to guest")
	phase("won")
	await await_phase("restart")
	NetworkSession.command("interact")
	await wait(0.4)
	check(is_instance_valid(manager.game), "Guest can replay after completing")
	phase("disconnecting")
	NetworkSession.leave()
	await await_phase("done")
