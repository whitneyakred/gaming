extends Node
var failures: int = 0
var checks: int = 0
var role: String
var last_phase: String = ""
var client_seen_fish: bool = false
var shared_grill_key: int = -1
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(role + ": " + message)
func _ready() -> void:
	run.call_deferred()
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
func phase(value: String) -> void:
	var file := FileAccess.open("res://.godot/network-phase.txt", FileAccess.WRITE)
	file.store_string(value)
	file.close()
func read_phase() -> String:
	return FileAccess.get_file_as_string("res://.godot/network-phase.txt") if FileAccess.file_exists("res://.godot/network-phase.txt") else ""
func run() -> void:
	get_tree().create_timer(70).timeout.connect(func() -> void: get_tree().quit(1))
	GameWindow.set_preference("pause_unfocused", false)
	GameWindow.set_preference("fullscreen", false)
	get_window().size = Vector2i(1280, 720)
	var args := OS.get_cmdline_user_args()
	role = "host" if "--test-host" in args else ("Alpha" if "--test-alpha" in args else "Beta")
	if role == "host":
		phase("")
		if "--relay-test" in args:
			NetworkSession.local_name = "Captain"
			await HarborService.host("Relay smoke", "test")
		else:
			NetworkSession.host_session("Captain", 24678, "test", false)
		await host_tests()
	else:
		await wait(1 if role == "Alpha" else 2)
		await join_test()
		await client_tests()
	print("NETWORK ", role, ": ", checks, " checks, ", failures, " failures")
	if NetworkSession.online:
		NetworkSession.leave()
	await wait(0.2)
	GameWindow.shutdown_audio()
	await wait(0.1)
	get_tree().quit(0 if failures == 0 else 1)

func join_test() -> void:
	if "--relay-test" in OS.get_cmdline_user_args():
		NetworkSession.local_name = role
		await HarborService.browse()
		for crew: Dictionary in HarborService.crews.values():
			if crew.title == "Relay smoke":
				await HarborService.join_crew(crew.id, "test")
				return
	else:
		NetworkSession.join_session("127.0.0.1", 24678, role, "test")
