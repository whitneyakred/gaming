class_name SurvivalWorld
extends Node2D
## The host alone advances health, danger timers and the shared shark pack.
@export var red_water_seconds: float = 15.0
@export var shark_delay: float = 4.0
@export var shark_delay_variation: float = 4.0
## Water deaths within this many world pixels recover inventory on shore.
@export_range(0.0, 400.0) var shore_drop_distance: float = 120.0
var arrival_delays: Dictionary = {}
var medical: Dictionary = {}
@export_range(1.0, 2.0) var largest_shark_scale: float = 1.75
@export_range(1, 3) var sharks_per_swimmer: int = 2
const MAX_SHARKS := 8
var sharks: Array[Dictionary] = []
var visual_positions: Array[Vector2] = []
var visual_angles: Array[float] = []
var visual_alpha: Array[float] = []
@export var idle_food_seconds: float = 100.0
@export var walking_food_seconds: float = 75.0
@export var swimming_food_seconds: float = 38.0
@export var regeneration_seconds: float = 12.0
var ship_danger := 0.0
var sink_serial := 0
var time := 0.0
var shark_visuals: Array[SharkVisual] = []
var wreck_position := Vector2.ZERO
var wreck_rotation := 0.0
var hud: Control
@onready var ship: Ship = get_parent()

func _ready() -> void:
	set_as_top_level(true)
	global_transform = Transform2D.IDENTITY
	z_index = 5
	shark_rng.randomize()
	ensure_sharks(2)
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	hud = load("res://scripts/survival/survival_hud.gd").new()
	hud.world = self
	layer.add_child(hud)

const NAVIGATION = preload("res://scripts/survival/shark_navigation.gd")
var navigation = NAVIGATION.new()
var navigation_seed := -1
var navigation_version := -1
var routes: Dictionary = {}
var route_timers: Dictionary = {}
var shark_rng := RandomNumberGenerator.new()

func ensure_sharks(count: int) -> void:
	while sharks.size() < count:
		var index := sharks.size()
		var body_size := shark_rng.randf_range(1.0, largest_shark_scale)
		sharks.append({"position": Vector2.ZERO, "target": 0, "angle": 0.0, "active": false, "mode": "arrive", "clock": 0.0, "orbit": 0.0, "aim": Vector2.ZERO, "bitten": false, "alpha": 0.0, "size": body_size, "pace": shark_rng.randf_range(0.9, 1.1), "patience": shark_rng.randf_range(0.8, 1.6), "side": 1.0 if index % 2 == 0 else -1.0})
		visual_positions.append(Vector2.ZERO)
		visual_angles.append(0.0)
		visual_alpha.append(0.0)
		var visual := SharkVisual.new()
		add_child(visual)
		visual.visible = false
		shark_visuals.append(visual)

func move_shark(index: int, goal: Vector2, speed: float, delta: float) -> void:
	var shark: Dictionary = sharks[index]
	var at: Vector2 = shark.position
	var radius := 24.0 * float(shark.get("size", 1.0))
	route_timers[index] = float(route_timers.get(index, 0.0)) - delta
	var waypoint := goal
	if not navigation.segment(at, goal, radius):
		if float(route_timers[index]) <= 0 or not routes.has(index):
			routes[index] = navigation.route(at, goal, radius)
			route_timers[index] = 0.9 + float(index) * 0.07
		var path: PackedVector2Array = routes[index]
		while path.size() > 1 and at.distance_to(path[0]) < 55:
			path.remove_at(0)
		if path.is_empty(): return
		waypoint = path[0]
		# Skip reachable corners to avoid robotic cell-to-cell swimming.
		while path.size() > 1 and navigation.segment(at, path[1], radius):
			path.remove_at(0)
			waypoint = path[0]
		routes[index] = path
	else:
		routes.erase(index)
	var direction := waypoint - at
	if direction.length() < 2: return
	shark.angle = rotate_toward(float(shark.angle), direction.angle(), delta * 4.2 / sqrt(float(shark.get("size", 1.0))))
	var alignment := maxf(0.15, Vector2.from_angle(shark.angle).dot(direction.normalized()))
	var next := at + Vector2.from_angle(shark.angle) * minf(speed * delta * alignment, direction.length())
	if navigation.segment(at, next, radius) or (not navigation.clear(at, radius) and next.distance_to(waypoint) < at.distance_to(waypoint)):
		shark.position = next
	else:
		route_timers[index] = 0.0


