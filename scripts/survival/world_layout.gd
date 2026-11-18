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
	var templates: Array[Node] = ship.islands_root.get_children()
	var islands: Array[WorldIsland] = []
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
			for other in islands:
				if candidate.distance_to(other.position) < 1700: clear = false; break
			if clear: break
		island.position = candidate
		islands.append(island)
	for old in templates:
		ship.islands_root.remove_child(old)
		old.queue_free()
	MapState.island_catalog.clear()
	MapState.discovered_islands.clear()
	for island in islands:
		ship.islands_root.add_child(island)
		MapState.register_island(str(island.name), island.display_name, island.global_position)
		MapState.island_catalog[str(island.name)]["coast"] = island.get_coast()
	MapState.world_bounds = Rect2(-HALF_SIZE, -HALF_SIZE, HALF_SIZE * 2, HALF_SIZE * 2)
	MapState.changed.emit()
	var challenges := ship.get_node_or_null("IslandChallenges")
	if challenges != null:
		challenges.install_totems()
