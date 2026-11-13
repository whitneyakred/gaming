class_name TurtleBeach
extends IslandGame

## Turtle Beach: help the hatchlings reach the sea.
## Baby turtles hatch from the nests one by one and crawl to the nearest
## stretch of shore. Crabs scuttle in from the rocks to snatch them; walk into
## a crab to chase it off. Get enough turtles safely to the sea and the beach
## pays 5-30 gold coins. If so many are snatched that you can't make it,
## it's game over.
##
## Scene setup:
## - Marker2D children of Nests are the nests.
## - Marker2D children of Sea are spots at the water's edge.
## - Marker2D children of CrabDens are where crabs come from.

@export_group("Turtles")
@export var nests_path: NodePath = ^"World/Nests"
@export var sea_path: NodePath = ^"World/Sea"
@export var dens_path: NodePath = ^"World/CrabDens"
@export var total_hatchlings: int = 12
@export var turtles_needed: int = 8
@export var hatch_interval: float = 2.6
@export var turtle_speed: float = 28.0

@export_group("Crabs")
@export var crab_speed: float = 52.0
@export var crab_interval: float = 3.2
## Walking this close to a crab chases it off.
@export var scare_radius: float = 34.0
## A crab this close to a hatchling snatches it.
@export var snatch_radius: float = 12.0

var hatched_count: int = 0
var saved_count: int = 0
var lost_count: int = 0
var rewarded: bool = false
## Each turtle: {pos: Vector2, target: Vector2, wiggle: float}
var turtles: Array[Dictionary] = []
## Each crab: {pos: Vector2, vel: Vector2, fleeing: bool, life: float}
var crabs: Array[Dictionary] = []

var _nests: Array[Vector2] = []
var _sea: Array[Vector2] = []
var _dens: Array[Vector2] = []
var _layer: Node2D
var _next_hatch: float = 0.8
var _next_crab: float = 3.0
var _time: float = 0.0


func _setup_game() -> void:
	_nests = _marker_positions(nests_path)
	_sea = _marker_positions(sea_path)
	_dens = _marker_positions(dens_path)
	assert(not _nests.is_empty() and not _sea.is_empty() and not _dens.is_empty(),
			"TurtleBeach needs markers under Nests, Sea and CrabDens.")
	turtles_needed = mini(turtles_needed, total_hatchlings)
	_layer = Node2D.new()
	_layer.name = "Beach"
	_layer.z_index = 5
	_layer.draw.connect(_draw_beach)
	add_child(_layer)


func _marker_positions(path: NodePath) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var parent := get_node_or_null(path)
	if parent:
		for marker in parent.get_children():
			if marker is Node2D:
				result.append(marker.global_position)
	return result


func _game_process(delta: float) -> void:
	_time += delta
	if hatched_count < total_hatchlings:
		_next_hatch -= delta
		if _next_hatch <= 0.0:
			_next_hatch = hatch_interval
			hatch()

	if not rewarded:
		_next_crab -= delta
		if _next_crab <= 0.0:
			_next_crab = crab_interval
			spawn_crab()

	_move_turtles(delta)
	_move_crabs(delta)
	_layer.queue_redraw()


## Hatches the next turtle from a random nest. Returns its index in `turtles`.
func hatch() -> int:
	if hatched_count >= total_hatchlings:
		return -1
	hatched_count += 1
	var nest: Vector2 = _nests[randi() % _nests.size()]
	var start := nest + Vector2(randf_range(-8, 8), randf_range(-6, 6))
	var target: Vector2 = _sea[0]
	for spot in _sea:
		if start.distance_to(spot) < start.distance_to(target):
			target = spot
	turtles.append({"pos": start, "target": target, "wiggle": randf() * TAU})
	refresh_hud()
	return turtles.size() - 1


## Sends a crab out from a random den. Returns its index in `crabs`.
func spawn_crab() -> int:
	var den: Vector2 = _dens[randi() % _dens.size()]
	crabs.append({"pos": den, "vel": Vector2.ZERO, "fleeing": false, "life": 0.0})
	return crabs.size() - 1


func _move_turtles(delta: float) -> void:
	for i in range(turtles.size() - 1, -1, -1):
		var turtle := turtles[i]
		var pos: Vector2 = turtle["pos"]
		var target: Vector2 = turtle["target"]
		turtle["wiggle"] = float(turtle["wiggle"]) + delta * 10.0
		pos = pos.move_toward(target, turtle_speed * delta)
		turtle["pos"] = pos
		if pos.distance_to(target) < 2.0:
			turtles.remove_at(i)
			_turtle_saved()


