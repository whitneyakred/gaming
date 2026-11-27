class_name IslandFoliage
extends Node2D
## Seeded scenery is local; only damaged trees are replicated reliably.
const ATLAS = preload("res://assets/terrain/foliage.png")
const REACH := 65.0
const COOLDOWN := 0.6
@export var regrow_seconds := 300.0
var ship: Ship
var trees: Dictionary = {}
var patches: Array[Dictionary] = []
var changes: Dictionary = {}
var cooldowns: Dictionary = {}
var flashes: Dictionary = {}
var seed_value := -1
var version := -1
var clock := 0.0
var visible_plants: Array[Dictionary] = []
var sounds: Dictionary = {}
var received_state := false

static func icon(index: int) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = ATLAS
	var cell := Vector2(ATLAS.get_width()/4.0,ATLAS.get_height()/2.0)
	result.region = Rect2(Vector2(index%4,index/4)*cell,cell)
	return result

func _ready() -> void:
	ship = get_parent() as Ship
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["chop","tree_fall","axe_swing"]: sounds[kind] = ActionAudio.make(kind)
	rebuild()

func rebuild() -> void:
	if seed_value == ship.world_seed and version == ship.layout_version: return
	seed_value = ship.world_seed
	version = ship.layout_version
	trees.clear(); patches.clear(); changes.clear(); flashes.clear(); cooldowns.clear()
	received_state = false
	for island in ship.get_islands():
		if not island is GeneratedIsland: continue
		var rng := RandomNumberGenerator.new()
		rng.seed = island.terrain_seed + 18271
		var plants: Array[Dictionary] = []
		for attempt in 500:
			if plants.size() >= 110: break
			var p := Vector2(rng.randf_range(-2300,2300),rng.randf_range(-2300,2300))
			if Vector2(p.x/930.0,p.y/750.0).length() < 1.0: continue
			if not Geometry2D.is_point_in_polygon(p+ p.normalized()*200.0,island.coast_points): continue
			var near := false
			for other in plants:
				if p.distance_to(other.local) < 110.0: near = true; break
			if near: continue
			var kind := rng.randi_range(0,5)
			var id := str(island.name)+":"+str(plants.size())
			var entry := {"id":id,"local":p,"point":island.to_global(p),"kind":kind,"size":rng.randf_range(0.85,1.18),"phase":rng.randf_range(0,TAU)}
			plants.append(entry)
			if kind < 4: trees[id] = entry
		patches.append({"center":island.global_position,"plants":plants})

func time_now() -> float:
	return ship.ocean_fish.shared_time() if is_instance_valid(ship.ocean_fish) else clock

func _process(delta: float) -> void:
	rebuild()
	clock += delta
	if not NetworkSession.online or multiplayer.is_server():
		for id in changes.keys():
			if changes[id].hits == 3 and time_now() >= changes[id].until: changes.erase(id)
	var camera := get_viewport().get_camera_2d()
	if camera == null: return
	var half := get_viewport_rect().size / camera.zoom * 0.5 + Vector2(160,180)
	var view := Rect2(camera.get_screen_center_position()-half,half*2)
	visible_plants.clear()
	for patch in patches:
		if not view.grow(3000).has_point(patch.center): continue
		for entry in patch.plants:
			if view.has_point(entry.point): visible_plants.append(entry)
	visible_plants.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.point.y < b.point.y)
	for id in flashes.keys():
		flashes[id] -= delta
		if flashes[id] <= 0: flashes.erase(id)
	queue_redraw()

