class_name WorldLayout
extends RefCounted
const HALF_SIZE := 12000.0
const SAFE_EDGE := 11000.0
const ISLAND_COUNT := 30

static func danger(point: Vector2) -> bool:
	return absf(point.x) >= SAFE_EDGE or absf(point.y) >= SAFE_EDGE

static func generate(ship: Ship, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var old_islands: Array[Node] = ship.islands_root.get_children()
	var templates: Array[Node] = old_islands.filter(func(node: Node) -> bool: return not node is QuestIsland)
	var islands: Array[WorldIsland] = []
	var quest_islands: Array[WorldIsland] = []
	MapState.key_regions.clear()
	var centers := [Vector2(-7200, 0), Vector2(0, 7200), Vector2(7200, 0)]
	for index in 3:
		var key: String = VoyageState.KEY_IDS[index]
		var special := preload("res://scenes/islands/quest_island.tscn").instantiate() as QuestIsland
		special.key_id = key
		special.name = "Key_" + key
		special.display_name = key.capitalize() + " Key Sanctuary"
		special.position = centers[index] + Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(400, 1200)
		quest_islands.append(special)
		MapState.key_regions.append({"key": key, "center": centers[index], "radius": 3800.0, "island": str(special.name)})
	var paradise := preload("res://scenes/islands/quest_island.tscn").instantiate() as QuestIsland
	paradise.name = "Paradise"
	paradise.paradise = true
	paradise.display_name = "Paradise Island"
	paradise.position = Vector2(0, -9900)
	quest_islands.append(paradise)
	for i in ISLAND_COUNT:
		var island := templates[i % templates.size()].duplicate() as WorldIsland
		# Runtime totems own labels and occupancy; recreate them after rebuilding.
		for child in island.get_children():
			if child is QuestClue:
				island.remove_child(child)
				child.free()
		var old_totem := island.get_node_or_null("MinigameTotem")
		if old_totem != null:
			island.remove_child(old_totem)
			old_totem.free()
		island.name = "Island_%02d" % i
		island.display_name = "Island %d" % (i + 1)
		var factor := rng.randf_range(0.75, 2.3)
		island.scale = Vector2.ONE * factor
		var candidate := Vector2.ZERO
		for attempt in 2000:
			candidate = Vector2(rng.randf_range(-9400, 9400), rng.randf_range(-9400, 9400))
			if candidate.length() < 2000: continue
			var clear := true
			for other in islands + quest_islands:
				if candidate.distance_to(other.position) < 1700: clear = false; break
			if clear: break
		island.position = candidate
		islands.append(island)
	for old in old_islands:
		ship.islands_root.remove_child(old)
		old.queue_free()
	MapState.island_catalog.clear()
	MapState.discovered_islands.clear()
	for island in islands + quest_islands:
		ship.islands_root.add_child(island)
		MapState.register_island(str(island.name), island.display_name, island.global_position, island == paradise)
		MapState.island_catalog[str(island.name)]["coast"] = island.get_coast()
	# A nearby ordinary island in each search region carries a guaranteed clue.
	for region in MapState.key_regions:
		var closest: WorldIsland
		var distance := INF
		for island in islands:
			var gap: float = island.position.distance_to(region.center)
			if gap < distance:
				closest = island
				distance = gap
		if closest != null:
			var clue := preload("res://scripts/islands/quest_clue.gd").new()
			clue.key_id = region.key
			closest.add_child(clue)
			var coast := closest.get_coast()
			var triangles := Geometry2D.triangulate_polygon(coast)
			if triangles.size() >= 3:
				clue.global_position = (coast[triangles[0]] + coast[triangles[1]] + coast[triangles[2]]) / 3.0
			clue.global_scale = Vector2.ONE
	MapState.world_bounds = Rect2(-HALF_SIZE, -HALF_SIZE, HALF_SIZE * 2, HALF_SIZE * 2)
	MapState.changed.emit()
	var challenges := ship.get_node_or_null("IslandChallenges")
	if challenges != null:
		challenges.install_totems()
