class_name OceanFish
extends Node2D
## Bounded, recycled schools; one atlas and one MultiMesh for the entire field.
@export_range(1, 256) var max_fish: int = 125
@export_range(0.2, 5.0) var arrival_seconds: float = 1.6
@export_range(1.0, 1800.0) var caught_respawn_seconds: float = 300.0
@export var menu_mode: bool = false
@export var menu_center := Vector2(478, 265)
@export var menu_extent := Vector2(600, 360)
var world_seed: int = 0
var schools: Dictionary = {}
var batch: MultiMeshInstance2D
var _navigation = preload("res://scripts/survival/shark_navigation.gd").new()
var _last_cell := Vector2i(2147483647, 2147483647)
var _local_time := 0.0
var _offset := 0.0
var _target_offset := 0.0
var _has_clock := false
var _ship: Ship
var _render_material: ShaderMaterial
var visible_fish: int = 0
var _step := 1.0/60.0
var threats: Array[Vector3] = []
var claims: Dictionary = {}
var taken: Dictionary = {}
var returns: Dictionary = {}
var fishing_schools: Dictionary = {}

func fish_id(cell: Vector2i, index: int) -> String:
	return "%d:%d:%d" % [cell.x, cell.y, index]

func unavailable(id: String) -> bool:
	if claims.has(id) or float(taken.get(id, 0.0)) > shared_time(): return true
	if is_instance_valid(_ship):
		var services: Array = NetworkSession.services.values() if NetworkSession.online else [_ship.get_node("InventorySystem")]
		for service in services:
			if service.get_node("Fishing").catch_id == id: return true
	return false

func claim_near(point: Vector2, owner: int) -> Dictionary:
	if NetworkSession.online and not multiplayer.is_server(): return {}
	var now := shared_time()
	for id in returns.keys():
		if now >= float(returns[id].time)+float(returns[id].duration): returns.erase(id)
	for id in taken.keys():
		if float(taken[id]) <= now: taken.erase(id)
	# Reserve room for pending catches rather than evicting an unexpired cooldown.
	if taken.size() + claims.size() >= 256: return {}
	var cell := Vector2i((point / FishSchool.CELL_SIZE).floor())
	var best := {}
	var distance := 110.0
	for y in range(cell.y-1, cell.y+2):
		for x in range(cell.x-1, cell.x+2):
			var key := Vector2i(x,y)
			if not fishing_schools.has(key):
				if fishing_schools.size() >= 45: fishing_schools.erase(fishing_schools.keys()[0])
				var created := FishSchool.create(world_seed,key)
				created["water"] = _navigation.clear(created.center, FishSchool.CLEARANCE)
				fishing_schools[key] = created
			var school: Dictionary = fishing_schools[key]
			if not school.water or FishSchool.visibility(school,now) < 0.5: continue
			for i in school.members.size():
				var id := fish_id(key,i)
				if unavailable(id) or returns.has(id): continue
				var pose := FishSchool.pose(school,school.members[i],now)
				var gap := pose.origin.distance_to(point)
				if gap < distance:
					distance = gap
					best = {"id":id,"position":pose.origin,"species":school.species,"length":school.members[i].length,"angle":pose.get_rotation(),"phase":school.members[i].phase,"speed":school.members[i].speed}
	if not best.is_empty(): claims[best.id] = owner
	return best

func release_fish(id: String, owner: int, caught: bool) -> bool:
	if id.is_empty() or claims.get(id, -1) != owner: return false
	claims.erase(id)
	if caught:
		taken[id] = shared_time() + caught_respawn_seconds
	return true

func _ready() -> void:
	if not menu_mode:
		_ship = get_parent() as Ship
		set_as_top_level(true)
		global_transform = Transform2D.IDENTITY
		z_index = -15 # Above water, below islands, boats, swimmers and sharks.
	batch = MultiMeshInstance2D.new()
	batch.texture = FishAtlas.TEXTURE
	batch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_2D
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = max_fish
	instances.visible_instance_count = 0
	batch.multimesh = instances
	_render_material = FishAtlas.material()
	batch.material = _render_material
	add_child(batch)
	if menu_mode: configure(74219, [])
	elif is_instance_valid(_ship): configure(_ship.world_seed, _ship.islands_root.get_children())

func configure(seed_value: int, islands: Array) -> void:
	world_seed = seed_value
	schools.clear()
	fishing_schools.clear()
	claims.clear()
	taken.clear()
	returns.clear()
	_last_cell = Vector2i(2147483647, 2147483647)
	_navigation.obstacles.clear()
	for island in islands:
		if island is WorldIsland and not island.get_coast().is_empty():
			_navigation.obstacles.append(island.get_coast())
	_navigation.prepare()

func synchronize(host_time: float) -> void:
	if not is_finite(host_time) or host_time < 0.0: return
	_target_offset = host_time - Time.get_ticks_msec() / 1000.0
	if not _has_clock:
		_offset = _target_offset
		_has_clock = true

func shared_time() -> float:
	return Time.get_ticks_msec() / 1000.0 + _offset