func crew() -> Dictionary:
	return NetworkSession.players if NetworkSession.online else {1: ship.player}

func service_for(id: int) -> InventoryService:
	return NetworkSession.services.get(id) if NetworkSession.online else ship.get_node("InventorySystem")

func _physics_process(delta: float) -> void:
	if NetworkSession.online and (not multiplayer.is_server() or not NetworkSession.world_ready): return
	advance(delta)

func advance(delta: float) -> void:
	var people := crew()
	ship_danger = ship_danger + delta if WorldLayout.danger(ship.global_position) else 0.0
	if ship_danger >= red_water_seconds:
		sink()
		return
	for id in people:
		var player: CharacterBody2D = people[id]
		if player.island_challenge:
			player.swim_time = 0.0
			continue
		if player.health <= 0:
			player.swim_time = 0.0
			continue
		if player.is_overboard:
			for island_id in MapState.island_catalog:
				if MapState.discovered_islands.has(island_id): continue
				var island: Dictionary = MapState.island_catalog[island_id]
				if player.global_position.distance_to(island.position) < 950:
					MapState.discover_island(island_id, island.name, island.position)
		advance_metabolism(id, delta)
		var swimming: bool = player.is_overboard and not player.on_land
		player.swim_time = player.swim_time + delta if swimming else 0.0
		player.danger_time = player.danger_time + delta if swimming and WorldLayout.danger(player.global_position) else 0.0
		if player.danger_time >= red_water_seconds: damage(id, 15)
	advance_sharks(delta, people)

