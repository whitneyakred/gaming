class_name PropCollision
extends RefCounted
## Deterministic circle sweeps shared by host simulation and guest prediction.
## Only nearby cells are queried; scenery does not allocate thousands of bodies.
const CELL := 160.0
const CREW_RADIUS := 8.0
const MAX_RADIUS := 40.0
var cells: Dictionary = {}

func clear() -> void:
	cells.clear()

func insert(id: String, point: Vector2, radius: float, reduced_radius: float = -1.0) -> void:
	var cell := Vector2i(floori(point.x/CELL),floori(point.y/CELL))
	if not cells.has(cell): cells[cell] = []
	cells[cell].append({"id":id,"point":point,"radius":radius,"reduced":reduced_radius})

func nearby(start: Vector2, end: Vector2) -> Array:
	var bounds := Rect2(start,Vector2.ZERO).expand(end).grow(MAX_RADIUS+CREW_RADIUS)
	var first := Vector2i(floori(bounds.position.x/CELL),floori(bounds.position.y/CELL))
	var last := Vector2i(floori(bounds.end.x/CELL),floori(bounds.end.y/CELL))
	var result: Array = []
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1): result.append_array(cells.get(Vector2i(x,y),[]))
	return result

func move(start: Vector2, motion: Vector2, changes: Dictionary) -> Vector2:
	var position := start
	var remaining := motion
	var candidates := nearby(start,start+motion)
	for slide in 3:
		var length_squared := remaining.length_squared()
		if length_squared < 0.000001: break
		var earliest := 1.0
		var normal := Vector2.ZERO
		for solid: Dictionary in candidates:
			var radius: float = solid.radius
			if solid.reduced >= 0.0 and changes.get(solid.id,{}).get("hits",0) == 3: radius = solid.reduced
			radius += CREW_RADIUS
			var offset: Vector2 = position-solid.point
			var b := offset.dot(remaining)
			var c := offset.length_squared()-radius*radius
			if c < 0.0:
				# Teleports or regrowth may overlap a foot: allow escape, never trap it.
				if b >= 0.0: continue
				if earliest > 0.0:
					earliest = 0.0
					normal = offset.normalized()
				continue
			if b >= 0.0: continue
			var discriminant := b*b-length_squared*c
			if discriminant < 0.0: continue
			var hit := (-b-sqrt(discriminant))/length_squared
			if hit >= 0.0 and hit < earliest:
				earliest = hit
				normal = (offset+remaining*hit).normalized()
		if normal.is_zero_approx():
			position += remaining
			break
		position += remaining * maxf(0.0,earliest-0.001/sqrt(length_squared))
		remaining = (remaining*(1.0-earliest)).slide(normal)
	return position
