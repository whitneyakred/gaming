extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameWindow.set_preference("pause_unfocused",false)
	GameWindow.set_preference("fullscreen",false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship: Ship = get_tree().current_scene.get_node("Ship")
	ship.set_physics_process(false)
	ship.survival.set_physics_process(false)
	ship.rebuild_world(34729)
	var started := Time.get_ticks_usec()
	ship.foliage.rebuild()
	print("FOLIAGE BUILD MS: ",(Time.get_ticks_usec()-started)/1000.0)
	var forest := ship.foliage
	check(forest.trees.size()>500 and forest.trees.size()<3300,"Bounded varied forest generated")
	var tree_id: String = forest.trees.keys().filter(func(id: String)->bool: return forest.trees[id].kind==0)[0]
	var tree: Dictionary = forest.trees[tree_id]
	var original := forest.trees.duplicate(true)
	forest.seed_value = -1
	forest.rebuild()
	check(original==forest.trees,"Host and guest derive identical foliage from seed")
	for patch in forest.patches:
		for plant in patch.plants:
			check(Vector2(plant.local.x/930.0,plant.local.y/750.0).length()>=1,"Clearing remains empty")
	var service: InventoryService = ship.get_node("InventorySystem")
	var player := ship.player
	player.set_overboard(true)
	player.update_land(true)
	player.global_position = tree.point+Vector2(0,40)
	var slot := -1
	for i in service.local_slots.size():
		if service.local_slots[i].get("id")==&"axe": slot=i
	check(slot>=0,"New sailor starts with axe")
	service.hud.select_slot(slot)
	check(not forest.chop(service,tree.point,-1),"Invalid slot rejected")
	check(not forest.chop(service,Vector2(INF,0),slot),"Non-finite aim rejected")
	var before := service.drops.size()
	for i in 3:
		forest.cooldowns.clear()
		check(forest.chop(service,tree.point,slot),"Valid chop accepted")
		check(forest.changes[tree_id].hits==i+1,"Exactly one hit per chop")
		check(not forest.chop(service,tree.point,slot),"Rapid repeat cannot double-hit")
	check(service.drops.size()==before+1,"Third hit creates exactly one wood stack")
	var drop: Dictionary = service.drops.values().back()
	check(drop.id==&"wood" and drop.quantity==3 and drop.world,"Wood remains on island")
	forest.cooldowns.clear()
	forest.chop(service,tree.point,slot)
	check(service.drops.size()==before+1,"Stump cannot grant more wood")
	var saved := forest.capture_save()
	check(saved[tree_id].until>299 and saved[tree_id].until<=300,"Five minute regrowth saved as remaining duration")
	forest.restore(saved,true)
	check(forest.changes[tree_id].hits==3,"Stump survives save restoration")
	check(not IslandFoliage.valid({tree_id:{"hits":"bad","until":0.0}}),"Malformed tree state rejected")
	check(not IslandFoliage.valid({tree_id:{"hits":4,"until":0.0}}),"Impossible health rejected")
	forest.changes[tree_id].until = forest.time_now()-1
	forest._process(0.01)
	check(not forest.changes.has(tree_id),"Expired stump regrows")
	var axe: AxeAction
	for child in player.presentation.get_children():
		if child is AxeAction: axe=child
	forest.cooldowns.clear()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = player.get_canvas_transform()*tree.point
	axe._unhandled_input(touch)
	check(forest.changes.get(tree_id,{}).get("hits",0)==1 and axe.timer>0,"Touch starts immediate swing and authoritative chop")
	var serial: int = player.chop_serial
	axe._unhandled_input(touch)
	check(player.chop_serial==serial,"Touch/mouse emulation cannot double chop")
	axe.cooldown=0
	MapState.map_open=true
	axe._unhandled_input(touch)
	check(player.chop_serial==serial,"Map prevents axe input")
	MapState.map_open=false
	var largest := {}
	for id in forest.trees: largest[id]={"hits":3,"until":12345.0}
	check(var_to_bytes(largest).compress(FileAccess.COMPRESSION_GZIP).size()<20000,"Even every felled tree fits comfortably in reliable packet budget")
	for island in ship.get_islands():
		if island is GeneratedIsland: check(island.terrain.path_polygon.is_empty(),"Beach-to-clearing path removed")
	for item in ItemDatabase.get_all_items():
		check(item.icon is AtlasTexture and item.icon.atlas==PixelItemIcons.ATLAS,"Every registered item has matching pixel artwork")
		check(minf(item.icon.get_width(),item.icon.get_height())>75,"Inventory icon is cropped to visible artwork")
	check(VoyageState.get_ship_storage(18,1).slots.filter(func(entry: Dictionary)->bool: return entry.get("id")==&"pickaxe").size()==4,"Second chest supplies four unstacked pickaxes")
	var rock_id: String = forest.trees.keys().filter(func(id: String)->bool: return forest.trees[id].kind==8)[0]
	var rock: Dictionary = forest.trees[rock_id]
	player.global_position = rock.point+Vector2(0,40)
	forest.cooldowns.clear()
	forest.chop(service,rock.point,slot)
	check(not forest.changes.has(rock_id),"Axe cannot mine stone")
	check(service.inventory.try_add(&"pickaxe"),"Pickaxe fits empty carrying slot")
	var pick_slot := 3
	service.hud.select_slot(pick_slot)
	before = service.drops.size()
	for i in 3:
		forest.cooldowns.clear()
		check(forest.chop(service,rock.point,pick_slot),"Pickaxe strike accepted")
	check(forest.changes[rock_id].hits==3 and service.drops.size()==before+1,"Rock breaks once after three hits")
	drop = service.drops.values().back()
	check(drop.id==&"stone" and drop.quantity==3,"Rock yields three stone")
	forest.cooldowns.clear()
	forest.chop(service,rock.point,pick_slot)
	check(service.drops.size()==before+1,"Rubble cannot duplicate loot")
	var palm_id: String = forest.trees.keys().filter(func(id: String)->bool: return forest.trees[id].kind==3)[0]
	var palm: Dictionary = forest.trees[palm_id]
	player.global_position = palm.point+Vector2(0,40)
	forest.cooldowns.clear()
	forest.chop(service,palm.point,pick_slot)
	check(not forest.changes.has(palm_id),"Pickaxe cannot chop palms")
	service.hud.select_slot(slot)
	before = service.drops.size()
	for i in 3:
		forest.cooldowns.clear()
		forest.chop(service,palm.point,slot)
	var palm_drops: Array = service.drops.values().slice(before)
	check(palm_drops.size()==2 and palm_drops[0].id==&"wood" and palm_drops[0].quantity==1 and palm_drops[1].id==&"coconut" and palm_drops[1].quantity==2,"Palm produces one wood and two coconuts")
	service.inventory.remove(pick_slot,1)
	service.inventory.try_add(&"coconut",2)
	service.hud.select_slot(pick_slot)
	player.hunger=10
	check(ship.survival.eat(1,pick_slot) and player.hunger==12 and service.inventory.get_quantity(&"coconut")==1,"Coconut is consumed authoritatively and restores hunger")
	for region in MapState.key_regions:
		var covered := 0
		for island in ship.get_islands():
			if island is GeneratedIsland and region.center.distance_to(island.global_position)+island.footprint<=region.radius+0.01: covered+=1
		check(covered>=3 and region.radius>=8500,"Each enlarged key circle contains multiple whole islands")
	var old_camera := get_viewport().get_camera_2d()
	old_camera.enabled=false
	var depth_camera := Camera2D.new()
	get_tree().current_scene.add_child(depth_camera)
	depth_camera.global_position=tree.point
	depth_camera.make_current()
	depth_camera.force_update_scroll()
	forest.changes[tree_id]={"hits":3,"until":forest.time_now()+300.0}
	player.global_position=tree.point+Vector2(0,8)
	forest._process(0.01)
	var stump_visual: FoliageVisual = forest.visuals.filter(func(v: FoliageVisual)->bool: return v.visible and v.entry.id==tree_id)[0]
	check(player.z_index>stump_visual.z_index,"Player in front renders over stump")
	player.global_position=tree.point-Vector2(0,8)
	forest._process(0.01)
	check(player.z_index<stump_visual.z_index,"Player behind renders behind stump")
	depth_camera.queue_free()
	old_camera.enabled=true
	service.hud.select_slot(slot)
	player.global_position=tree.point+Vector2(0,20)
	if "--capture" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1280,720)
		ship.set_process(false)
		old_camera.enabled = false
		var camera := Camera2D.new()
		get_tree().current_scene.add_child(camera)
		camera.make_current()
		camera.global_position = tree.point
		camera.zoom = Vector2(2,2)
		for i in 2:
			forest.cooldowns.clear()
			forest.chop(service,tree.point,slot)
		axe.start_swing()
		await get_tree().create_timer(0.18).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/foliage-preview.png")
	GameWindow.shutdown_audio()
	print("FOLIAGE: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