func advance_sharks(delta: float, people: Dictionary) -> void:
	var eligible: Array[int] = []
	for id in people:
		var person = people[id]
		if person.health > 0 and person.is_overboard and not person.on_land and not person.island_challenge:
			if not arrival_delays.has(id): arrival_delays[id] = shark_rng.randf_range(shark_delay, shark_delay + shark_delay_variation)
			var lingering := sharks.any(func(shark: Dictionary): return shark.active and shark.get("last_target",0) == id)
			if lingering or person.swim_time >= float(arrival_delays[id]): eligible.append(id)
		else: arrival_delays.erase(id)
	for id in arrival_delays.keys():
		if not people.has(id): arrival_delays.erase(id)
	ensure_sharks(mini(MAX_SHARKS, maxi(2, eligible.size() * sharks_per_swimmer)))
	var hull := ship.get_hull_polygon(ship.global_position,ship.global_rotation)
	if navigation_seed != ship.world_seed or navigation_version != ship.layout_version:
		navigation_seed = ship.world_seed
		navigation_version = ship.layout_version
		navigation.obstacles.clear()
		navigation.obstacles.append(hull)
		for island in ship.get_islands(): navigation.obstacles.append(island.get_coast())
		navigation.prepare()
		routes.clear()
		route_timers.clear()
	else:
		navigation.obstacles[0] = hull
		var bounds := Rect2(hull[0],Vector2.ZERO)
		for point in hull: bounds = bounds.expand(point)
		navigation.bounds[0] = bounds
	var claimed := {}
	for index in sharks.size():
		var shark: Dictionary = sharks[index]
		var target := 0
		var nearest := INF
		for id in eligible:
			if int(claimed.get(id, 0)) >= sharks_per_swimmer: continue
			var distance: float = Vector2(shark.position).distance_squared_to(people[id].global_position)
			# A little loyalty prevents rapid switching between nearby swimmers.
			if int(shark.target) == id: distance *= 0.8
			if distance < nearest: nearest = distance; target = id
		if target == 0:
			if not shark.active: continue
			if shark.mode != "depart":
				shark.mode = "depart"
				shark.clock = 0.0
				var away := (Vector2(shark.position) - ship.global_position).normalized()
				if int(shark.target) in people:
					away = (Vector2(shark.position) - people[int(shark.target)].global_position).normalized()
				if away.is_zero_approx(): away = Vector2.from_angle(shark.angle)
				shark.aim = Vector2(shark.position) + away * 900
				for attempt in 16:
					var escape := Vector2(shark.position) + away.rotated(attempt * TAU / 16) * 900
					if navigation.clear(escape, 45): shark.aim = escape; break
			shark.target = 0
			shark.clock = float(shark.clock) + delta
			var lingering := float(shark.clock) < 3.5
			var goal: Vector2 = Vector2(shark.position) + Vector2.from_angle(float(shark.angle) + 0.7) * 90 if lingering else Vector2(shark.aim)
			move_shark(index, goal, (75.0 if lingering else 190.0) * float(shark.get("pace", 1.0)), delta)
			if not lingering: shark.alpha = move_toward(float(shark.alpha), 0, delta * 0.4)
			shark.active = float(shark.alpha) > 0 or lingering
			continue
		claimed[target] = int(claimed.get(target, 0)) + 1
		var player: CharacterBody2D = people[target]
		if int(shark.target) != target:
			shark.mode = "arrive"
			shark.clock = 0.0
			shark.orbit = float(index)*PI
			if not shark.active:
				for attempt in 24:
					var spawn: Vector2 = player.global_position + Vector2(1500,0).rotated(float(attempt+index*12)*TAU/24.0)
					if navigation.clear(spawn, 45): shark.position = spawn; break
				shark.angle = (player.global_position-Vector2(shark.position)).angle()
				shark.alpha = 0.0
		shark.target = target
		shark["last_target"] = target
		shark.active = true
		shark.clock = float(shark.clock) + delta
		var goal: Vector2 = player.global_position
		var speed := 210.0
		var visible_target := 1.0
		match str(shark.mode):
			"arrive":
				if Vector2(shark.position).distance_to(goal)<210:
					shark.mode = "circle"; shark.clock = 0.0
					shark.orbit = (Vector2(shark.position)-goal).angle()
			"circle":
				shark.orbit = float(shark.orbit) + delta * (0.85 * float(shark.get("side", 1.0)) * float(shark.get("pace", 1.0)))
				goal += Vector2.from_angle(shark.orbit) * (145.0 + 30.0 * float(shark.get("size", 1.0)))
				speed = 150.0
				if float(shark.clock)>float(shark.get("patience", 4.0)):
					shark.mode = "dive"; shark.clock = 0.0
					shark.aim = player.global_position + player.velocity * 0.3
					shark.bitten = false
			"dive":
				visible_target = 0.2
				goal = shark.aim
				speed = 75.0
				if float(shark.clock)>0.3: shark.mode="lunge"; shark.clock=0.0
			"lunge":
				if float(shark.clock) < 0.6: shark.aim = player.global_position + player.velocity * 0.25
				goal = shark.aim
				speed = 380.0
				visible_target = 0.55
				if not shark.bitten and Vector2(shark.position).distance_to(player.global_position)<42 * float(shark.get("size", 1.0)) and navigation.segment(shark.position, player.global_position, 0):
					damage(target, maxi(2, roundi(pow(float(shark.get("size", 1.0)), 2)))); shark.bitten=true
				if float(shark.clock)>1.5 or Vector2(shark.position).distance_to(goal)<16:
					shark.mode="retreat"; shark.clock=0.0
					shark.aim = Vector2(shark.position)+Vector2.from_angle(shark.angle)*230
			"retreat":
				goal = shark.aim
				speed = 170.0
				if float(shark.clock)>0.7:
					shark.mode="circle"; shark.clock=0.0
					shark.orbit=(Vector2(shark.position)-player.global_position).angle()
		shark.alpha = move_toward(float(shark.alpha),visible_target,delta*1.2)
		move_shark(index, goal, speed * float(shark.get("pace", 1.0)), delta)

func advance_metabolism(id: int, delta: float) -> void:
	var player: CharacterBody2D = crew()[id]
	if player.health <= 0: return
	player.eat_cooldown = maxf(0,player.eat_cooldown-delta)
	var seconds := idle_food_seconds
	if player.is_overboard and not player.on_land: seconds=swimming_food_seconds
	elif player.velocity.length()>1: seconds=walking_food_seconds
	player.hunger_clock += delta/seconds
	while player.hunger_clock>=1.0:
		player.hunger_clock-=1.0
		player.hunger=maxi(0,player.hunger-1)
	if player.hunger==0:
		player.regen_clock=0.0
		player.starvation_clock+=delta
		while player.starvation_clock>=2.0 and player.hunger==0:
			player.starvation_clock-=2.0
			damage(id,1)
	else:
		player.starvation_clock=0.0
		if player.hunger==15 and player.health<15:
			player.regen_clock+=delta
			if player.regen_clock>=regeneration_seconds:
				player.regen_clock-=regeneration_seconds
				player.health=mini(15,player.health+1)
		else: player.regen_clock=0.0

