extends Node
var main: Node
var service: Node
var disconnects: int = 0
var elapsed: float = 0.0
var host: bool = false
var done: bool = false

func _ready() -> void:
	call_deferred("run")

func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 25.0:
		fail("Network inventory test timed out")
	if host and main != null:
		# Place test crew at the chest on the authoritative host.
		for id: int in main.players:
			main.players[id].position = Vector2(-70, -90) if id == 1 else service.storage_position

func run() -> void:
	var args := OS.get_cmdline_user_args()
	host = "--inventory-host" in args
	main = preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	service = main.get_node("InventorySystem")
	main.port = 19081
	if host:
		main.multiplayer.peer_disconnected.connect(func(_id: int): disconnects += 1)
		main.host_game()
		while disconnects < 2:
			await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		if service.drops.size() != 1 or service.drops.values()[0].quantity != 8:
			fail("Disconnect must preserve exactly eight fish on deck")
			return
		if not service.storage.slots[0].is_empty():
			fail("Chest must not duplicate taken fish")
			return
		print("INVENTORY NETWORK HOST: PASS")
		main.end_session("Done")
		get_tree().quit()
		return
	main.join_game("ws://127.0.0.1:19081")
	while not main.running or service.local_slots.is_empty() or not service.near_storage(multiplayer.get_unique_id()):
		await get_tree().process_frame
	if "--late" in args:
		if not service.storage_view[0].is_empty() or (service.drops_view.is_empty() and service.local_slots[0].get("id") != &"fish_cod"):
			fail("Late join did not receive current chest and deck state")
			return
	else:
		service.request_drag({"index": 0, "storage": true, "revision": service.view_revision}, 3, false)
		while service.local_slots[3].is_empty():
			await get_tree().process_frame
		await get_tree().create_timer(0.15).timeout
		service.request_drag({"index": 3, "storage": false, "revision": service.view_revision}, 0, false)
	while service.local_slots[0].is_empty():
		await get_tree().process_frame
	if service.local_slots[0].id != &"fish_cod" or service.local_slots[0].quantity != 8:
		fail("Client did not receive authoritative fish stack")
		return
	await get_tree().create_timer(0.2).timeout
	if "--late" not in args:
		service.request_drag({"index": 0, "storage": false, "revision": service.view_revision})
		while service.drops_view.is_empty() or not service.local_slots[0].is_empty():
			await get_tree().process_frame
		await get_tree().create_timer(2.0).timeout
		if not service.local_slots[0].is_empty() or service.drops_view.size() != 1:
			fail("Waiting inside the trigger must not reabsorb dropped items")
			return
	print("INVENTORY NETWORK CLIENT: PASS ", "late join + pickup" if "--late" in args else "take + drop")
	main.end_session("Done")
	get_tree().quit()