func _draw() -> void:
	var cell := Vector2(ATLAS.get_width()/4.0,ATLAS.get_height()/2.0)
	var local_player: Node2D = NetworkSession.players.get(NetworkSession.local_id) if NetworkSession.online else ship.player
	for entry in visible_plants:
		var stump: bool = changes.get(entry.id,{}).get("hits",0) == 3
		var kind: int = 6 if stump else entry.kind
		var size: float = (120.0 if kind < 4 else (45.0 if stump else 83.0))*entry.size
		var shake: float = flashes.get(entry.id,0.0)
		var angle := 0.0 if stump else sin(clock*1.35+entry.phase)*0.025 + sin(clock*2.3+entry.phase)*0.008
		if not stump: angle += sin(shake*65.0)*shake*0.22
		var tint := Color.WHITE
		if is_instance_valid(local_player) and kind < 4 and local_player.global_position.distance_to(entry.point+Vector2(0,-45)) < 48: tint.a = 0.45
		draw_set_transform(entry.point+Vector2(0,2),0,Vector2(1,0.28))
		draw_circle(Vector2.ZERO,(24.0 if kind<4 else 15.0)*entry.size,Color(0.08,0.14,0.1,0.18))
		draw_set_transform(entry.point,angle,Vector2.ONE)
		# Tree feet sit at 94% of the top cell; lower-row items at 74%.
		var anchor := 0.94 if kind < 4 else 0.74
		draw_texture_rect_region(ATLAS,Rect2(-size*0.5,-size*anchor,size,size),Rect2(Vector2(kind%4,kind/4)*cell,cell),tint)
		if shake > 0:
			var progress := 1.0-shake/0.35
			if stump:
				var full_size: float = 120.0*entry.size
				draw_set_transform(entry.point,progress*1.15,Vector2.ONE)
				draw_texture_rect_region(ATLAS,Rect2(-full_size*0.5,-full_size*0.94,full_size,full_size),Rect2(Vector2(entry.kind%4,entry.kind/4)*cell,cell),Color(1,1,1,1-progress))
			draw_set_transform(entry.point,0,Vector2.ONE)
			for chip in 5:
				var offset := Vector2((chip-2)*progress*12,-sin(progress*PI)*20+progress*12)
				draw_rect(Rect2(offset,Vector2(3,2)),Color(0.72,0.5,0.29,1-progress))
	draw_set_transform(Vector2.ZERO)

func sound(kind: String, point: Vector2) -> void:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = sounds[kind]
	audio.position = point
	audio.max_distance = 700
	audio.volume_db = -5
	audio.pitch_scale = randf_range(0.94,1.06)
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func chop(service: InventoryService, point: Vector2, slot: int) -> bool:
	var player: CharacterBody2D = service.player
	if not point.is_finite() or not service.can_handle_items() or not player.on_land or player.inventory_open or player.fishing_active or player.access_motion != &"": return false
	if slot < 0 or slot >= service.local_slots.size() or service.local_slots[slot].get("id") != &"axe": return false
	var now := time_now()
	if now < float(cooldowns.get(service.network_id,-1.0)): return false
	cooldowns[service.network_id] = now+COOLDOWN
	var direction := (point-player.global_position).normalized()
	player.chop_direction = direction
	player.chop_serial += 1
	var best := ""
	var distance := REACH
	for id in trees:
		if changes.get(id,{}).get("hits",0) == 3: continue
		var offset: Vector2 = trees[id].point-player.global_position
		if offset.length() < distance and (offset.length()<18 or direction.dot(offset.normalized()) > 0.35):
			distance = offset.length(); best = id
	if best.is_empty(): return true
	# Never consume a tree if the bounded shared floor inventory cannot hold loot.
	if service.drops.size() >= 250: return true
	var hits: int = changes.get(best,{}).get("hits",0)+1
	changes[best] = {"hits":hits,"until":now+regrow_seconds if hits==3 else 0.0}
	flashes[best] = 0.35
	sound("tree_fall" if hits==3 else "chop",trees[best].point)
	if hits == 3:
		var drop_id := NetworkSession.dropped_id if NetworkSession.online else service.next_drop_id
		if NetworkSession.online: NetworkSession.dropped_id += 1
		else: service.next_drop_id += 1
		service.drops[drop_id] = {"id":&"wood","quantity":3,"position":trees[best].point+Vector2(25,18),"world":true,"age":0.0,"spawn_origin":trees[best].point,"spawn_time":now}
	return true

func restore(state: Dictionary, saved := false) -> void:
	if not saved and received_state and state == changes: return
	for id in state:
		if not trees.has(id): continue
		var entry: Dictionary = state[id]
		if not saved and received_state and changes.get(id,{}).get("hits",0) != entry.hits:
			flashes[id] = 0.35
			sound("tree_fall" if entry.hits==3 else "chop",trees[id].point)
	changes = state.duplicate(true)
	received_state = true
	if saved:
		for id in changes:
			if changes[id].hits == 3: changes[id].until = time_now()+clampf(changes[id].until,0,regrow_seconds)

func capture_save() -> Dictionary:
	var result := changes.duplicate(true)
	for id in result:
		if result[id].hits==3: result[id].until = maxf(0.0,result[id].until-time_now())
	return result

static func valid(state: Variant) -> bool:
	if not state is Dictionary or state.size() > 3300: return false
	for id in state:
		var entry: Variant = state[id]
		if not id is String or id.length()>80 or not entry is Dictionary: return false
		if not entry.get("hits") is int or entry.hits < 1 or entry.hits > 3: return false
		if not entry.get("until") is float or not is_finite(entry.until) or entry.until < 0: return false
	return true