func eat(id: int, slot: int) -> bool:
	if NetworkSession.online and not multiplayer.is_server(): return false
	var service := service_for(id)
	if not service or not service.can_handle_items() or service.hud.storage_open or service.hud.grill_open: return false
	var player: CharacterBody2D = crew()[id]
	if player.fishing_active or player.hunger>=15 or player.eat_cooldown>0 or slot != service.hud.selected: return false
	var entries := service.inventory.capture()
	if slot<0 or slot>=entries.size(): return false
	var item: StringName = entries[slot].get("id", &"")
	if item not in [&"fish_cod", &"dried_fish"]: return false
	service.inventory.remove(slot,1)
	player.hunger=mini(15,player.hunger+(1 if item==&"fish_cod" else 3))
	player.eat_cooldown=0.65
	player.eat_serial+=1
	return true

func medpack(id: int, action: String, slot: int) -> bool:
	if NetworkSession.online and not multiplayer.is_server(): return false
	if action == "cancel": medical.erase(id); return true
	var service := service_for(id)
	if service == null or not service.can_handle_items() or service.hud.storage_open or service.hud.grill_open: medical.erase(id); return false
	var player: CharacterBody2D = crew().get(id)
	if player == null or player.health <= 0 or player.health >= 15 or player.fishing_active or slot != service.hud.selected: medical.erase(id); return false
	if slot < 0 or slot >= service.inventory.slots.size() or service.inventory.slots[slot].get("id") != &"medpack": medical.erase(id); return false
	if action == "start":
		medical[id] = {"time":Time.get_ticks_msec(),"slot":slot,"revision":service.view_revision}
		return true
	var hold: Dictionary = medical.get(id,{})
	medical.erase(id)
	if action != "finish" or hold.is_empty() or hold.slot != slot or hold.revision != service.view_revision: return false
	var elapsed := Time.get_ticks_msec()-int(hold.time)
	if elapsed < 1800 or elapsed > 6000: return false
	service.inventory.remove(slot,1)
	player.health = 15
	player.heal_serial += 1
	return true

func damage(id: int, amount: int) -> void:
	var people := crew()
	if not people.has(id): return
	var player: CharacterBody2D = people[id]
	if player.health <= 0: return
	player.health = maxi(0, player.health - amount)
	player.hurt_serial += 1
	if player.health == 0:
		stop_actions(id)
		drop_death_inventory(id)
		player.velocity = Vector2.ZERO
		player.swim_time = 0.0

func death_drop_location(player: CharacterBody2D) -> Dictionary:
	# Deck drops stay in ship-local coordinates, even while the ship moves.
	if not player.is_overboard:
		return {"position":player.position,"world":false}
	var point := player.global_position
	var nearest := shore_drop_distance
	var result := {}
	for island in ship.get_islands():
		var coast := island.get_coast()
		if Geometry2D.is_point_in_polygon(point,coast):
			return {"position":point,"world":true}
		for i in coast.size():
			var a := coast[i]
			var b := coast[(i+1)%coast.size()]
			var edge := Geometry2D.get_closest_point_to_segment(point,a,b)
			var distance := point.distance_to(edge)
			if distance > nearest or a.is_equal_approx(b): continue
			var normal := (b-a).normalized().orthogonal()
			# Test both sides rather than assuming coastline winding or convexity.
			for inset in [12.0,4.0,1.0]:
				for side in [-1.0,1.0]:
					var landing: Vector2 = edge+normal*inset*side
					if Geometry2D.is_point_in_polygon(landing,coast):
						nearest = distance
						result = {"position":landing,"world":true}
						break
				if not result.is_empty() and nearest == distance: break
	return result

func drop_death_inventory(id: int) -> void:
	if NetworkSession.online and not multiplayer.is_server(): return
	var player: CharacterBody2D = crew()[id]
	var service := service_for(id)
	var location := death_drop_location(player)
	var carried: Array[Dictionary] = player.player_inventory.capture()
	player.player_inventory.clear()
	medical.erase(id)
	if service != null and not location.is_empty():
		for entry in carried:
			if entry.is_empty(): continue
			var drop_id := NetworkSession.dropped_id if NetworkSession.online else service.next_drop_id
			service._spawn_drop(entry,location.position)
			service.drops[drop_id]["world"] = location.world
	# Lost-at-sea keys become available at their original solved pedestal again.
	# Ground keys, keys in other bags/chests and inserted keys remain accounted for.
	VoyageState.reconcile_keys()