func host_tests() -> void:
	for i in 100:
		if NetworkSession.players.size() == 3:
			break
		await wait(0.1)
	check(NetworkSession.players.size() == 3, "Three peers joined")
	if NetworkSession.players.size() != 3:
		phase("done")
		return
	var alpha: int = 0
	var beta: int = 0
	for id: int in NetworkSession.identities:
		if NetworkSession.identities[id].name == "Alpha": alpha = id
		if NetworkSession.identities[id].name == "Beta": beta = id
	var a: InventoryService = NetworkSession.services[alpha]
	var b: InventoryService = NetworkSession.services[beta]
	var ship: Node2D = NetworkSession.ship
	a.player.position = Vector2(-30, 90)
	await wait(0.4)
	phase("move")
	await wait(0.9)
	check(a.player.position.x > -10, "Client movement input advances server-owned player")
	a.player.position = a.storage_position
	b.player.position = b.storage_position
	VoyageState.get_ship_storage().restore([]) # Isolate the chest race from starter fuel.
	VoyageState.get_ship_storage().try_add(&"fish_cod") if VoyageState.get_ship_storage().has_method("try_add") else VoyageState.get_ship_storage().add_items(ItemDatabase.get_item(&"fish_cod"), 1)
	await wait(0.5)
	phase("chest")
	await wait(1)
	check(a.hud.storage_open and b.hud.storage_open, "Both clients can view chest")
	phase("race")
	await wait(1)
	check(a.inventory.get_quantity(&"fish_cod") + b.inventory.get_quantity(&"fish_cod") == 1, "Contended chest item awarded exactly once")
	check(VoyageState.get_ship_storage().capture()[0].is_empty(), "Shared chest emptied consistently")
	a.hud.close()
	b.hud.close()
	var grill: ShipGrill = ship.get_node("Cooking")
	a.player.position = grill.position + Vector2(-16, 12)
	b.player.position = grill.position + Vector2(-16, 12)
	a.inventory.try_add(&"fish_cod", 1)
	a.inventory.try_add(&"wood", 1)
	await wait(0.4)
	phase("grill_open")
	await wait(0.6)
	check(a.hud.grill_open and b.hud.grill_open, "Both clients open the same grill")
	phase("grill_place")
	await wait(0.8)
	check(grill.fish.size() == 1, "Client drag places authoritative fish")
	phase("grill_fuel")
	await wait(0.8)
	check(grill.cooking(), "Client fuel starts shared cooking")
	grill.advance(8)
	await wait(0.4)
	phase("grill_inspect")
	await wait(0.6)
	phase("grill_collect")
	await wait(0.8)
	check(grill.fish.is_empty() and a.inventory.get_quantity(&"dried_fish") + b.inventory.get_quantity(&"dried_fish") == 1, "Two clients collecting one fish receive exactly one meal")
	a.inventory.try_remove(&"dried_fish", 1)
	b.inventory.try_remove(&"dried_fish", 1)
	a.hud.close()
	b.hud.close()
	b.player.position = Vector2(-25, 120)
	await wait(0.5)
	phase("drop")
	await wait(1)
	check(a.drops.size() == 1 and a.inventory.get_quantity(&"fishing_rod") == 0, "Client drop removes one canonical item")
	phase("inspect_drop")
	await wait(0.6)
	b.player.position = a.player.position
	await wait(0.5)
	check(a.drops.is_empty() and b.inventory.get_quantity(&"fishing_rod") == 2, "Other client picks up shared dropped rod")
	# Station contention.
	a.player.position = ship.get_node("Helm").position
	b.player.position = a.player.position
	await wait(0.4)
	phase("helm")
	await wait(0.8)
	check((a.player.using_station and not b.player.using_station) or (b.player.using_station and not a.player.using_station), "Only one client owns helm")
	ship.get_node("Helm").release_control()
	# Give Alpha a rod back to test server fishing and observers.
	a.inventory.try_add(&"fishing_rod")
	a.hud.selected = 0
	b.player.position = Vector2(-25, 120)
	a.player.position = Vector2(-20, 50)
	await wait(0.5)
	phase("fish")
	await wait(0.8)
	var fish: RodFishing = a.get_node("Fishing")
	check(fish.state != RodFishing.State.IDLE, "Remote cast accepted and simulated on server")
	phase("inspect_fish")
	await wait(0.7)
	ship.global_position += Vector2(400, 250)
	ship.global_rotation = 0.4
	await wait(0.6)
	check(fish.state != RodFishing.State.IDLE, "Moving shared boat keeps client cast alive")
	var fish_before: int = a.inventory.get_quantity(&"fish_cod") + a.inventory.get_quantity(&"rope")
	phase("fight")
	for i in 250:
		if fish.state == RodFishing.State.IDLE:
			break
		await wait(0.1)
	check(a.inventory.get_quantity(&"fish_cod") + a.inventory.get_quantity(&"rope") == fish_before + 1, "Remote client wins authoritative fishing minigame and receives catch")
	fish.cancel()
	# No scene switch at island coast. Enter, walk, then re-enter water.
	a.player.set_overboard(true)
	var island: WorldIsland = ship.get_islands()[0]
	var coast := island.get_coast()
	var inside := Vector2.ZERO
	for point in coast: inside += point
	inside /= coast.size()
	a.player.global_position = inside
	ship.get_node("SwimAccess").update_crew(a.player)
	check(a.player.on_land and a.player.is_overboard, "Swimmer walks on island in the same world")
	var old_scene := get_tree().current_scene
	a.player.move_crew(Vector2.RIGHT, 0.1)
	check(a.player.global_position.distance_to(inside) > 10, "Land movement uses walking speed")
	a.player.global_position = Vector2(9000, 9000)
	ship.get_node("SwimAccess").update_crew(a.player)
	check(not a.player.on_land and old_scene == get_tree().current_scene, "Leaving island returns to swimming without a scene change")
	phase("land")
	await wait(0.6)
	PauseMenu.pause()
	check(not get_tree().paused, "Host menu does not pause the server")
	PauseMenu.resume()
	NetworkSession.save_world()
	check(FileAccess.file_exists(NetworkSession.save_path()), "Hosted voyage saved")
	var token: String = NetworkSession.identities[alpha].token
	var inventory := a.inventory.capture()
	phase("reconnect")
	await wait(3)
	var restored: InventoryService
	for id: int in NetworkSession.identities:
		if NetworkSession.identities[id].token == token and NetworkSession.services.has(id): restored = NetworkSession.services[id]
	check(restored != null and restored.inventory.capture() == inventory, "Reconnect restores inventory without duplicating starter tools")
	var survival: SurvivalWorld = ship.survival
	restored.player.set_overboard(true)
	restored.player.global_position = Vector2(1500,0)
	restored.player.swim_time = 11
	survival.damage(restored.network_id, 1)
	await wait(0.3)
	phase("survival")
	await wait(0.7)
	restored.player.set_overboard(false)
	restored.player.position=Vector2(0,70)
	restored.inventory.restore([])
	restored.inventory.try_add(&"fish_cod",1)
	restored.hud.selected=0
	restored.player.hunger=11
	await wait(0.3)
	phase("eat")
	await wait(0.7)
	check(restored.player.hunger==12 and restored.inventory.get_quantity(&"fish_cod")==0,"Guest eating is host-authoritative")
	survival.damage(restored.network_id, 15)
	check(restored.player.health == 0, "Guest waits for respawn")
	NetworkSession._handle_command(restored.network_id, "respawn", {})
	check(restored.player.health == 15 and not restored.player.is_overboard, "Host respawns dead guest")
	check(restored.inventory.capture().all(func(slot): return slot.is_empty()), "Guest death destroys inventory")
	phase("done")
	await wait(0.6)
