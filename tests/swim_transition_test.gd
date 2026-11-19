extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ship = main.get_node("Ship")
	var crew = ship.player
	var visual = crew.idle_sprite
	var appearance = crew.character_appearance
	var access = ship.get_node("SwimAccess")
	access.set_physics_process(false)
	crew.set_physics_process(false)
	visual.set_physics_process(false)
	crew.position = access.plank_end
	access.update_crew(crew)
	check(crew.access_motion == &"jump", "Plank starts jump")
	var start: Vector2 = crew.global_position
	crew.move_crew(Vector2.RIGHT, 0.1)
	check(crew.global_position == start, "Traversal locks manual movement")
	access._advance_access(crew, access.jump_seconds * 0.6)
	check(visual.texture == appearance.action_atlas and visual.region_rect == appearance.action_regions[2], "Jump uses dedicated tucked cannonball frame")
	check(visual.position.y < -15, "Cannonball follows raised arc")
	ship.global_position += Vector2(100, 60)
	ship.global_rotation = 0.4
	access._advance_access(crew, access.jump_seconds * 0.4 + 0.00001)
	check(crew.access_motion == &"dunk" and crew.is_overboard, "Impact starts underwater dip")
	check(crew.global_position.distance_to(ship.to_global(access.water_entry)) < 0.01, "Landing follows moving ship")
	var splashes: Array[Node] = []
	for child in ship.get_children():
		if child.get_script() == load("res://scripts/visuals/water_splash.gd"): splashes.append(child)
	check(splashes.size() == 1, "Exactly one splash on impact")
	var landing: Vector2 = crew.global_position
	ship.global_position += Vector2(20, 0)
	access._advance_access(crew, access.dunk_seconds * 0.7)
	check(crew.global_position == landing, "Dunk stays at impact while ship sails away")
	check(visual.self_modulate.a < 0.4 and visual.position.y > 8, "Underwater body sinks and fades blue")
	crew._process(0)
	check(crew.z_index == -1, "Underwater body stays below ship")
	access._advance_access(crew, access.dunk_seconds * 0.3 + 0.00001)
	check(crew.access_motion == &"surface" and visual.texture == appearance.swim_atlas, "Resurfacing switches to swimming art")
	access._advance_access(crew, access.surface_seconds + 0.00001)
	check(crew.access_motion == &"" and visual.self_modulate == Color.WHITE, "Swim resumes without leftover tint")
	check(not visual.region_enabled and visual.hframes == appearance.columns, "Swim restores regular atlas layout")
	if not splashes.is_empty():
		var splash = splashes[0]
		check(splash.global_position == landing, "Splash stays in water as ship moves")
		await create_timer(0.85).timeout
		check(not is_instance_valid(splash), "Splash frees itself")
	for angle in [0.0, PI / 2.0]:
		ship.global_rotation = angle
		crew.global_position = ship.to_global(access.ladder_water + Vector2(-10, 5))
		access.update_crew(crew)
		check(crew.access_motion == &"align", "Ladder first aligns swimmer")
		access._advance_access(crew, access.align_seconds + 0.00001)
		check(crew.access_motion == &"climb", "Alignment starts climb")
		check(ship.to_local(crew.global_position).distance_to(access.ladder_water) < 0.01, "Climb begins on ladder center")
		access._advance_access(crew, access.climb_seconds * 0.5)
		var halfway: Vector2 = ship.to_local(crew.global_position)
		check(is_equal_approx(halfway.x, access.ladder_water.x) and halfway.y < access.ladder_water.y, "Climb is straight up ship-relative ladder")
		check(visual.texture == appearance.action_atlas and visual.facing == 3, "Climb uses dedicated back-facing animation")
		access._advance_access(crew, access.climb_seconds * 0.5 + 0.00001)
		check(crew.access_motion == &"step_on" and crew.is_overboard, "Only reaching the lip starts sideways step")
		access._advance_access(crew, access.step_seconds * 0.5)
		var sideways: Vector2 = ship.to_local(crew.global_position)
		check(is_equal_approx(sideways.y, access.ladder_lip.y) and sideways.x > access.ladder_lip.x, "Step moves horizontally onto deck")
		check(visual.texture == appearance.walk_atlas, "Deck step uses walking art")
		access._advance_access(crew, access.step_seconds)
		check(not crew.is_overboard and crew.access_motion == &"" and crew.position.distance_to(access.ladder_top) < 0.01, "Climb finishes on deck")
		check(crew.collision_mask != 0, "Boarding restores collision")
		crew.set_overboard(true)
	crew.set_overboard(false)
	crew.position = access.plank_end
	access.update_crew(crew)
	access._advance_access(crew, 2.0)
	check(crew.access_motion == &"" and crew.is_overboard, "Large delta completes phases without sticking")
	crew.set_overboard(false)
	crew.position = access.plank_end
	access.update_crew(crew)
	crew.health = 0
	access._advance_access(crew, 0.1)
	check(crew.access_motion == &"", "Death cancels traversal")
	crew.health = 15
	access._begin_access(crew, &"align")
	crew.set_overboard(false)
	check(crew.access_motion == &"", "Respawn/forced boarding clears traversal")
	var portrait: AtlasTexture = appearance.portrait()
	var cropped := portrait.atlas.get_image().get_region(Rect2i(portrait.region))
	check(cropped.get_used_rect() == Rect2i(Vector2i.ZERO, cropped.get_size()), "Portrait trims uneven transparent padding")
	for region in appearance.action_regions:
		check(Rect2(Vector2.ZERO, appearance.action_atlas.get_size()).encloses(region), "Action crop is inside saved atlas")
	print("SWIM TRANSITIONS: ", checks, " checks, ", failures, " failures")
	quit(failures)