func stop_actions(id: int) -> void:
	var service := service_for(id)
	if service:
		service.get_node("Fishing").cancel()
		service.hud.close()
	var player: CharacterBody2D = crew()[id]
	if player.using_station: player.active_station.release_control()
	player.active_station = null
	player.inventory_open = false

func respawn(id: int) -> void:
	stop_actions(id)
	var player: CharacterBody2D = crew()[id]
	var empty: Array[Dictionary] = []
	player.player_inventory.restore(empty)
	player.set_overboard(false)
	player.update_land(false)
	player.position = Vector2(0, 70)
	player.health = 15
	player.hunger = 15
	player.hunger_clock = 0.0
	player.starvation_clock = 0.0
	player.regen_clock = 0.0
	player.swim_time = 0.0
	player.danger_time = 0.0
	player.respawn_serial += 1

func sink() -> void:
	var people := crew()
	for id in people:
		var player: CharacterBody2D = people[id]
		if not player.is_overboard:
			var at := ship.to_global(Vector2(-150, 20 + 30 * int(id) % 100))
			stop_actions(id)
			player.set_overboard(true)
			player.update_land(false)
			player.global_position = at
			player.swim_time = 0.0
			player.danger_time = 0.0
	var empty: Array[Dictionary] = []
	VoyageState.get_ship_storage().restore(empty)
	VoyageState.floor_items.get("ship", {}).clear()
	ship.get_node("Cooking").restore({"starter": true})
	show_wreck(ship.global_position, ship.global_rotation)
	ship.speed = 0.0
	ship.turn_rate = 0.0
	ship.global_position = Vector2.ZERO
	ship.global_rotation = 0.0
	ship.anchor_deployed = true
	ship.set_sail_level(0)
	ship.set_wheel_angle(0)
	ship_danger = 0
	sink_serial += 1
	if NetworkSession.online: NetworkSession.save_world.call_deferred()

func capture() -> Dictionary:
	return {"sharks": sharks.duplicate(true), "danger": ship_danger, "sink": sink_serial, "wreck": wreck_position, "wreck_rotation": wreck_rotation}

func restore(data: Dictionary) -> void:
	ship_danger = data.get("danger", 0.0)
	var next_sink: int = data.get("sink", 0)
	if next_sink != sink_serial: show_wreck(data.get("wreck", Vector2.ZERO), data.get("wreck_rotation", 0.0))
	sink_serial = next_sink
	var states: Array = data.get("sharks", [])
	ensure_sharks(mini(states.size(), MAX_SHARKS))
	for i in mini(states.size(), sharks.size()):
		sharks[i] = states[i].duplicate()
	for i in range(states.size(), sharks.size()):
		sharks[i].alpha = 0.0
		sharks[i].active = false

func _process(delta: float) -> void:
	time += delta
	for i in sharks.size():
		var target: Vector2 = sharks[i].position
		visual_angles[i] = lerp_angle(visual_angles[i],float(sharks[i].angle),1.0-exp(-10*delta))
		visual_alpha[i] = move_toward(visual_alpha[i],float(sharks[i].get("alpha",0)),delta*1.5)
		visual_positions[i] = visual_positions[i].lerp(target, 1.0-exp(-16.0*delta)) if visual_positions[i].distance_to(target)<300 else target
	for i in shark_visuals.size():
		var visual := shark_visuals[i]
		visual.scale = Vector2.ONE * float(sharks[i].get("size", 1.0))
		visual.position = visual_positions[i]
		visual.rotation = visual_angles[i] + PI*0.5
		visual.modulate.a = visual_alpha[i]
		visual.visible = visual_alpha[i] > 0.01
		visual.set_swim_time(0.0 if GameWindow.preferences.reduced_motion else time, i)

func show_wreck(at: Vector2, angle: float) -> void:
	wreck_position = at
	wreck_rotation = angle
	var ghost := Sprite2D.new()
	ghost.texture = ship.get_node("ShipSprite").texture
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.scale = Vector2(2,2)
	ghost.position = at
	ghost.rotation = angle
	add_child(ghost)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ghost,"modulate",Color(0.3,0.4,0.5,0),2.0)
	tween.tween_property(ghost,"scale",Vector2(1.7,1.7),2.0)
	tween.chain().tween_callback(ghost.queue_free)

func is_water(point: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(point, ship.get_hull_polygon(ship.global_position, ship.global_rotation)): return false
	for island in ship.get_islands():
		if Geometry2D.is_point_in_polygon(point, island.get_coast()): return false
	return true