func refresh(center: Vector2) -> void:
	if menu_mode:
		if not schools.is_empty(): return
		# A loose screen-wide grid prevents same-species clumps around a few cells.
		for row in 2:
			for column in 6:
				var at := Vector2(65.0+column*165.0,105.0+row*320.0)
				var school := FishSchool.create_menu(world_seed,row*6+column,at)
				school.water = true
				school.arrival = _local_time
				schools[Vector2i(column,row)] = school
		return
	var cell := Vector2i((center / FishSchool.CELL_SIZE).floor())
	if cell == _last_cell: return
	_last_cell = cell
	# Fixed 5x5 window, independent of travel distance; menus use denser populations.
	for key: Vector2i in schools.keys():
		if absi(key.x-cell.x) > 2 or absi(key.y-cell.y) > 2: schools.erase(key)
	for y in range(cell.y-2, cell.y+3):
		for x in range(cell.x-2, cell.x+3):
			var key := Vector2i(x, y)
			if schools.has(key): continue
			var school := FishSchool.create(world_seed, key)
			# Reserve the entire wandering envelope once, never run per-fish physics.
			school["water"] = _navigation.clear(school.center, FishSchool.CLEARANCE)
			school["arrival"] = _local_time
			schools[key] = school

func _process(delta: float) -> void:
	_step = minf(delta, 0.1)
	_local_time += delta
	_offset = move_toward(_offset, _target_offset, delta * 0.08)
	var center := menu_center
	var extent := menu_extent
	if not menu_mode:
		if NetworkSession.online and not multiplayer.is_server() and not _has_clock:
			batch.multimesh.visible_instance_count = 0
			return
		var camera := get_viewport().get_camera_2d()
		if is_instance_valid(camera):
			center = camera.get_screen_center_position()
			extent = get_viewport_rect().size / camera.zoom * 0.5
		elif is_instance_valid(_ship): center = _ship.global_position
	refresh(center)
	update_threats()
	var reduced: bool = GameWindow.preferences.reduced_motion
	# Accessibility preferences must never change multiplayer world positions.
	var time := (30.0 if reduced else _local_time) if menu_mode else shared_time()
	render_fish(center, extent, time)

func update_threats() -> void:
	threats.clear()
	if menu_mode or not is_instance_valid(_ship): return
	# Capsule-like coverage of the boat, using already replicated boat/crew transforms.
	for y in [-160.0, 0.0, 160.0]:
		var at := _ship.to_global(Vector2(0, y))
		threats.append(Vector3(at.x, at.y, 150.0))
	if is_instance_valid(_ship.rowboat) and _ship.rowboat.visible:
		var at := _ship.rowboat.global_position
		threats.append(Vector3(at.x, at.y, 100.0))
	var people: Array = NetworkSession.players.values() if NetworkSession.online else [_ship.player]
	for player in people:
		if is_instance_valid(player) and player.is_overboard and not player.on_land:
			var at: Vector2 = player.global_position
			threats.append(Vector3(at.x, at.y, 115.0))

func animate_member(member: Dictionary, target: Transform2D) -> Transform2D:
	if not member.has("visual_position"):
		member["visual_position"] = target.origin
		member["visual_angle"] = target.get_rotation()
		member["tail_frame"] = float(member.phase)/TAU*4.0
		member["visual_speed"] = 0.0
	var before: Vector2 = member.visual_position
	var desired := before.lerp(target.origin, 1.0-exp(-8.0*_step))
	var after := before.move_toward(desired, maxf(65.0,float(member.speed)*1.8)*_step)
	var velocity := (after-before)/maxf(_step, 0.0001)
	var heading := velocity.angle()+PI*0.5 if velocity.length() > 2.0 else float(member.visual_angle)
	member.visual_angle = rotate_toward(float(member.visual_angle), heading, _step*3.5)
	member.visual_position = after
	member.visual_speed = lerpf(float(member.visual_speed), velocity.length(), 1.0-exp(-6.0*_step))
	if not GameWindow.preferences.reduced_motion:
		# Integrate phase rather than multiplying time by a changing rate (which jumps).
		member.tail_frame = fposmod(float(member.tail_frame)+FishSchool.animation_rate(member.visual_speed, member.length)*_step, 4.0)
	return Transform2D(member.visual_angle, after)

func render_fish(center: Vector2, extent: Vector2, time: float) -> void:
	var count := 0
	for cell: Vector2i in schools:
		var school: Dictionary = schools[cell]
		if not school.water: continue
		var alpha := FishSchool.visibility(school, time) * smoothstep(0.0, arrival_seconds, _local_time-float(school.arrival))
		for index in school.members.size():
			var member: Dictionary = school.members[index]
			if not menu_mode and unavailable(fish_id(cell,index)): continue
			var pose := FishSchool.pose(school, member, time)
			var returning: Dictionary = returns.get(fish_id(cell,index),{})
			if not menu_mode and not returning.is_empty():
				var distance: float = returning.position.distance_to(pose.origin)
				var blend := clampf((time-float(returning.time))/maxf(0.6,float(returning.duration)),0.0,1.0)
				if distance < 600.0 and blend < 1.0:
					pose = Transform2D(lerp_angle(returning.angle,pose.get_rotation(),blend),Vector2(returning.position).lerp(pose.origin,blend))
			if menu_mode: pose = animate_member(member, pose)
			else: member["tail_frame"] = fposmod(time * FishSchool.animation_rate(member.speed, member.length) + member.phase, 4.0)
			if alpha < 0.005: continue
			var distance := (pose.origin-center).abs()
			# Fade before the recycled-cell boundary even on unusually wide screens.
			var edge := extent.min(Vector2.ONE * 780.0)
			var fade := 1.0-smoothstep(0.0, 130.0, maxf(distance.x-edge.x, distance.y-edge.y))
			if fade * alpha < 0.005: continue
			if count >= max_fish: break
			var size := float(member.length) / 0.65
			pose.x *= size
			pose.y *= size
			batch.multimesh.set_instance_transform_2d(count, pose)
			batch.multimesh.set_instance_custom_data(count, Color((float(school.species)+0.5)/6.0, float(member.tail_frame)/4.0, fade*alpha, 0.0))
			count += 1
	batch.multimesh.visible_instance_count = count
	visible_fish = count
