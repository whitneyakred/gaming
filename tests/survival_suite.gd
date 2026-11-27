extends Node
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	GameWindow.set_preference("fullscreen",false)
	GameWindow.set_preference("pause_unfocused",false)
	VoyageState.reset()
	MapState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	await get_tree().process_frame
	var ship: Ship = get_tree().current_scene.get_node("Ship")
	var world := ship.survival
	world.set_physics_process(false)
	var player := ship.player
	var service: InventoryService = ship.get_node("InventorySystem")
	check(ship.get_islands().size() == 34,"Thirty ordinary plus four quest islands")
	check(MapState.island_catalog.size() == 34,"All unknown island locations are mapped")
	var first := ship.get_islands()[0].position
	var seed_value := ship.world_seed
	ship.rebuild_world(seed_value+1)
	check(ship.get_islands()[0].position != first,"Different worlds have different positions")
	ship.rebuild_world(seed_value)
	check(ship.get_islands()[0].position == first,"Seed restores identical positions")
	for island in ship.get_islands():
		check(not WorldLayout.danger(island.position) and island.position.length()>2000,"Island avoids boundary and spawn")
	player.fishing_active = true
	var old := player.position
	player.move_crew(Vector2.RIGHT,0.1)
	check(player.position != old,"Fishing allows deck movement")
	player.position = ship.get_node("SwimAccess").plank_end
	ship.get_node("SwimAccess").update_crew(player)
	check(player.is_overboard,"Fishing does not block water entry")
	check(not service.get_node("Fishing").can_fish(),"Swimming invalidates fishing")
	player.fishing_active = false
	player.global_position = Vector2(1500,0)
	world.advance(3.9)
	check(not world.sharks[0].active,"No sharks before four seconds")
	world.advance(4.2)
	check(world.sharks.size()==2 and world.sharks[0].active,"Two shared sharks engage by eight seconds")
	player.update_land(true)
	world.advance(0.1)
	check(world.sharks[0].target == 0,"Sharks stop attacking on land")
	player.update_land(false)
	player.swim_time = 0.0
	world.advance_sharks(0.01,world.crew())
	check(world.sharks[0].target == 1,"Lingering sharks immediately re-engage returning swimmer")
	player.global_position = Vector2(MapState.world_bounds.end.x-500.0,0)
	world.advance(14.9)
	check(player.is_overboard,"Red water allows escape before fifteen seconds")
	world.advance(0.2)
	check(player.health==0,"Red water death waits for respawn")
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/death-screen.png")
	world.respawn(1)
	check(player.player_inventory.get_quantity(&"fishing_rod")==0,"Death loses carried items")
	var storage := VoyageState.get_ship_storage()
	storage.add_items(ItemDatabase.get_item(&"wood"),3)
	ship.global_position = Vector2(MapState.world_bounds.end.x-500.0,0)
	player.position = Vector2.ZERO
	world.advance(15)
	check(ship.global_position==Vector2.ZERO and ship.anchor_deployed,"Sunken ship returns safely to origin")
	check(player.is_overboard and player.global_position.x>MapState.world_bounds.end.x-1000.0,"Passengers remain swimming where ship sank")
	check(storage.capture().all(func(slot): return slot.is_empty()),"Sinking empties ship chest")
	check(ship.get_node("Cooking").fish.is_empty() and ship.get_node("Cooking").starter_granted,"Sinking clears grill without regranting fuel")
	world.respawn(1)
	world.damage(1,1)
	check(player.health==14 and player.hunger==15,"Third-heart damage and static hunger")
	world.damage(1,14)
	check(player.health==0,"Lethal damage waits for respawn")
	world.respawn(1)
	player.velocity = Vector2.ZERO
	player.hunger = 10
	player.hunger_clock = 0
	world.advance_metabolism(1,100)
	check(player.hunger==9,"Idle hunger loses one third in 100 seconds")
	player.velocity=Vector2(145,0)
	world.advance_metabolism(1,75)
	check(player.hunger==8,"Walking hunger drains gently faster")
	player.set_overboard(true)
	player.update_land(false)
	world.advance_metabolism(1,38)
	check(player.hunger==7,"Swimming drains one third in 38 seconds")
	player.set_overboard(false)
	player.velocity=Vector2.ZERO
	player.hunger=0
	player.health=15
	player.starvation_clock=0
	world.advance_metabolism(1,1.9)
	check(player.health==15,"Starvation waits two seconds")
	world.advance_metabolism(1,0.1)
	check(player.health==14,"Starvation damages every two seconds")
	player.hunger=15
	player.hunger_clock=0
	player.regen_clock=0
	world.advance_metabolism(1,12)
	check(player.health==15,"Full hunger regenerates slowly")
	player.health=9
	player.regen_clock=0
	world.advance_metabolism(1,12)
	check(player.health==10,"Regeneration restores exactly one third of a heart")
	player.health=10
	player.hunger=14
	world.advance_metabolism(1,12)
	check(player.health==10,"Partial hunger cannot regenerate")
	var empty_food: Array[Dictionary] = []
	player.player_inventory.restore(empty_food)
	player.player_inventory.try_add(&"fish_cod",2)
	service.hud.selected=0
	player.hunger=10
	var eating = service.get_node("Eating")
	eating.start()
	check(player.player_inventory.get_quantity(&"fish_cod")==2 and player.hunger==10,"Starting a hold does not consume food")
	eating._process(0.1)
	check(not eating.active and player.player_inventory.get_quantity(&"fish_cod")==2,"Releasing early cancels eating without consuming")
	check(world.eat(1,0) and player.hunger==11,"Raw fish restores one third")
	check(not world.eat(1,0),"Eating cooldown prevents rapid consumption")
	player.eat_cooldown=0
	player.player_inventory.restore(empty_food)
	player.player_inventory.try_add(&"dried_fish",2)
	check(world.eat(1,0) and player.hunger==14,"Cooked fish restores a full icon")
	player.eat_cooldown=0
	player.hunger=15
	check(not world.eat(1,0) and player.player_inventory.get_quantity(&"dried_fish")==1,"Full hunger does not waste fish")
	var scope: SpyglassController=service.get_node("Spyglass")
	scope._previous_camera=get_viewport().get_camera_2d()
	scope._blend=1
	scope.active=false
	scope._previous_camera.global_position+=Vector2(200,100)
	scope._update_view(scope.zoom_seconds)
	check(scope._scope_camera.global_position.is_equal_approx(scope._previous_camera.global_position+scope._previous_camera.offset),"Spyglass returns to current camera position")
	player.set_overboard(true)
	# Test the attack cycle outside every obstacle's bounds. Sampling rings can
	# miss coastlines between samples, and the old search could find no candidate.
	# Only advance_sharks runs here, so boundary-water metabolism is independent.
	var right_edge := ship.global_position.x
	for point in ship.get_hull_polygon(ship.global_position, ship.global_rotation):
		right_edge = maxf(right_edge, point.x)
	for island in ship.get_islands():
		for point in island.get_coast():
			right_edge = maxf(right_edge, point.x)
	player.global_position = Vector2(right_edge + 2400, 0)
	player.velocity = Vector2.ZERO
	player.update_land(false)
	player.swim_time=11
	# Earlier cases exercised death, departure and teleporting. Start both
	# attackers fresh so neither carries a previous target or navigation route.
	for shark in world.sharks:
		shark.active=false
		shark.target=0
		shark.alpha=0
	world.routes.clear()
	world.route_timers.clear()
	world.advance_sharks(1.0/60.0,world.crew())
	var arena := Rect2(player.global_position - Vector2.ONE * 2000, Vector2.ONE * 4000)
	check(world.navigation.bounds.all(func(bound): return not bound.intersects(arena)),"Shark attack arena excludes every island and the hull")
	check(Vector2(world.sharks[0].position).distance_to(player.global_position)>350 and world.sharks[0].alpha<0.1,"Shark arrives nearby with fade-in")
	var modes := {}
	var hurt_before: int=player.hurt_serial
	for frame in 2400:
		world.advance_sharks(1.0/60.0,world.crew())
		modes[world.sharks[0].mode]=true
	check(modes.has("circle") and modes.has("dive") and modes.has("lunge") and modes.has("retreat"),"Shark circles, dives, lunges and retreats (seed=%s, modes=%s)" % [seed_value, modes.keys()])
	check(player.hurt_serial>hurt_before,"Lunging shark can damage its target")
	world.respawn(1)
	player.player_inventory.try_add(&"spyglass")
	player.health = 11
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/survival-hud.png")
		MapState.map_open = true
		ship.get_node("MapUI").show()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/survival-map.png")
	# Death loot uses the actual death surface, never the nearby boat.
	service.drops.clear()
	world.respawn(1)
	var death_bag: Array[Dictionary] = [{"id":&"coal","quantity":3},{"id":&"bronze_key","quantity":1}]
	player.player_inventory.restore(death_bag)
	VoyageState.paradise_quest["bronze_seals"] = 3
	VoyageState.reconcile_keys()
	var deck_position := player.position
	world.damage(1,15)
	check(service.drops.size()==2 and service.drops.values().all(func(e): return not e.world and e.position==deck_position),"Deck death drops every carried stack in ship coordinates")
	check(player.player_inventory.get_quantity(&"coal")==0 and VoyageState.has_key("bronze"),"Ground key stays claimed while dead bag is empty")
	world.damage(1,15)
	check(service.drops.size()==2,"Repeated death damage cannot duplicate drops")
	world.respawn(1)
	check(service.drops.size()==2,"Respawn preserves death loot")
	service.drops.clear()
	var island := ship.get_islands()[0]
	var coast := island.get_coast()
	var shore := Vector2.ZERO
	var water := Vector2.ZERO
	var located := false
	for i in coast.size():
		var middle := (coast[i]+coast[(i+1)%coast.size()])*0.5
		var normal := (coast[(i+1)%coast.size()]-coast[i]).normalized().orthogonal()
		for side in [-1.0,1.0]:
			var inside: Vector2 = middle+normal*12.0*side
			var outside: Vector2 = middle-normal*60.0*side
			if Geometry2D.is_point_in_polygon(inside,coast) and not Geometry2D.is_point_in_polygon(outside,coast):
				shore=inside; water=outside; located=true; break
		if located: break
	check(located,"Test finds real coastline with water and safe interior")
	player.set_overboard(true)
	player.update_land(true)
	player.global_position=shore
	death_bag = [{"id":&"silver_key","quantity":1},{"id":&"rope","quantity":2}]
	player.player_inventory.restore(death_bag)
	world.damage(1,15)
	check(service.drops.size()==2 and service.drops.values().all(func(e): return e.world and e.position==shore),"Shore death drops items exactly on land")
	check(VoyageState.has_key("silver"),"Island-floor key cannot respawn a duplicate")
	service.drops.clear()
	world.respawn(1)
	player.set_overboard(true)
	player.update_land(false)
	player.global_position=water
	death_bag = [{"id":&"gold_key","quantity":1},{"id":&"coal","quantity":2}]
	player.player_inventory.restore(death_bag)
	world.damage(1,15)
	check(service.drops.size()==2 and service.drops.values().all(func(e): return e.world and Geometry2D.is_point_in_polygon(e.position,coast)),"Near-shore drowning places all items inside island coastline")
	service.drops.clear()
	world.respawn(1)
	player.set_overboard(true)
	player.update_land(false)
	player.global_position=ship.to_global(Vector2(250,0))
	death_bag = [{"id":&"bronze_key","quantity":1},{"id":&"coal","quantity":3}]
	player.player_inventory.restore(death_bag)
	VoyageState.reconcile_keys()
	world.damage(1,15)
	check(service.drops.is_empty() and player.player_inventory.get_quantity(&"coal")==0,"Drowning near boat but far from land loses loot without deck drops")
	check(not VoyageState.has_key("bronze") and VoyageState.paradise_quest.bronze_seals==3,"Lost sea key returns to solved pedestal")
	world.respawn(1)
	check(VoyageState.grant_key("bronze",player.player_inventory),"Returned key can be collected again")
	GameWindow.shutdown_audio()
	for voice in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		voice.stop()
		voice.stream = null
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	print("SURVIVAL: ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

