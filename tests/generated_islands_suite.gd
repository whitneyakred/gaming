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
	print("WORLD BUILD: ",ship.generation_ms," ms, ",ship.get_islands().size()," islands")
	check(ship.layout_version==2 and MapState.world_bounds.size==Vector2(48000,48000),"New worlds use expanded versioned layout")
	var originals := {}
	var meshes := 0
	for island in ship.get_islands():
		originals[str(island.name)] = {"position":island.position,"coast":island.get_coast()}
		for point in island.get_coast(): check(MapState.world_bounds.grow(-1000).has_point(point),"Coast stays inside safe world boundary")
		if not island is GeneratedIsland: continue
		var generated := island as GeneratedIsland
		check(generated.footprint>1400 and generated.coast_points.size()==GeneratedIsland.VERTICES,"Large bounded coastline geometry")
		check(Geometry2D.triangulate_polygon(generated.coast_points).size()>0,"Coast triangulates without self-intersections")
		for corner in [GeneratedIsland.CLEARING.position,GeneratedIsland.CLEARING.end,Vector2(-560,380),Vector2(560,-380)]:
			check(Geometry2D.is_point_in_polygon(corner,generated.coast_points),"Playable clearing fits entirely on island")
			check(Geometry2D.is_point_in_polygon(corner,generated.terrain.clearing_polygon),"Reserved game footprint fits the visible clearing")
		check(generated.get_node("MinigameTotem").global_position==generated.challenge_position(),"Totem is placed in reserved clearing")
		check(generated.terrain.polygon_count<=12,"Terrain draw geometry stays bounded")
		meshes += generated.terrain.polygon_count
	var all := ship.get_islands()
	for i in all.size():
		for j in range(i+1,all.size()): check(Geometry2D.intersect_polygons(all[i].get_coast(),all[j].get_coast()).is_empty(),"Islands never overlap")
	ship.rebuild_world(34730)
	check(ship.get_island("Island_00").get_coast()!=originals.Island_00.coast,"Another seed changes actual shape and position")
	ship.rebuild_world(34729)
	for island in ship.get_islands():
		check(originals[str(island.name)].position==island.position and originals[str(island.name)].coast==island.get_coast(),"Same seed reproduces exact host/guest geometry")
	var peak_generation := ship.generation_ms
	for seed_value in [1,97,8191,272921,999999,2147483646]:
		ship.rebuild_world(seed_value)
		peak_generation = maxf(peak_generation,ship.generation_ms)
		check(ship.get_islands().size()==34,"Seed sweep packs every island")
		for generated in ship.get_islands():
			if generated is GeneratedIsland:
				check(generated.position.length() > generated.footprint+2200.0,"Seed sweep preserves safe starting waters")
		await get_tree().process_frame
	print("WORLD BUILD SWEEP PEAK: ",peak_generation," ms")
	ship.rebuild_world(34729,1)
	check(ship.layout_version==1 and MapState.world_bounds.size==Vector2(24000,24000),"Old saves retain original map size and generator")
	check(not ship.get_island("Island_00") is GeneratedIsland,"Old saves retain authored island pictures")
	ship.rebuild_world(34729,2)
	check(ship.get_island("Island_00").get_coast()==originals.Island_00.coast,"Version switching restores exact new shape")
	if "--capture" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(1280,720)
		var island := ship.get_island("Island_00") as GeneratedIsland
		var camera := Camera2D.new()
		ship.add_child(camera)
		camera.global_position = island.global_position
		camera.zoom = Vector2(0.16,0.16)
		camera.make_current()
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/generated-island-overview.png")
		camera.zoom = Vector2.ONE
		ship.player.set_overboard(true)
		ship.player.update_land(true)
		ship.player.global_position = island.global_position+Vector2(0,160)
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/generated-island-clearing.png")
		camera.global_position = island.to_global(island.coast_points[20])
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/generated-island-shore.png")
		await capture_gallery()
	print("GENERATED ISLANDS: %d checks, %d failures, %d terrain polygons" % [checks,failures,meshes])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)

func capture_gallery() -> void:
	get_tree().current_scene.queue_free()
	await get_tree().process_frame
	var gallery := Node2D.new()
	get_tree().root.add_child(gallery)
	get_tree().current_scene = gallery
	get_window().size = Vector2i(1280,960)
	var camera := Camera2D.new()
	camera.position = Vector2(640,480)
	gallery.add_child(camera)
	camera.make_current()
	var ocean := Ocean.new()
	gallery.add_child(ocean)
	for i in 4:
		var island := GeneratedIsland.new()
		island.configure([1075616,852915,645329,123459][i])
		island.position = Vector2(320+(i%2)*640,260+(i/2)*460)
		island.scale = Vector2.ONE*0.102
		gallery.add_child(island)
		var label := Label.new()
		label.position = Vector2((i%2)*640,22+(i/2)*460)
		label.size = Vector2(640,40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font",HarborTheme.UI_FONT)
		label.add_theme_font_size_override("font_size",22)
		label.text = ["Broad coves","Long beaches","Rocky ground","Sheltered clearing"][i]
		gallery.add_child(label)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/previews")
	get_viewport().get_texture().get_image().save_png("res://docs/previews/generated-islands.png")