func client_tests() -> void:
	var rejoined := false
	for i in 1300:
		await wait(0.05)
		var current := read_phase()
		if current == last_phase or current.is_empty():
			continue
		last_phase = current
		if current == "done": return
		if not NetworkSession.services.has(NetworkSession.local_id):
			check(false, "Local crew available in phase " + current)
			continue
		var service: InventoryService = NetworkSession.services[NetworkSession.local_id]
		match current:
			"eat":
				if role=="Alpha": NetworkSession.command("eat",{"index":0,"revision":service.view_revision})
			"survival":
				check(NetworkSession.ship.get_islands().size() == 30, "Guest has randomized world")
				check(NetworkSession.ship.world_seed == int(NetworkSession._last_snapshot.seed), "Guest shares host seed")
				check(NetworkSession.ship.survival.sharks.any(func(shark): return shark.active), "Guests see host sharks")
				if role == "Alpha": check(service.player.health == 14, "Guest receives third-heart damage")
			"move":
				if role == "Alpha":
					var before: Vector2 = service.player.position
					NetworkSession._predict_local(Vector2.RIGHT, 1.0 / 60.0)
					check(service.player.position.x > before.x, "Local movement responds before a host snapshot")
					Input.action_press("move_right")
					await wait(0.3)
					Input.action_release("move_right")
			"chest":
				check(NetworkSession.players.size() == 3, "Late join sees entire crew")
				NetworkSession.command("interact")
			"race":
				NetworkSession.command("transfer", {"action": "take", "index": 0, "revision": service.view_revision})
			"grill_open": NetworkSession.command("interact")
			"grill_place", "grill_fuel":
				if role == "Alpha":
					var item := &"fish_cod" if current == "grill_place" else &"wood"
					for slot in service.local_slots.size():
						if service.local_slots[slot].get("id") == item:
							NetworkSession.command("grill", {"action": "fish" if current == "grill_place" else "fuel", "index": slot, "revision": service.view_revision, "point": Vector2(0.3, 0.4)})
							break
			"grill_inspect":
				var grill: ShipGrill = NetworkSession.ship.get_node("Cooking")
				check(grill.fish.size() == 1 and grill.fish[0].progress >= grill.cook_seconds, "Shared grill progress reaches both clients")
				if not grill.fish.is_empty():
					shared_grill_key = grill.fish[0].key
			"grill_collect":
				NetworkSession.command("grill", {"action": "collect", "key": shared_grill_key})
			"drop":
				if role == "Alpha":
					NetworkSession.command("drag", {"index": 0, "storage": false, "destination": -1, "revision": service.view_revision})
			"inspect_drop": check(service.drops.size() == 1, "Dropped item visible to each client")
			"helm": NetworkSession.command("interact")
			"fish":
				if role == "Alpha":
					NetworkSession.command("fish", {"point": service.player.global_position + Vector2(230, 0)})
			"inspect_fish":
				var found := false
				for value in NetworkSession.services.values():
					if value.get_node("Fishing").state != RodFishing.State.IDLE: found = true
				check(found, "Other players receive rod and bobber state")
				if "--capture" in OS.get_cmdline_user_args():
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png("res://.godot/network-" + role + ".png")
			"fight":
				if role == "Alpha":
					var hooked := false
					for frame in 500:
						await wait(0.05)
						var fishing: RodFishing = service.get_node("Fishing")
						if fishing.state == RodFishing.State.BITE and not hooked:
							hooked = true
							NetworkSession.command("fish")
							check(fishing.local_reeling, "Hook starts locally without awaiting host")
							var tension_before := fishing.fight.tension
							fishing.tick_local_fight(1.0 / 60.0)
							check(fishing.fight.tension > tension_before, "Reel responds on the local frame")
						elif fishing.state == RodFishing.State.REELING:
							var event := InputEventMouseButton.new()
							event.button_index = MOUSE_BUTTON_LEFT
							event.position = Vector2(1000, 300)
							event.pressed = fishing.fight.tension < fishing.fight.green_center
							Input.parse_input_event(event)
						elif hooked and fishing.state == RodFishing.State.IDLE:
							break
					var release := InputEventMouseButton.new()
					release.button_index = MOUSE_BUTTON_LEFT
					release.pressed = false
					Input.parse_input_event(release)
			"land":
				await wait(0.3)
				var found := false
				for player in NetworkSession.players.values():
					if player.is_overboard: found = true
				check(found, "Off-ship positions synchronized")
			"reconnect":
				if role == "Alpha" and not rejoined:
					rejoined = true
					NetworkSession.leave()
					await wait(0.4)
					await join_test()
	check(false, "Test timed out")
