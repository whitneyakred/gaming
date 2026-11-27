class_name SharedSnapshotState
extends RefCounted
## Rarely changing state travels reliably; motion packets reference its revision.
const KEYS := ["foliage","paradise_quest", "island_locks", "discovered", "layout_version", "seed", "storage", "port_storage", "drops", "markers", "fish_taken", "fish_returns"]
var revision := 0
var current: Dictionary = {}
var versions: Dictionary = {}

func extract(snapshot: Dictionary) -> bool:
	var state := {}
	for key: String in KEYS: state[key] = snapshot.get(key,{})
	# Lifetime/timeout clocks are host-only. Their per-tick changes must not turn
	# an idle dropped item or occupied island into a reliable 10 Hz broadcast.
	state.drops = snapshot.drops.duplicate()
	for id: int in state.drops:
		state.drops[id] = snapshot.drops[id].duplicate()
		state.drops[id].erase("age")
	state.island_locks = snapshot.island_locks.duplicate()
	for id: String in state.island_locks:
		state.island_locks[id] = snapshot.island_locks[id].duplicate()
		state.island_locks[id].erase("seconds")
	state["bags"] = {}
	for id: int in snapshot.crew:
		state.bags[id] = snapshot.crew[id].inventory
	if state == current: return false
	current = state.duplicate(true)
	revision += 1
	return true

func motion(snapshot: Dictionary) -> Dictionary:
	# The captured values are immutable during serialization. Copy only the
	# dictionaries we edit, not the inventories we are about to omit.
	var result := snapshot.duplicate()
	for key: String in KEYS: result.erase(key)
	result.crew = snapshot.crew.duplicate()
	for id: int in result.crew:
		result.crew[id] = snapshot.crew[id].duplicate()
		result.crew[id].erase("inventory")
	result["shared_revision"] = revision
	return result

func accept(version: int, state: Dictionary) -> bool:
	if version < 1 or not valid(state): return false
	versions[version] = state
	# Reliable delivery is ordered, but motion can arrive on another channel.
	var keys := versions.keys()
	keys.sort()
	while keys.size() > 8: versions.erase(keys.pop_front())
	return true

func expand(snapshot: Dictionary) -> Dictionary:
	if not snapshot.get("shared_revision") is int: return {}
	var state: Dictionary = versions.get(snapshot.shared_revision, {})
	if state.is_empty() or not snapshot.get("crew") is Dictionary: return {}
	var result := snapshot.duplicate()
	result.crew = snapshot.crew.duplicate()
	for key: String in KEYS: result[key] = state.get(key,{})
	for id: Variant in result.crew:
		if not result.crew[id] is Dictionary or not state.bags.has(id): return {}
		result.crew[id] = snapshot.crew[id].duplicate()
		result.crew[id]["inventory"] = state.bags[id]
	return result

static func valid_slots(slots: Variant) -> bool:
	if not slots is Array or slots.size() > 256: return false
	for slot: Variant in slots:
		if not slot is Dictionary: return false
		if slot.is_empty(): continue
		if not (slot.get("id") is String or slot.get("id") is StringName) or not slot.get("quantity") is int: return false
		if slot.has("durability") and (not slot.durability is int or slot.durability < 1 or slot.durability > 999): return false
		if slot.quantity < 1 or slot.quantity > 999999: return false
	return true

static func valid(state: Dictionary) -> bool:
	if not IslandFoliage.valid(state.get("foliage",{})): return false
	for key in ["markers", "fish_taken", "fish_returns"]:
		if not state.get(key,{}) is Dictionary: return false
	if state.get("fish_returns",{}).size() > 32: return false
	for id in state.get("fish_returns",{}):
		var entry: Variant = state.fish_returns[id]
		if not id is String or id.length() > 80 or not entry is Dictionary: return false
		if not entry.get("position") is Vector2 or not entry.position.is_finite(): return false
		for key in ["angle","time","duration"]:
			if not entry.get(key) is float or not is_finite(entry[key]): return false
	if state.get("markers",{}).size() > 4 or state.get("fish_taken",{}).size() > 256: return false
	for id in state.get("markers",{}):
		if not id is int or not state.markers[id] is Vector2 or not state.markers[id].is_finite(): return false
	for id in state.get("fish_taken",{}):
		if not id is String or id.length() > 80 or not state.fish_taken[id] is float or not is_finite(state.fish_taken[id]): return false
	for key: String in ["paradise_quest", "island_locks", "discovered", "drops", "bags"]:
		if not state.get(key) is Dictionary: return false
	if not state.get("layout_version") is int or state.layout_version not in [1,WorldLayout.VERSION]: return false
	if not state.get("seed") is int or not valid_slots(state.get("storage")) or not valid_slots(state.get("port_storage")): return false
	if state.bags.size() > 4: return false
	for key: Variant in state.paradise_quest:
		if not (key is String or key is StringName) or not state.paradise_quest[key] is bool: return false
	for key: Variant in state.island_locks:
		var lock: Variant = state.island_locks[key]
		if not key is String or not lock is Dictionary or not lock.get("player") is int or not lock.get("token") is int: return false
		if lock.has("until") and (not lock.until is float or not is_finite(lock.until)): return false
	for key: Variant in state.discovered:
		var island: Variant = state.discovered[key]
		if not (key is String or key is StringName) or not island is Dictionary: return false
		if not island.get("name") is String or not island.get("position") is Vector2 or not island.position.is_finite(): return false
	for id: Variant in state.bags:
		if not id is int or not valid_slots(state.bags[id]): return false
	for id: Variant in state.drops:
		var drop: Variant = state.drops[id]
		if not id is int or not drop is Dictionary or not drop.get("position") is Vector2 or not drop.position.is_finite(): return false
		if not valid_slots([drop]): return false
		if drop.has("spawn_origin") and (not drop.spawn_origin is Vector2 or not drop.spawn_origin.is_finite()): return false
		if drop.has("spawn_time") and (not drop.spawn_time is float or not is_finite(drop.spawn_time)): return false
		if drop.has("world") and not drop.world is bool: return false
	return true
