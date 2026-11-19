extends RefCounted
## Bounded local water routing. Rebuilt only when a direct swim is obstructed.
const CELL := 64.0
var obstacles: Array[PackedVector2Array] = []
var bounds: Array[Rect2] = []
func prepare() -> void:
	bounds.clear()
	for polygon in obstacles:
		var box := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon: box = box.expand(point)
		bounds.append(box)
func clear(point: Vector2, radius: float) -> bool:
	for index in obstacles.size():
		if not bounds[index].grow(radius).has_point(point): continue
		var polygon := obstacles[index]
		if Geometry2D.is_point_in_polygon(point, polygon): return false
		for i in polygon.size():
			if Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()]).distance_squared_to(point) < radius * radius: return false
	return true
func segment(a: Vector2, b: Vector2, radius: float) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / 24.0))
	for i in range(1, steps + 1):
		if not clear(a.lerp(b, float(i) / steps), radius): return false
	return true
func route(start: Vector2, goal: Vector2, radius: float) -> PackedVector2Array:
	var low := start.min(goal) - Vector2.ONE * 640
	var high := start.max(goal) + Vector2.ONE * 640
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(((high - low) / CELL).ceil()).min(Vector2i(80, 80)))
	grid.cell_size = Vector2.ONE * CELL
	grid.offset = low
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var from := Vector2i.ZERO
	var to := Vector2i.ZERO
	var from_distance := INF
	var to_distance := INF
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x, y)
			var point := grid.get_point_position(cell)
			# Extra half-cell clearance keeps diagonal edges away from corners.
			var free := clear(point, radius + 24)
			grid.set_point_solid(cell, not free)
			if not free: continue
			if point.distance_squared_to(start) < from_distance:
				from_distance = point.distance_squared_to(start); from = cell
			if point.distance_squared_to(goal) < to_distance:
				to_distance = point.distance_squared_to(goal); to = cell
	if is_inf(from_distance) or is_inf(to_distance): return PackedVector2Array()
	return grid.get_point_path(from, to)
