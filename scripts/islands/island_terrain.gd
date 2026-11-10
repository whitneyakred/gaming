@tool
class_name IslandTerrain
extends Node2D

## Island ground for the island minigames. When the game runs it also builds
## the invisible wall that keeps the player on land and on the dock.
##
## Two ways to use it:
## - Art (what the minigames use): set `art` to an island picture and trace
##   `walkable_outline` around its sand and dock. scenes/islands/island_art.tscn
##   is set up with assets/island_large.png; instance it as "Terrain" and
##   scale the instance if a minigame needs more room.
## - Placeholder: leave `art` empty and it draws a wobbly sand blob, an inner
##   patch (grass, rock, jungle...) and a wooden dock in code. The dock is
##   centred on x = 0 and runs from the shore down to y = radius.y + dock_length,
##   so put the rowboat at about (0, radius.y + dock_length - 14) and the
##   player's start at (0, radius.y).

@export var radius: Vector2 = Vector2(420, 300):
	set(value):
		radius = value
		_rebuild()
## How bumpy the coastline is (0 = a perfect oval).
@export_range(0.0, 0.3, 0.01) var wobble: float = 0.08:
	set(value):
		wobble = value
		_rebuild()
## Change for a different coastline shape.
@export var shape_seed: int = 1:
	set(value):
		shape_seed = value
		_rebuild()
@export var dock_length: float = 70.0:
	set(value):
		dock_length = value
		_rebuild()
@export var dock_width: float = 36.0:
	set(value):
		dock_width = value
		_rebuild()

@export_group("Colors")
@export var shore_color: Color = Color8(232, 214, 160):
	set(value):
		shore_color = value
		queue_redraw()
@export var sand_color: Color = Color8(214, 190, 128):
	set(value):
		sand_color = value
		queue_redraw()
## Size of the inner patch relative to the island (0 hides it).
@export_range(0.0, 0.95, 0.01) var inner_scale: float = 0.6:
	set(value):
		inner_scale = value
		queue_redraw()
@export var inner_color: Color = Color8(108, 158, 80):
	set(value):
		inner_color = value
		queue_redraw()
@export var dock_color: Color = Color8(120, 82, 48):
	set(value):
		dock_color = value
		queue_redraw()

@export_group("Art")
## Island picture drawn instead of the placeholder. When it's set (and
## `walkable_outline` has points), the shape, dock and color settings above
## are ignored.
@export var art: Texture2D:
	set(value):
		art = value
		_rebuild()
@export var art_scale: float = 1.25:
	set(value):
		art_scale = value
		queue_redraw()
## Where the player can walk on the art (the sand plus the dock), in this
## node's coordinates.
@export var walkable_outline: PackedVector2Array = PackedVector2Array():
	set(value):
		walkable_outline = value
		_rebuild()

const POINT_COUNT: int = 72
## The dock starts this far up the island so it always overlaps the sand.
const DOCK_OVERLAP: float = 0.2

var _coast: PackedVector2Array = PackedVector2Array()
var _walkable: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	_rebuild()
	if not Engine.is_editor_hint():
		_build_boundary()


## True when a global position is on the island (sand or dock).
func contains_point(global_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(global_point), _walkable)


## A random global position on the sand, at least `margin` px from the coast.
func random_point(margin: float = 30.0, rng: RandomNumberGenerator = null) -> Vector2:
	if _uses_art():
		return _random_art_point(margin, rng)
	for attempt in 60:
		var angle := _randf(rng) * TAU
		var distance := sqrt(_randf(rng))
		var local := Vector2(cos(angle) * radius.x, sin(angle) * radius.y) * distance
		if _distance_to_coast(local) >= margin and Geometry2D.is_point_in_polygon(local, _coast):
			return to_global(local)
	return global_position


## Coastline in local coordinates (without the dock).
func get_coast() -> PackedVector2Array:
	return _coast


func _uses_art() -> bool:
	return art != null and walkable_outline.size() >= 3


