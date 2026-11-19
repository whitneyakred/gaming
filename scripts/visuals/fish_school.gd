class_name FishSchool
extends RefCounted
## Stateless world-space paths: seed + cell + host time reproduce the same fish.
const CELL_SIZE := 480.0
const CLEARANCE := 435.0
const ESCAPE_RANGE := 180.0
const COUNTS := [2, 1, 2, 1, 1, 1]
const LENGTHS := [23.0, 30.0, 34.0, 22.0, 27.0, 41.0]

static func cell_seed(world_seed: int, cell: Vector2i) -> int:
	return posmod(world_seed + cell.x * 73856093 + cell.y * 19349663, 2147483647)

static func create(world_seed: int, cell: Vector2i, density: int = 1, species_override: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = cell_seed(world_seed, cell)
	var species := rng.randi_range(0, 5)
	if species_override >= 0: species = species_override
	var members: Array[Dictionary] = []
	for i in COUNTS[species] * density:
		var member := {"length": LENGTHS[species] * rng.randf_range(0.72, 1.25), "phase": rng.randf_range(0, TAU),
			"speed": rng.randf_range(24.0, 43.0) * (0.72 if species == 3 else 1.0)}
		build_route(member, rng)
		members.append(member)
	return {"seed": rng.randi_range(1, 1000000), "species": species, "members": members,
		"center": (Vector2(cell) + Vector2.ONE * 0.5) * CELL_SIZE + Vector2(rng.randf_range(-35, 35), rng.randf_range(-35, 35)),
		"phase": rng.randf_range(0, 200),
		"period": rng.randf_range(75, 110)}

static func create_menu(seed_value: int, index: int, center: Vector2) -> Dictionary:
	# Six columns permute all species per row: red never dominates one region.
	var species := (index % 6 + (index / 6)*2) % 6
	var school := create(seed_value, Vector2i(index, -71), 1, species)
	school.members.resize(1)
	school.center = center
	var member: Dictionary = school.members[0]
	var path: PackedVector2Array = member.path
	var distances: PackedFloat32Array = member.distances
	for i in path.size(): path[i] *= 0.32
	for i in distances.size(): distances[i] *= 0.32
	member.path = path
	member.distances = distances
	member.start = float(member.start)*0.32
	member.speed = float(member.speed)*0.7
	return school

static func build_route(member: Dictionary, rng: RandomNumberGenerator) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var point := Vector2.ZERO
		for attempt in 32:
			point = Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(75, 140)
			if i == 0 or point.distance_to(points[-1]) > 125.0: break
		points.append(point)
	var curve := Curve2D.new()
	curve.bake_interval = 4.0
	for i in 11:
		var index := i % 10
		var tangent := (points[(index+1)%10] - points[(index+9)%10]) / 6.0
		curve.add_point(points[index], -tangent, tangent)
	var path := curve.get_baked_points()
	var distances := PackedFloat32Array([0.0])
	for i in range(1, path.size()): distances.append(distances[-1] + path[i-1].distance_to(path[i]))
	member["path"] = path
	member["distances"] = distances
	member["start"] = rng.randf() * distances[-1]

static func route_point(member: Dictionary, distance: float) -> Vector2:
	var distances: PackedFloat32Array = member.distances
	var path: PackedVector2Array = member.path
	var at := fposmod(distance, distances[-1])
	var low := 0
	var high := distances.size()-1
	while high-low > 1:
		var middle := (low+high)/2
		if distances[middle] <= at: low = middle
		else: high = middle
	return path[low].lerp(path[high], (at-distances[low])/maxf(0.001, distances[high]-distances[low]))

static func pose(school: Dictionary, member: Dictionary, time: float) -> Transform2D:
	# Arc-length sampling prevents vigorous tail beats on almost stationary spline bends.
	# Each fish has its own route, phase and gentle acceleration/gliding rhythm.
	var distance := float(member.start) + float(member.speed) * (time + 0.28/0.7 * sin(time*0.7+float(member.phase)))
	var point := route_point(member, distance)
	var direction := route_point(member, distance+5.0)-route_point(member, distance-5.0)
	return Transform2D(direction.angle()+PI*0.5, Vector2(school.center)+point)

static func advance_escape(member: Dictionary, base: Transform2D, threats: Array[Vector3], delta: float) -> Vector2:
	var offset: Vector2 = member.get("escape_offset", Vector2.ZERO)
	var velocity: Vector2 = member.get("escape_velocity", Vector2.ZERO)
	var base_velocity := (base.origin-Vector2(member.get("escape_base", base.origin)))/maxf(delta,0.0001)
	member.escape_base = base.origin
	var point := base.origin+offset
	var flee := Vector2.ZERO
	var blocked := false
	for threat in threats:
		var at := Vector2(threat.x, threat.y)
		var away := point-at
		if away.length() < threat.z:
			var direction := away.normalized() if away.length() > 1.0 else -base.y
			flee += direction*(1.0-smoothstep(threat.z*0.35,threat.z,away.length()))
		# Do not pull a fish back through the player or boat to reach its old route.
		if Geometry2D.get_closest_point_to_segment(at,point,base.origin).distance_to(at) < threat.z+20.0:
			blocked = true
	var hold := maxf(0.0,float(member.get("escape_hold",0.0))-delta)
	var desired := Vector2.ZERO
	if blocked: hold = 3.0
	if flee.length() > 0.01:
		hold = 3.0
		desired = (flee.limit_length(1.0)*65.0-base_velocity).limit_length(100.0)
	elif hold <= 0.0:
		desired = -offset.normalized()*minf(12.0,offset.length()*0.35)
	velocity = velocity.move_toward(desired,45.0*delta)
	var next := offset+velocity*delta
	if next.length() > ESCAPE_RANGE:
		next = next.limit_length(ESCAPE_RANGE)
		velocity -= next.normalized()*maxf(0.0,velocity.dot(next.normalized()))
	member.escape_hold = hold
	member.escape_offset = next
	member.escape_velocity = velocity
	return next

static func animation_rate(speed: float, length: float) -> float:
	# Frames/second: slow glide at rest, measured body-lengths/second while swimming.
	return clampf(speed/maxf(length, 1.0) * 2.0, 0.0, 5.0)

static func visibility(school: Dictionary, time: float) -> float:
	var phase := fposmod(time + float(school.phase), float(school.period))
	return smoothstep(0.0, 4.0, phase) * (1.0 - smoothstep(float(school.period)-9.0, float(school.period)-4.0, phase))