func _move_crabs(delta: float) -> void:
	for i in range(crabs.size() - 1, -1, -1):
		var crab := crabs[i]
		var pos: Vector2 = crab["pos"]
		if crab["fleeing"]:
			var vel: Vector2 = crab["vel"]
			crab["pos"] = pos + vel * delta
			crab["life"] = float(crab["life"]) - delta
			if float(crab["life"]) <= 0.0:
				crabs.remove_at(i)
			continue
		if player and pos.distance_to(player.global_position) <= scare_radius:
			scare(i)
			continue
		var prey := _nearest_turtle(pos)
		if prey < 0:
			# Nothing to chase: drift slowly toward the middle of the beach.
			crab["pos"] = pos.move_toward(_nests[0], crab_speed * 0.4 * delta)
			continue
		var prey_pos: Vector2 = turtles[prey]["pos"]
		pos = pos.move_toward(prey_pos, crab_speed * delta)
		crab["pos"] = pos
		if pos.distance_to(prey_pos) <= snatch_radius:
			_snatch(prey, crab)
			if not is_running():
				return


func scare(index: int) -> void:
	var crab := crabs[index]
	var pos: Vector2 = crab["pos"]
	var away := (pos - player.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	crab["fleeing"] = true
	crab["vel"] = away * 190.0
	crab["life"] = 2.0


func _snatch(turtle_index: int, crab: Dictionary) -> void:
	turtles.remove_at(turtle_index)
	lost_count += 1
	crab["fleeing"] = true
	crab["life"] = 2.5
	var pos: Vector2 = crab["pos"]
	var home: Vector2 = _dens[0]
	for den in _dens:
		if pos.distance_to(den) < pos.distance_to(home):
			home = den
	crab["vel"] = (home - pos).normalized() * 90.0
	refresh_hud()
	if total_hatchlings - lost_count < turtles_needed and not rewarded:
		lose("Too many hatchlings were snatched!")
	else:
		show_message("A crab snatched a hatchling!", 1.0)


func _turtle_saved() -> void:
	saved_count += 1
	refresh_hud()
	if saved_count >= turtles_needed and not rewarded:
		rewarded = true
		for i in crabs.size():
			if not crabs[i]["fleeing"] and player:
				scare(i)
		give_treasure("Enough hatchlings made it to the sea!")


func _nearest_turtle(from: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for i in turtles.size():
		var distance := from.distance_to(turtles[i]["pos"])
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


func _get_objective_text() -> String:
	if rewarded:
		return "The hatchlings are safe! Head to the rowboat."
	return "Hatchlings in the sea: %d / %d   Snatched: %d" % [saved_count, turtles_needed, lost_count]


func _is_objective_complete() -> bool:
	return rewarded


func _get_incomplete_message() -> String:
	return "Get %d hatchlings to the sea first!" % turtles_needed


func _draw_beach() -> void:
	for nest in _nests:
		_layer.draw_circle(nest + Vector2(0, 2), 18.0, Color8(196, 170, 110))
		_layer.draw_circle(nest, 14.0, Color8(214, 190, 132))
		if hatched_count < total_hatchlings:
			_layer.draw_circle(nest + Vector2(-4, -2), 4.0, Color8(245, 240, 225))
			_layer.draw_circle(nest + Vector2(5, 1), 4.0, Color8(245, 240, 225))
	for spot in _sea:
		var foam := 0.5 + 0.3 * sin(_time * 3.0 + spot.x)
		_layer.draw_arc(spot, 14.0, 0.0, TAU, 20, Color(1, 1, 1, foam), 2.0)
		_layer.draw_arc(spot, 8.0, 0.0, TAU, 16, Color(0.6, 0.85, 1.0, foam), 2.0)
	for turtle in turtles:
		var pos: Vector2 = turtle["pos"]
		var target: Vector2 = turtle["target"]
		var facing := (target - pos).angle() + PI / 2.0
		var flip := sin(float(turtle["wiggle"])) * 2.0
		_layer.draw_set_transform(pos, facing)
		for side in [-1.0, 1.0]:
			_layer.draw_circle(Vector2(side * 6.0, -3.0 + flip * side), 2.5, Color8(60, 110, 70))
			_layer.draw_circle(Vector2(side * 5.0, 4.0 - flip * side), 2.0, Color8(60, 110, 70))
		_layer.draw_circle(Vector2(0, -7), 3.0, Color8(80, 130, 80))
		_layer.draw_circle(Vector2.ZERO, 6.0, Color8(52, 96, 60))
		_layer.draw_circle(Vector2.ZERO, 3.5, Color8(90, 140, 90))
		_layer.draw_set_transform(Vector2.ZERO)
	for crab in crabs:
		var pos: Vector2 = crab["pos"]
		var red := Color8(200, 70, 45)
		var leg := sin(_time * 18.0) * 2.0
		for side in [-1.0, 1.0]:
			for j in 3:
				_layer.draw_line(pos + Vector2(side * 5.0, -2.0 + j * 3.0),
						pos + Vector2(side * 11.0, -3.0 + j * 4.0 + (leg if j % 2 == 0 else -leg)), red.darkened(0.3), 2.0)
			_layer.draw_circle(pos + Vector2(side * 8.0, -8.0), 3.0, red)
		_layer.draw_circle(pos, 7.0, red)
		_layer.draw_circle(pos + Vector2(-2.5, -4), 1.4, Color.BLACK)
		_layer.draw_circle(pos + Vector2(2.5, -4), 1.4, Color.BLACK)