func _random_art_point(margin: float, rng: RandomNumberGenerator) -> Vector2:
	var bounds := Rect2(_coast[0], Vector2.ZERO)
	for point in _coast:
		bounds = bounds.expand(point)
	# The margin is in world pixels; this node may be scaled.
	var local_margin := margin / maxf(absf(global_scale.x), 0.001)
	for attempt in 200:
		var local := bounds.position + Vector2(_randf(rng), _randf(rng)) * bounds.size
		if Geometry2D.is_point_in_polygon(local, _coast) and _distance_to_coast(local) >= local_margin:
			return to_global(local)
	return global_position


func _rebuild() -> void:
	if _uses_art():
		_coast = walkable_outline
		_walkable = walkable_outline
		queue_redraw()
		return
	_coast = _make_coast()
	var dock := _dock_rect()
	var merged := Geometry2D.merge_polygons(_coast, PackedVector2Array([
		dock.position, Vector2(dock.end.x, dock.position.y), dock.end, Vector2(dock.position.x, dock.end.y),
	]))
	# The union is one outline (sand + dock); keep the biggest piece in case
	# a very wobbly coast splits off a sliver.
	_walkable = _coast
	var best_area := 0.0
	for polygon in merged:
		var area := absf(_area(polygon))
		if area > best_area:
			best_area = area
			_walkable = polygon
	queue_redraw()


func _make_coast() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	var phases := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var points := PackedVector2Array()
	for i in POINT_COUNT:
		var t := TAU * i / POINT_COUNT
		var bump := sin(3.0 * t + phases[0]) * 0.5 + sin(5.0 * t + phases[1]) * 0.3 + sin(7.0 * t + phases[2]) * 0.2
		var r := 1.0 + wobble * bump
		points.append(Vector2(cos(t) * radius.x, sin(t) * radius.y) * r)
	return points


func _dock_rect() -> Rect2:
	var top := radius.y * (1.0 - DOCK_OVERLAP)
	return Rect2(-dock_width / 2.0, top, dock_width, radius.y + dock_length - top)


func _draw() -> void:
	if _uses_art():
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(art_scale, art_scale))
		draw_texture(art, -art.get_size() / 2.0)
		draw_set_transform(Vector2.ZERO)
		return
	if _coast.size() < 3:
		return
	draw_colored_polygon(_scaled(_coast, 1.0), shore_color)
	draw_colored_polygon(_scaled(_coast, 0.93), sand_color)
	if inner_scale > 0.0:
		draw_colored_polygon(_scaled(_coast, inner_scale), inner_color)
	# Dock planks.
	var dock := _dock_rect()
	var shore_y := radius.y * 0.85
	var planks := Rect2(dock.position.x, shore_y, dock.size.x, dock.end.y - shore_y)
	draw_rect(planks, dock_color)
	var y := planks.position.y + 10.0
	while y < planks.end.y:
		draw_line(Vector2(planks.position.x, y), Vector2(planks.end.x, y), dock_color.darkened(0.35), 2.0)
		y += 12.0
	for x in [planks.position.x + 2.0, planks.end.x - 2.0]:
		draw_rect(Rect2(x - 3.0, planks.end.y - 6.0, 6.0, 10.0), dock_color.darkened(0.5))


func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(p * factor)
	return result


func _build_boundary() -> void:
	var body := StaticBody2D.new()
	body.name = "IslandBoundary"
	var wall := CollisionPolygon2D.new()
	wall.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	wall.polygon = _walkable  # segments mode closes the loop itself
	body.add_child(wall)
	add_child(body)


func _distance_to_coast(local: Vector2) -> float:
	var best := INF
	for i in _coast.size():
		var a := _coast[i]
		var b := _coast[(i + 1) % _coast.size()]
		best = minf(best, local.distance_to(Geometry2D.get_closest_point_to_segment(local, a, b)))
	return best


func _area(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in points.size():
		total += points[i].cross(points[(i + 1) % points.size()])
	return total / 2.0


func _randf(rng: RandomNumberGenerator) -> float:
	return rng.randf() if rng else randf()
