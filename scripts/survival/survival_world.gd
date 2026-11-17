class_name SurvivalWorld
extends Node2D
## The host alone advances health, danger timers and the two shared sharks.
@export var red_water_seconds: float = 15.0
@export var shark_delay: float = 10.0
var sharks: Array[Dictionary] = []
var visual_positions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var visual_angles: Array[float] = [0.0,0.0]
var visual_alpha: Array[float] = [0.0,0.0]
@export var idle_food_seconds: float = 120.0
@export var walking_food_seconds: float = 90.0
@export var swimming_food_seconds: float = 45.0
@export var regeneration_seconds: float = 12.0
var ship_danger := 0.0
var sink_serial := 0
var time := 0.0
var wreck_position := Vector2.ZERO
var wreck_rotation := 0.0
var hud: Control
@onready var ship: Ship = get_parent()

func _ready() -> void:
	set_as_top_level(true)
	global_transform = Transform2D.IDENTITY
	z_index = 5
	for i in 2:
		sharks.append({"position": Vector2.ZERO, "target": 0, "angle": 0.0, "cooldown": 0.0, "active": false, "mode": "arrive", "clock": 0.0, "orbit": 0.0, "aim": Vector2.ZERO, "bitten": false, "alpha": 0.0})
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	hud = load("res://scripts/survival/survival_hud.gd").new()
	hud.world = self
	layer.add_child(hud)

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
	var claimed := {}
	for index in sharks.size():
		var shark: Dictionary = sharks[index]
		var target: int = shark.target
		if not people.has(target) or people[target].swim_time < shark_delay or claimed.has(target):
			target = 0
			for id in people:
				if people[id].swim_time >= shark_delay and not claimed.has(id): target = id; break
		if target == 0:
			shark.alpha = move_toward(float(shark.alpha),0,delta*0.65)
			shark.active = float(shark.alpha)>0
			shark.target = 0
			continue
		claimed[target] = true
		var player: CharacterBody2D = people[target]
		if int(shark.target) != target:
			shark.mode = "arrive"
			shark.clock = 0.0
			shark.orbit = float(index)*PI
			if not shark.active:
				for attempt in 24:
					var spawn: Vector2 = player.global_position + Vector2(1800,0).rotated(float(attempt+index*12)*TAU/24.0)
					if is_water(spawn): shark.position = spawn; break
				shark.angle = (player.global_position-Vector2(shark.position)).angle()
				shark.alpha = 0.0
		shark.target = target
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
				shark.orbit = float(shark.orbit) + delta * (0.95 if index==0 else -0.95)
				goal += Vector2.from_angle(shark.orbit) * 155.0
				speed = 150.0
				if float(shark.clock)>3.8+index*0.7:
					shark.mode = "dive"; shark.clock = 0.0
					shark.aim = player.global_position + player.velocity * 0.3
					shark.bitten = false
			"dive":
				visible_target = 0.2
				goal = shark.aim
				speed = 75.0
				if float(shark.clock)>0.65: shark.mode="lunge"; shark.clock=0.0
			"lunge":
				goal = shark.aim
				speed = 300.0
				visible_target = 0.55
				if not shark.bitten and Vector2(shark.position).distance_to(player.global_position)<32:
					damage(target,1); shark.bitten=true
				if float(shark.clock)>1.5 or Vector2(shark.position).distance_to(goal)<16:
					shark.mode="retreat"; shark.clock=0.0
					shark.aim = Vector2(shark.position)+Vector2.from_angle(shark.angle)*230
			"retreat":
				goal = shark.aim
				speed = 170.0
				if float(shark.clock)>2.0:
					shark.mode="circle"; shark.clock=0.0
					shark.orbit=(Vector2(shark.position)-player.global_position).angle()
		shark.alpha = move_toward(float(shark.alpha),visible_target,delta*1.2)
		var desired := (goal-Vector2(shark.position)).angle()
		shark.angle = rotate_toward(float(shark.angle),desired,delta*3.0)
		var step := minf(speed*delta, Vector2(shark.position).distance_to(goal))
		for turn in [0.0,0.7,-0.7,1.4,-1.4]:
			var next: Vector2 = Vector2(shark.position)+Vector2.from_angle(float(shark.angle)+turn)*step
			if is_water(next): shark.position=next; break

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

func damage(id: int, amount: int) -> void:
	var people := crew()
	if not people.has(id): return
	var player: CharacterBody2D = people[id]
	if player.health <= 0: return
	player.health = maxi(0, player.health - amount)
	player.hurt_serial += 1
	if player.health == 0:
		stop_actions(id)
		var empty: Array[Dictionary] = []
		player.player_inventory.restore(empty)
		player.velocity = Vector2.ZERO
		player.swim_time = 0.0

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
	for i in mini(states.size(), sharks.size()):
		sharks[i] = states[i].duplicate()

func _process(delta: float) -> void:
	time += delta
	for i in sharks.size():
		var target: Vector2 = sharks[i].position
		visual_angles[i] = lerp_angle(visual_angles[i],float(sharks[i].angle),1.0-exp(-10*delta))
		visual_alpha[i] = move_toward(visual_alpha[i],float(sharks[i].get("alpha",0)),delta*1.5)
		visual_positions[i] = visual_positions[i].lerp(target, 1.0-exp(-16.0*delta)) if visual_positions[i].distance_to(target)<300 else target
	queue_redraw()

func _draw() -> void:
	for index in sharks.size():
		var alpha: float = visual_alpha[index]
		if alpha<0.01: continue
		draw_set_transform(visual_positions[index],visual_angles[index])
		# Low charcoal fin, warm highlights and a tapered wake, matching the sea palette.
		for i in 3:
			var phase := fposmod(time*0.9+i/3.0,1.0)
			var x := -12.0-phase*40.0
			draw_polyline(PackedVector2Array([Vector2(x-12,-8-phase*9),Vector2(x,0),Vector2(x-12,8+phase*9)]),Color(0.48,0.72,0.74,alpha*(1-phase)*0.5),1.2,true)
		var fin := PackedVector2Array([Vector2(-14,5),Vector2(-9,0),Vector2(-5,-11),Vector2(0,-16),Vector2(2,-15),Vector2(1,-6),Vector2(5,0),Vector2(13,5)])
		draw_colored_polygon(fin,Color(0.16,0.23,0.27,alpha))
		draw_polyline(PackedVector2Array([Vector2(-14,5),Vector2(-9,0),Vector2(-5,-11),Vector2(0,-16)]),Color(0.49,0.59,0.58,alpha),1.5,true)
		draw_line(Vector2(-16,6),Vector2(15,6),Color(0.6,0.79,0.77,alpha*0.65),1.5,true)

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
