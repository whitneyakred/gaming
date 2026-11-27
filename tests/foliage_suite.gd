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
	var tree_id: String = forest.trees.keys()[0]
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
	if "--capture" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1280,720)
		ship.set_process(false)
		var old_camera := get_viewport().get_camera_2d()
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

