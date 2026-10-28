class_name RowPlanner
extends RefCounted
## Finds a short rowing path that keeps clear of obstacles such as an island's
## coast and the ship's own hull.
##
## Each obstacle is grown by its margin to make a ring of waypoints around it.
## The path hops between waypoints that can see each other (shortest route
## first), so the boat goes around land and around the ship, never over them.

## A hop may pass this much closer than the margin, so it can run along a ring.
const SLACK := 6.0


## Global points from `start` (not included) to `goal` (included). Falls back
## to a straight hop when no clear path exists.
static func find_path(start: Vector2, goal: Vector2, obstacles: Array[PackedVector2Array],
		margins: Array[float], spacing: float = 50.0) -> PackedVector2Array:
	var walls: Array[PackedVector2Array] = []
	var wall_bounds: Array[Rect2] = []
	var rings: Array[PackedVector2Array] = []
	for k in obstacles.size():
		if obstacles[k].size() < 3:
			continue
		var wall := _grow(obstacles[k], maxf(margins[k] - SLACK, 0.0))
		walls.append(wall)
		wall_bounds.append(_bounds(wall))
		rings.append(_grow(obstacles[k], margins[k]))
	# An end inside a wall (a dock on the beach, a stern near the shore) gets
	# one short hop straight out to that obstacle's ring. Everything else is
	# planned from there, so no other hop may cross land or the hull.
	var exit_start := _step_out(start, walls, rings)
	var exit_goal := _step_out(goal, walls, rings)
	var nodes := PackedVector2Array([exit_start, exit_goal])
	for ring in rings:
		var last := Vector2.INF
		for point in ring:
			if last == Vector2.INF or point.distance_to(last) >= spacing:
				nodes.append(point)
				last = point
	# Waypoints that ended up inside another obstacle can't be reached.
	var usable := PackedVector2Array([exit_start, exit_goal])
	for i in range(2, nodes.size()):
		if _walls_containing(nodes[i], walls).is_empty():
			usable.append(nodes[i])
	nodes = usable

	var n := nodes.size()
	var dist := PackedFloat64Array()
	dist.resize(n)
	dist.fill(INF)
	dist[0] = 0.0
	var prev := PackedInt32Array()
	prev.resize(n)
	prev.fill(-1)
	var done := PackedByteArray()
	done.resize(n)
	while true:
		var u := -1
		for i in n:
			if done[i] == 0 and dist[i] < INF and (u == -1 or dist[i] < dist[u]):
				u = i
		if u == -1 or u == 1:
			break
		done[u] = 1
		for v in n:
			if done[v] == 1:
				continue
			var d := dist[u] + nodes[u].distance_to(nodes[v])
			if d >= dist[v]:
				continue
			if _is_clear(nodes[u], nodes[v], walls, wall_bounds):
				dist[v] = d
				prev[v] = u

	var route := PackedVector2Array()
	if exit_start != start:
		route.append(exit_start)
	if prev[1] == -1 and exit_start != exit_goal:
		push_warning("RowPlanner: no clear rowing path; rowing straight.")
		route.append(goal)
		return route
	var hops := PackedVector2Array()
	var at := 1
	while at != 0 and at != -1:
		hops.insert(0, nodes[at])
		at = prev[at]
	route.append_array(hops)
	if exit_goal != goal:
		route.append(goal)
	return route


# The nearest point on the ring of whichever wall `point` is inside (or
# `point` itself when it's out in open water).
static func _step_out(point: Vector2, walls: Array[PackedVector2Array], rings: Array[PackedVector2Array]) -> Vector2:
	for k in _walls_containing(point, walls):
		var ring := rings[k]
		var best := point
		var best_distance := INF
		for i in ring.size():
			var candidate := Geometry2D.get_closest_point_to_segment(point, ring[i], ring[(i + 1) % ring.size()])
			if point.distance_squared_to(candidate) < best_distance:
				best = candidate
				best_distance = point.distance_squared_to(candidate)
		return best
	return point


static func _is_clear(a: Vector2, b: Vector2, walls: Array[PackedVector2Array],
		wall_bounds: Array[Rect2]) -> bool:
	var hop_bounds := Rect2(a, Vector2.ZERO).expand(b)
	var hop := PackedVector2Array([a, b])
	for k in walls.size():
		if not wall_bounds[k].intersects(hop_bounds, true):
			continue
		if not Geometry2D.intersect_polyline_with_polygon(hop, walls[k]).is_empty():
			return false
	return true


static func _walls_containing(point: Vector2, walls: Array[PackedVector2Array]) -> Array[int]:
	var result: Array[int] = []
	for k in walls.size():
		if Geometry2D.is_point_in_polygon(point, walls[k]):
			result.append(k)
	return result


static func _grow(polygon: PackedVector2Array, delta: float) -> PackedVector2Array:
	if delta <= 0.0:
		return polygon
	var best := _largest(Geometry2D.offset_polygon(polygon, delta, Geometry2D.JOIN_SQUARE))
	# Which way an outline is drawn decides whether offset_polygon grows or
	# shrinks it, so make sure it really grew.
	if best.is_empty() or _area(best) < _area(polygon):
		best = _largest(Geometry2D.offset_polygon(polygon, -delta, Geometry2D.JOIN_SQUARE))
	if best.is_empty() or _area(best) < _area(polygon):
		return polygon
	return best


static func _largest(polygons: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	for polygon in polygons:
		if _area(polygon) > _area(best):
			best = polygon
	return best


static func _area(polygon: PackedVector2Array) -> float:
	var twice := 0.0
	for i in polygon.size():
		twice += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return absf(twice) * 0.5


static func _bounds(polygon: PackedVector2Array) -> Rect2:
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)
	return rect
