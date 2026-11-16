extends Node

signal changed

const DISCOVERY_CELL_SIZE := 256.0
const MAP_EDGE_PADDING_CELLS := 2

var world_bounds := Rect2(-1024, -1024, 2048, 2048)
var _has_world_bounds := false
var pixels_per_meter := 10.0

var markers: Array[Vector2] = []
var discovered_islands: Dictionary = {}
var island_catalog: Dictionary = {}
var discovered_ocean: Dictionary = {}
var player_position := Vector2.ZERO
var has_player_position := false
var paradise_position := Vector2.ZERO
var has_paradise_position := false
var selected_island_id := ""

var has_destination := false
var destination := Vector2.ZERO
var map_open := false


func register_island(
	island_id: String,
	island_name: String,
	position: Vector2,
	is_paradise_island: bool = false
) -> void:
	island_catalog[island_id] = {"name": island_name, "position": position}
	_expand_world_bounds(position, DISCOVERY_CELL_SIZE)
	if is_paradise_island:
		paradise_position = position
		has_paradise_position = true
		changed.emit()


func update_player_position(position: Vector2) -> void:
	var position_changed := not has_player_position or player_position != position
	player_position = position
	has_player_position = true
	var cell := _world_to_cell(position)
	var discovered_new_tile := not discovered_ocean.has(cell)
	if discovered_new_tile:
		discovered_ocean[cell] = true

	_expand_world_bounds(position, DISCOVERY_CELL_SIZE)

	var discovered_new_island := false
	for island_id in island_catalog:
		var island: Dictionary = island_catalog[island_id]
		if discovered_islands.has(island_id):
			continue
		if _world_to_cell(Vector2(island["position"])) == cell:
			discovered_islands[island_id] = {
				"name": str(island["name"]),
				"position": Vector2(island["position"])
			}
			discovered_new_island = true

	if discovered_new_tile or discovered_new_island or (map_open and position_changed):
		changed.emit()


func add_marker(position: Vector2) -> void:
	markers.append(position)
	changed.emit()


func remove_marker_near(position: Vector2, tolerance: float) -> bool:
	for index in range(markers.size() - 1, -1, -1):
		if markers[index].distance_to(position) > tolerance:
			continue

		markers.remove_at(index)
		changed.emit()
		return true

	return false


func set_destination(position: Vector2) -> void:
	destination = position
	has_destination = true
	changed.emit()


func clear_destination() -> void:
	has_destination = false
	changed.emit()


func select_island(island_id: String) -> void:
	selected_island_id = island_id
	changed.emit()


func get_marker_distance_meters(position: Vector2) -> int:
	if not has_player_position:
		return 0
	return roundi(player_position.distance_to(position) / maxf(pixels_per_meter, 0.001))


func discover_island(island_id: String, island_name: String, position: Vector2) -> void:
	if discovered_islands.has(island_id):
		return

	discovered_islands[island_id] = {"name": island_name, "position": position}
	changed.emit()


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / DISCOVERY_CELL_SIZE),
		floori(position.y / DISCOVERY_CELL_SIZE))


func get_cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(
		Vector2(cell) * DISCOVERY_CELL_SIZE,
		Vector2.ONE * DISCOVERY_CELL_SIZE)


func _expand_world_bounds(position: Vector2, margin: float) -> void:
	var margin_vector := Vector2.ONE * margin
	var padding := DISCOVERY_CELL_SIZE * MAP_EDGE_PADDING_CELLS
	var minimum := position - margin_vector
	var maximum := position + margin_vector
	var cell_size := DISCOVERY_CELL_SIZE
	var expanded_minimum := Vector2(
		floorf(minimum.x / cell_size) * cell_size - padding,
		floorf(minimum.y / cell_size) * cell_size - padding)
	var expanded_maximum := Vector2(
		ceilf(maximum.x / cell_size) * cell_size + padding,
		ceilf(maximum.y / cell_size) * cell_size + padding)
	var required_bounds := Rect2(expanded_minimum, expanded_maximum - expanded_minimum)

	if not _has_world_bounds:
		world_bounds = required_bounds
		_has_world_bounds = true
	else:
		world_bounds = world_bounds.merge(required_bounds)
