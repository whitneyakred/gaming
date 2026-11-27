extends Node
var failures := 0
var role := ""
func _ready() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(role + ": " + label)
	else: print(role + " PASS " + label)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
func phase(value: String) -> void:
	var f := FileAccess.open("res://.godot/independent-chest-phase-v2.txt", FileAccess.WRITE)
	f.store_string(value)
func read_phase() -> String:
	return FileAccess.get_file_as_string("res://.godot/independent-chest-phase-v2.txt")
func run() -> void:
	get_tree().create_timer(45).timeout.connect(func(): get_tree().quit(9))
	GameWindow.set_preference("pause_unfocused", false)
	role = "host" if "--chest-host" in OS.get_cmdline_user_args() else "client"
	VoyageSaves.selected = 2
	if VoyageSaves.path(2) != "res://.godot/test-save-slot-2.save":
		push_error("Refusing to run against real saves")
		get_tree().quit(8)
		return
	if role == "host":
		phase("")
		VoyageSaves.clear_slot(2)
		NetworkSession.host_session("Chest Captain", 24689, "chest", false)
		for i in 100:
			if NetworkSession.players.size() == 2: break
			await wait(0.1)
		check(NetworkSession.players.size() == 2, "two real peers connected")
		if NetworkSession.players.size() != 2: get_tree().quit(1); return
		var guest_id: int = 0
		for id in NetworkSession.services:
			if id != 1: guest_id = id
		var captain = NetworkSession.services[1]
		var guest = NetworkSession.services[guest_id]
		captain.player.position = captain.storage_position + Vector2(-22, 0)
		guest.player.position = guest.second_storage_position + Vector2(22, 0)
		VoyageState.get_ship_storage().restore([])
		VoyageState.get_ship_storage(18, 1).restore([])
		VoyageState.get_ship_storage().add_items(ItemDatabase.get_item(&"wood"), 7)
		VoyageState.get_ship_storage(18, 1).add_items(ItemDatabase.get_item(&"coal"), 5)
		var empty_slots: Array[Dictionary] = [{}, {}, {}, {}]
		captain.inventory.restore(empty_slots)
		guest.inventory.restore(empty_slots)
		await wait(0.7)
		NetworkSession.command("interact")
		phase("open")
		await wait(1)
		check(captain.hud.storage_open and guest.hud.storage_open, "both players open separate chests simultaneously")
		check(captain.active_chest_id == 0 and guest.active_chest_id == 1, "server selects distinct chest IDs")
		NetworkSession.command("transfer", {"action":"take", "index":0,"revision":captain.view_revision})
		phase("take")
		await wait(1)
		check(captain.inventory.get_quantity(&"wood") == 7, "captain receives only right chest wood")
		check(guest.inventory.get_quantity(&"coal") == 5, "guest receives only left chest coal")
		check(captain.inventory.get_quantity(&"coal") == 0 and guest.inventory.get_quantity(&"wood") == 0, "no cross-chest transfer")
		NetworkSession.command("transfer", {"action":"store", "index":0,"revision":captain.view_revision})
		phase("store")
		await wait(1)
		check(VoyageState.get_ship_storage().capture()[0].quantity == 7, "right chest refilled")
		check(VoyageState.get_ship_storage(18,1).capture()[0].quantity == 5, "left chest refilled")
		NetworkSession.command("interact")
		await wait(0.5)
		check(not captain.hud.storage_open and guest.hud.storage_open, "closing right leaves left open")
		phase("verify")
		await wait(1)
		NetworkSession.save_world()
		var saved := VoyageSaves.world(2)
		check(saved.storage[0].quantity == 7 and saved.port_storage[0].quantity == 5, "both inventories written to actual save file")
		captain.hud.close()
		guest.hud.close()
		guest.player.position = Vector2(3, -143)
		guest.inventory.clear()
		guest.inventory.try_add(&"wood", 3)
		guest.inventory.try_add(&"stone", 2)
		await wait(0.7)
		phase("craft_open")
		await wait(0.7)
		check(guest.hud.crafting_open, "guest opens bow workbench on host")
		phase("craft_axe")
		await wait(0.7)
		check(guest.inventory.get_quantity(&"axe") == 1 and guest.inventory.get_quantity(&"wood") == 0, "host crafts guest axe and consumes ingredients")
		guest.inventory.wear(0, 7)
		await wait(0.7)
		phase("craft_verify")
		await wait(0.7)
		phase("done")
		await wait(0.8)
		NetworkSession.leave()
		await wait(0.5)
		NetworkSession.host_session("Chest Captain", 24689, "chest", true)
		for i in 60:
			if NetworkSession.world_ready: break
			await wait(0.1)
		check(VoyageState.get_ship_storage().capture()[0].get("quantity") == 7, "right inventory restored after hosting saved voyage")
		check(VoyageState.get_ship_storage(18,1).capture()[0].get("quantity") == 5, "left inventory restored after hosting saved voyage")
	else:
		await wait(0.8)
		NetworkSession.join_session("127.0.0.1", 24689, "Chest Guest", "chest")
		var last := ""
		while true:
			await wait(0.1)
			var current := read_phase()
			if current == last: continue
			last = current
			if current == "done": break
			if not NetworkSession.services.has(NetworkSession.local_id): continue
			var service = NetworkSession.services[NetworkSession.local_id]
			match current:
				"craft_open": NetworkSession.command("interact")
				"craft_axe":
					check(service.hud.crafting_open, "guest receives crafting panel state")
					NetworkSession.command("craft", {"action":"axe", "revision":service.view_revision})
				"craft_verify":
					check(service.local_slots[0].get("id") == &"axe" and service.local_slots[0].get("durability") == 23, "guest receives crafted tool durability")
				"open": NetworkSession.command("interact")
				"take":
					check(service.active_chest_id == 1 and service.storage_view[0].id == &"coal", "client sees left contents")
					NetworkSession.command("transfer", {"action":"take","index":0,"revision":service.view_revision})
				"store": NetworkSession.command("transfer", {"action":"store","index":0,"revision":service.view_revision})
				"verify":
					var art = service.get_node("DeckItems")
					check(art.chest_texture(0) == art.closed_chest_texture and art.chest_texture(1) == art.open_chest_texture, "replicated lids independently open and close")
	print("CHEST MULTIPLAYER ", role, ": ", failures, " failures")
	NetworkSession.leave()
	await wait(0.2)
	GameWindow.shutdown_audio()
	await wait(0.1)
	get_tree().quit(failures)





