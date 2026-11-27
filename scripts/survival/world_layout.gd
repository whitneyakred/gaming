class_name WorldLayout
extends RefCounted
const VERSION := 2
const HALF_SIZE := 24000.0
const SAFE_EDGE := 23000.0
const ISLAND_COUNT := 30

static func danger(point: Vector2) -> bool:
	var limit := MapState.world_bounds.end.x-1000.0
	return absf(point.x) >= limit or absf(point.y) >= limit

static func space_clear(point: Vector2, radius: float, placed: Array[Vector3]) -> bool:
	if point.length() < radius+2200.0: return false
	for other in placed:
		if point.distance_to(Vector2(other.x,other.y)) < radius+other.z+850.0: return false
	return true

static func generate(ship: Ship, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var old_islands := ship.islands_root.get_children()
	var templates: Array[Node] = old_islands.filter(func(node: Node) -> bool: return not node is QuestIsland)
	var islands: Array[WorldIsland] = []
	var placed: Array[Vector3] = []
	MapState.key_regions.clear()
	var centers := [Vector2(-16700,0),Vector2(0,16700),Vector2(16700,0)]
	for index in 4:
		var special := preload("res://scenes/islands/quest_island.tscn").instantiate() as QuestIsland
		special.generated_ground = true
		special.radius = Vector2(1350,1150)
		if index == 3:
			special.name = "Paradise"
			special.display_name = "Paradise Island"
			special.paradise = true
			special.position = Vector2(0,-20800)
		else:
			var key: String = VoyageState.KEY_IDS[index]
			special.key_id = key
			special.name = "Key_"+key
			special.display_name = key.capitalize()+" Key Sanctuary"
			special.position = centers[index]+Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(400,1300)
			MapState.key_regions.append({"key":key,"center":centers[index],"radius":4800.0,"island":str(special.name)})
		islands.append(special)
		placed.append(Vector3(special.position.x,special.position.y,1500))
	for i in ISLAND_COUNT:
		var island := GeneratedIsland.new()
		island.name = "Island_%02d" % i
		island.display_name = "Island %d" % (i+1)
		island.scene = templates[i%templates.size()].scene
		island.configure(seed_value*31+i*7919+17)
		var position_found := false
		for attempt in 2000:
			var limit := SAFE_EDGE-island.footprint-350.0
			var candidate := Vector2(rng.randf_range(-limit,limit),rng.randf_range(-limit,limit))
			if space_clear(candidate,island.footprint,placed):
				island.position = candidate
				position_found = true
				break
		assert(position_found,"Island packing exhausted: never silently overlap coastlines")
		islands.append(island)
		placed.append(Vector3(island.position.x,island.position.y,island.footprint))
	# Keep ordinary islands first for existing minigame and developer-tool callers.
	islands.sort_custom(func(a: WorldIsland,b: WorldIsland) -> bool: return str(a.name)<str(b.name))
	for old in old_islands:
		ship.islands_root.remove_child(old)
		old.queue_free()
	MapState.island_catalog.clear()
	MapState.discovered_islands.clear()
	for island in islands:
		ship.islands_root.add_child(island)
		MapState.register_island(str(island.name),island.display_name,island.global_position,str(island.name)=="Paradise")
		MapState.island_catalog[str(island.name)]["coast"] = island.get_coast()
	MapState.world_bounds = Rect2(-HALF_SIZE,-HALF_SIZE,HALF_SIZE*2,HALF_SIZE*2)
	MapState.changed.emit()
	var challenges := ship.get_node_or_null("IslandChallenges")
	if challenges != null: challenges.install_totems()
