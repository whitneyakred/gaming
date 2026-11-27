extends Node
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused",false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship: Ship = get_tree().current_scene.get_node("Ship")
	var field := ship.ocean_fish
	field.refresh(Vector2.ZERO)
	var point := Vector2.ZERO
	for school: Dictionary in field.schools.values():
		if school.water and FishSchool.visibility(school,field.shared_time()) > 0.8:
			point = FishSchool.pose(school,school.members[0],field.shared_time()).origin
			break
	var found := field.claim_near(point,1)
	check(not found.is_empty(),"Can hook an actual visible fish")
	var second := field.claim_near(point,2)
	check(second.is_empty() or second.id != found.id,"Two anglers cannot reserve the same fish")
	check(not field.release_fish(found.id,2,true),"Another player cannot claim catch reward")
	check(field.release_fish(found.id,1,true),"Owner can consume reserved fish")
	check(not field.release_fish(found.id,1,true),"Consumed fish cannot pay twice")
	check(field.unavailable(found.id),"Caught fish hidden on depletion cooldown")
	field.claims.clear()
	var service: InventoryService = ship.get_node("InventorySystem")
	var rod: RodFishing = service.get_node("Fishing")
	rod.set_process(false)
	check(rod.catch_mesh.multimesh.get_instance_transform_2d(0) == Transform2D.IDENTITY,"Hooked fish mesh has visible nonzero transform")
	rod.state=RodFishing.State.REELING
	var before := service.inventory.get_quantity(&"fish_cod")
	rod.finish(true)
	check(service.inventory.get_quantity(&"fish_cod")==before,"Winning without actual fish cannot fabricate loot")
	rod.state = RodFishing.State.WAITING
	rod.catch_id = found.id
	rod.catch_length = found.length
	rod.catch_angle = found.angle
	rod.catch_position = found.position
	rod.target = found.position+Vector2(80,0)
	field.claims[found.id] = 1
	rod.update_catch_visual(1.0/60)
	check(is_equal_approx(rod.catch_mesh.scale.x,float(found.length)/0.65),"Hooked fish preserves ambient size")
	var original := rod.catch_position
	rod.advance(1.0/60,false)
	check(rod.catch_position.distance_to(original)<=0.76,"Fish approach has bounded swim speed")
	rod.cancel()
	check(field.returns.has(found.id),"Escaped fish publishes smooth route return")
	var sprite: CrewSprite = service.player.idle_sprite
	sprite.refresh(0.01)
	service.player.hurt_serial += 1
	sprite.refresh(0.01)
	check(sprite.self_modulate.g < 0.5,"Replicated damage serial starts red flash")
	sprite.refresh(0.4)
	check(sprite.self_modulate == Color.WHITE,"Damage flash expires locally")
	service.player.health = 3
	service.inventory.restore([{"id":&"medpack","quantity":1},{"id":&"medpack","quantity":1},{},{}])
	service.hud.selected = 0
	check(ItemDatabase.get_item(&"medpack").max_stack == 1,"Medpacks cannot stack")
	check(ship.survival.medpack(1,"start",0),"Medpack starts with wounded player")
	check(not ship.survival.medpack(1,"finish",0),"Instant healing rejected")
	ship.survival.medpack(1,"start",0)
	ship.survival.medpack(1,"cancel",0)
	check(service.inventory.get_quantity(&"medpack")==2 and service.player.health==3,"Cancellation consumes nothing")
	ship.survival.medpack(1,"start",0)
	ship.survival.medical[1].time -= 2100
	check(ship.survival.medpack(1,"finish",0) and service.player.health==15,"Completed hold heals to full")
	check(service.inventory.get_quantity(&"medpack")==1 and not ship.survival.medpack(1,"finish",0),"Medpack consumed once")
	check(ItemDatabase.get_item(&"fish_cod").display_name=="Fish","Inventory uses generic fish name")
	MapState.set_destination(Vector2(500,600))
	check(MapState.crew_markers.get(1)==Vector2(500,600),"Local waypoint responds immediately")
	MapState.clear_destination()
	check(MapState.crew_markers.is_empty(),"Clear removes only local waypoint")
	NetworkSession.online=true
	NetworkSession.local_id=1
	NetworkSession.players={1:service.player,2:service.player}
	NetworkSession.services={1:service,2:service}
	NetworkSession._handle_command(2,"marker",{"point":Vector2(100,200),"id":1})
	check(NetworkSession.crew_markers.get(2)==Vector2(100,200) and not NetworkSession.crew_markers.has(1),"Marker ownership comes from sender, not supplied ID")
	NetworkSession._handle_command(2,"marker",{"point":Vector2(INF,0)})
	check(NetworkSession.crew_markers[2]==Vector2(100,200),"Invalid coordinate cannot mutate marker")
	check(MapState.marker_color(1)!=MapState.marker_color(2),"Crew markers have distinct colors")
	NetworkSession.online=false
	NetworkSession.players.clear()
	NetworkSession.services.clear()
	NetworkSession.crew_markers.clear()
	MapState.reset()
	if "--capture" in OS.get_cmdline_user_args():
		GameWindow.set_preference("fullscreen",false)
		get_window().size = Vector2i(1280,720)
		ship.rebuild_world(ship.world_seed)
		ship.get_node("MapUI").open_map()
		MapState.set_destination(Vector2(1200,900))
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/gameplay-map.png")
		ship.get_node("MapUI").close_map()
		var grill: ShipGrill = ship.get_node("Cooking")
		service.player.position=grill.position+Vector2(-20,12)
		service.hud.grill_open=true
		service.inventory.try_add(&"fish_cod")
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/gameplay-galley-menu.png")
		service.hud.grill_panel._start()
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/gameplay-galley.png")
	print("WORLD INTERACTIONS: %d checks, %d failures" % [checks,failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)
