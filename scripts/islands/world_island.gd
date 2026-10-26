class_name WorldIsland
extends Node2D

## An island placed on the sailing map (child of Ship/Islands in ship.tscn).
## Sail into the yellow circle at its dock point to anchor, then take the
## rowboat over to play its scene. Move the node in the 2D view to place the
## island anywhere on the map.
##
## The ship can't sail over the island. Its coastline is the Land/Coast
## CollisionPolygon2D (drawn as a blue outline in the editor). If you move or
## rescale the island's Sprite2D, drag Coast's points to match the new art.

@export var display_name: String = "Island"
@export_file("*.tscn") var scene: String = ""
## Where the ship's center anchors, relative to this island. The default
## lines the ship's rowboat route up with the island's dock.
@export var dock_offset: Vector2 = Vector2(-400, 40)
## The coastline the ship can't cross. Leave empty for an island ships can
## sail over.
@export var coast_path: NodePath = ^"Land/Coast"

var _coast: PackedVector2Array = PackedVector2Array()
var _coast_bounds: Rect2
var _coast_transform: Transform2D
var _coast_node: CollisionPolygon2D
var _coast_looked_up: bool = false


func _ready() -> void:
	# The Land body only holds the coastline shape; it takes no part in physics.
	var land := get_node_or_null(^"Land") as CollisionObject2D
	if land:
		land.collision_layer = 0
		land.collision_mask = 0


func get_dock_position() -> Vector2:
	return to_global(dock_offset)


## Coastline in global (map) coordinates. Empty when the island has none.
func get_coast() -> PackedVector2Array:
	_refresh_coast()
	return _coast


## True when a polygon in global coordinates (e.g. the ship's hull) overlaps land.
func overlaps_land(polygon: PackedVector2Array, polygon_bounds: Rect2) -> bool:
	_refresh_coast()
	if _coast.is_empty() or not _coast_bounds.intersects(polygon_bounds):
		return false
	return not Geometry2D.intersect_polygons(polygon, _coast).is_empty()


## The point on the coastline closest to a global position.
func get_nearest_coast_point(point: Vector2) -> Vector2:
	_refresh_coast()
	var best := global_position
	var best_distance := INF
	for i in _coast.size():
		var candidate := Geometry2D.get_closest_point_to_segment(point, _coast[i], _coast[(i + 1) % _coast.size()])
		var distance := point.distance_squared_to(candidate)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _refresh_coast() -> void:
	if not _coast_looked_up:
		_coast_looked_up = true
		_coast_node = get_node_or_null(coast_path) as CollisionPolygon2D
	if _coast_node == null:
		return
	var xform := _coast_node.global_transform
	if not _coast.is_empty() and xform == _coast_transform:
		return
	_coast_transform = xform
	_coast = xform * _coast_node.polygon
	_coast_bounds = Rect2(_coast[0], Vector2.ZERO)
	for point in _coast:
		_coast_bounds = _coast_bounds.expand(point)
