class_name LegacyWorldLayout
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
	var original: Node = load("res://scenes/ship.tscn").instantiate()
	var templates: Array[Node] = original.get_node("Islands").get_children()
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
	MapState.world_bounds = Rect2(-HALF_SIZE, -HALF_SIZE, HALF_SIZE * 2, HALF_SIZE * 2)
	MapState.changed.emit()
	var challenges := ship.get_node_or_null("IslandChallenges")
	if challenges != null:
		challenges.install_totems()

	original.free()
