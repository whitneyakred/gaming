extends Node
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	for i in 8: await get_tree().physics_frame
	var ship := get_tree().current_scene as Ship
	var crew := ship.player
	var journey := ship.get_node("ParadiseJourney") as ParadiseJourney
	var dev := ship.get_node("VoyageDevMenu")
	var inventory_before: Array = crew.player_inventory.capture()
	var walk_before: float = crew.walk_speed
	var swim_before: float = crew.swim_speed
	dev.speed_buttons.walk_speed.button_pressed = true
	dev.speed_buttons.swim_speed.button_pressed = true
	check(crew.walk_speed == walk_before * 8 and crew.swim_speed == swim_before * 8, "Speed buttons enable 8x walking and swimming")
	dev.speed_buttons.walk_speed.button_pressed = false
	check(crew.walk_speed == walk_before and crew.swim_speed == swim_before * 8, "Walking and swimming toggles are independent")
	for target in ["nearest", "Paradise", "Key_bronze", "Key_silver", "Key_gold", "random"]:
		crew.set_overboard(true)
		crew.update_land(true)
		check(dev.teleport(target), "Dev teleport succeeds: " + target)
		check(not crew.is_overboard and crew.position == Vector2(0, 70), "Teleport returns sailor aboard")
		check(not ship._is_pose_blocked(ship.global_position, ship.global_rotation), "Teleport hull is clear of all land")
		check(ship.anchor_deployed and ship.speed == 0 and ship.sail_level == 0, "Teleport stops and anchors ship")
	check(crew.player_inventory.capture() == inventory_before, "Teleport preserves inventory")
	ship.developer_tools_enabled = false
	var before_disabled: Vector2 = ship.global_position
	check(not dev.teleport("Paradise") and ship.global_position == before_disabled, "Inspector toggle disables teleport actions")
	dev._process(0)
	check(crew.walk_speed == walk_before and crew.swim_speed == swim_before, "Disabling dev tools restores normal speeds")
	check(not dev.panel.visible, "Inspector toggle hides menu")
	ship.developer_tools_enabled = true
	MapState.discovered_islands.clear()
	check(ship.get_islands().size() == 34, "30 ordinary islands plus four quest islands")
	check(MapState.has_paradise_position and MapState.paradise_position == Vector2(0, -9900), "Paradise marked north center from start")
	check(not VoyageState.open_paradise() and not VoyageState.complete_voyage(), "Cannot unlock or finish without keys")
	var paradise := ship.get_island(&"Paradise") as QuestIsland
	check(paradise.blocks_path(paradise.to_global(Vector2(0, 250)), paradise.to_global(Vector2(0, 170))), "Closed gate blocks entrance")
	check(paradise.blocks_path(paradise.to_global(Vector2(-260, 0)), paradise.to_global(Vector2(-190, 0))), "Side approach cannot bypass gate")
	crew.set_overboard(true)
	crew.update_land(true)
	crew.global_position = paradise.to_global(Vector2(0, 250))
	var outside: Vector2 = crew.global_position
	crew.move_crew(Vector2.UP, 0.6)
	check(crew.global_position == outside, "Actual player movement cannot cross closed gate")
	crew.player_inventory.clear()
	for region in MapState.key_regions:
		var island := ship.get_island(StringName(region.island)) as QuestIsland
		check(island.position.distance_to(region.center) < region.radius - island.radius.x, "Whole key island lies inside search circle")
		check(island.get_coast().size() == 48, "Quest island has navigable coastline")
		check(not MapState.discovered_islands.has(region.island), "Exact key location initially hidden")
		crew.global_position = island.global_position
		journey.interact(crew)
		check(not VoyageState.has_key(region.key), "Pedestal cannot award key before seals")
		crew.global_position = island.to_global(QuestIsland.SEALS[2])
		journey.interact(crew)
		check(island.seal_count() == 0, "Wrong first seal rejected")
		for point in QuestIsland.SEALS:
			crew.global_position = island.to_global(point)
			journey.interact(crew)
		check(island.seal_count() == 3, "Three seals complete encounter")
		crew.global_position = island.global_position
		journey.interact(crew)
		check(VoyageState.has_key(region.key), "Earned key is permanent voyage progress")
		check(not VoyageState.grant_key(region.key), "Duplicate award harmless")
	for key in VoyageState.KEY_IDS:
		check(crew.player_inventory.get_quantity(StringName(key + "_key")) == 1, "Key occupies a real inventory slot")
	var clues := 0
	for island in ship.get_islands():
		for child in island.get_children():
			if child is QuestClue:
				clues += 1
				check(Geometry2D.is_point_in_polygon(child.global_position, island.get_coast()), "Clue is on accessible land")
				crew.global_position = child.global_position
				journey.interact(crew)
				check(MapState.discovered_islands.has("Key_" + child.key_id), "Clue reveals exact key location")
	check(clues == 3, "One clue per key region")
	var service := ship.get_node("InventorySystem") as InventoryService
	var bag: PlayerInventory = crew.player_inventory
	var bronze := ship.get_island(&"Key_bronze") as QuestIsland
	check(not VoyageState.grant_key("bronze", bag), "Cannot duplicate carried key")
	var bronze_slot := -1
	for index in bag.slots.size():
		if bag.slots[index].get("id", &"") == &"bronze_key": bronze_slot = index
	service.request_drag({"service_id": service.get_instance_id(), "revision": service.view_revision, "index": bronze_slot})
	check(bag.get_quantity(&"bronze_key") == 0 and service.drops.size() == 1, "Key uses normal drag-to-ground drop")
	check(not VoyageState.grant_key("bronze", bag), "Ground key blocks duplicate reward")
	var drop_id: int = service.drops.keys()[0]
	service.pickup_inside[drop_id] = false
	service.server_pickups()
	check(bag.get_quantity(&"bronze_key") == 1 and service.drops.is_empty(), "Ground key is picked up through ordinary inventory system")
	for index in bag.slots.size():
		if bag.slots[index].get("id", &"") == &"bronze_key": bronze_slot = index
	service.request_drag({"service_id": service.get_instance_id(), "revision": service.view_revision, "index": bronze_slot})
	drop_id = service.drops.keys()[0]
	VoyageState.advance_ground_items(299)
	check(service.drops.has(drop_id), "Ground item remains before five minutes")
	VoyageState.advance_ground_items(1)
	VoyageState.reconcile_keys()
	check(service.drops.is_empty() and not VoyageState.has_key("bronze"), "Expired key returns to sanctuary")
	check(not service.pickup_inside.has(drop_id), "Expiry clears pickup bookkeeping")
	bag.try_add(&"fishing_rod")
	bag.try_add(&"spyglass")
	check(not VoyageState.grant_key("bronze", bag) and not VoyageState.has_key("bronze"), "Full bag leaves key at its pedestal")
	bag.try_remove(&"fishing_rod")
	bag.try_remove(&"spyglass")
	crew.global_position = bronze.global_position
	journey.interact(crew)
	check(bag.get_quantity(&"bronze_key") == 1, "Returned key can be reclaimed without replaying seals")
	var chest := VoyageState.get_ship_storage()
	for index in bag.slots.size():
		if bag.slots[index].get("id", &"") == &"silver_key": bag.transfer_to(index, chest)
	VoyageState.reconcile_keys()
	check(not VoyageState.grant_key("silver", bag), "Chest key blocks duplicate reward")
	ship.survival.damage(1, 15)
	VoyageState.reconcile_keys()
	check(not VoyageState.has_key("bronze") and not VoyageState.has_key("gold") and VoyageState.has_key("silver"), "Death returns carried keys but preserves stored key")
	ship.survival.respawn(1)
	for index in chest.slots.size():
		if chest.slots[index].get("id", &"") == &"silver_key": chest.transfer_to(index, bag)
	check(not VoyageState.open_paradise(bag), "One key inserts without opening gate")
	check(bag.get_quantity(&"silver_key") == 0 and VoyageState.paradise_quest.get("silver_inserted", false), "Inserted key leaves bag and fills gate")
	check(not VoyageState.grant_key("silver", bag), "Inserted key cannot be duplicated")
	for key in ["bronze", "gold"]: check(VoyageState.grant_key(key, bag), "Lost key can be issued again")
	service._spawn_drop({"id": &"wood", "quantity": 1}, crew.position)
	VoyageState.advance_ground_items(300)
	check(service.drops.is_empty(), "Ordinary ground items also expire after five minutes")
	crew.set_overboard(true)
	crew.update_land(true)
	crew.global_position = paradise.to_global(QuestIsland.GATE + Vector2(0, 50))
	check(journey.interact(crew) and VoyageState.paradise_quest.get("gate_open", false), "All three keys unlock gate")
	check(not paradise.blocks_path(paradise.to_global(Vector2(0, 250)), paradise.to_global(Vector2(0, 170))), "Open gate allows entrance")
	check(paradise.blocks_path(paradise.to_global(Vector2(-260, 0)), paradise.to_global(Vector2(-190, 0))), "Sanctuary side walls remain solid")
	check(not VoyageState.paradise_quest.get("complete", false), "Unlocking alone does not finish voyage")
	crew.global_position = paradise.to_global(QuestIsland.BEACON)
	journey.interact(crew)
	check(VoyageState.paradise_quest.get("complete", false), "Beacon completes voyage")
	var saved := VoyageState.quest_data()
	ship.survival.damage(1, 15)
	ship.survival.respawn(1)
	check(VoyageState.quest_data() == saved, "Death and respawn preserve quest progress")
	NetworkSession.online = true
	NetworkSession.local_id = 1
	NetworkSession.ship = ship
	NetworkSession.world_ready = true
	NetworkSession.save_world()
	NetworkSession.online = false
	NetworkSession.world_ready = false
	check(VoyageSaves.world(VoyageSaves.selected).get("paradise_quest", {}) == saved, "Actual voyage save includes quest progress")
	VoyageState.reset()
	check(not VoyageState.all_keys(), "New voyage clears quest progress")
	VoyageState.restore_quest(VoyageSaves.world(VoyageSaves.selected).get("paradise_quest", {}))
	check(VoyageState.quest_data() == saved, "Disk save restores keys, seals, gate and completion")
	MapState.restore_discoveries({"Island_00": {"name": "Old island", "position": Vector2(99999, 99999)}})
	check(MapState.discovered_islands.Island_00.position == MapState.island_catalog.Island_00.position, "Old discoveries use current seeded layout")
	var first_layout := {}
	for seed_value in [42, 73, 42]:
		ship.rebuild_world(seed_value)
		check(ship.get_islands().size() == 34, "Rebuilding never duplicates special islands")
		for island in ship.get_islands():
			if island is QuestIsland:
				if seed_value == 42:
					if first_layout.has(island.name): check(first_layout[island.name] == island.position, "Special positions reproduce for same seed")
					else: first_layout[island.name] = island.position
				for other in ship.get_islands():
					if other == island: continue
					check(Geometry2D.intersect_polygons(island.get_coast(), other.get_coast()).is_empty(), "Special islands never overlap ordinary islands")
	if "--capture" in OS.get_cmdline_user_args():
		ship.get_node("MapUI").open_map()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/paradise-map.png")
		ship.get_node("MapUI").close_map()
		var camera := Camera2D.new()
		ship.add_child(camera)
		camera.global_position = MapState.paradise_position
		camera.zoom = Vector2.ONE * 0.6
		camera.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/paradise-island.png")
	print("PARADISE JOURNEY: ", checks, " checks, ", failures, " failures")
	GameWindow.shutdown_audio()
	get_tree().quit(0 if failures == 0 else 1)
