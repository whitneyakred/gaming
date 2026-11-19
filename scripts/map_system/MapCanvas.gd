extends Control

const MAP_MARGIN := Vector2(64, 130)
var ship_heading: float = 0.0
func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	var scene := get_tree().current_scene
	var ship := scene.get_node_or_null("Ship") if scene != null else null
	if ship is Node2D and not is_equal_approx(ship_heading, ship.global_rotation):
		ship_heading = ship.global_rotation
		queue_redraw()
func heading_marker(center: Vector2, scale_factor: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in [Vector2(0,-11),Vector2(7,8),Vector2(0,4),Vector2(-7,8)]:
		points.append(center + (point * scale_factor).rotated(ship_heading))
	return points

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	MapState.changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func get_map_rect() -> Rect2:
	var bounds: Rect2 = MapState.world_bounds
	var available := (size - MAP_MARGIN).max(Vector2.ONE)
	var world_size := bounds.size.max(Vector2.ONE)
	var aspect_ratio := world_size.x / world_size.y
	var map_size := Vector2(
		minf(available.x, available.y * aspect_ratio),
		minf(available.y, available.x / aspect_ratio))
	return Rect2((size - map_size) / 2.0, map_size)


func world_to_map(world_position: Vector2) -> Vector2:
	var bounds: Rect2 = MapState.world_bounds
	var rect := get_map_rect()
	var relative_position := (world_position - bounds.position) / bounds.size
	return rect.position + relative_position * rect.size


func map_to_world(map_position: Vector2) -> Vector2:
	var rect := get_map_rect()
	var bounds: Rect2 = MapState.world_bounds
	var relative_position := (map_position - rect.position) / rect.size
	return bounds.position + relative_position * bounds.size


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	if not get_map_rect().has_point(event.position):
		return

	var world_position := map_to_world(event.position)
	if event.button_index == MOUSE_BUTTON_LEFT:
		var bounds: Rect2 = MapState.world_bounds
		var marker_tolerance := 12.0 * bounds.size.x / get_map_rect().size.x
		if MapState.remove_marker_near(world_position, marker_tolerance):
			accept_event()
			return

		var island_id := _get_clicked_island(world_position)
		if not island_id.is_empty():
			MapState.select_island(island_id)
			accept_event()
			return

		MapState.select_island("")
		MapState.add_marker(world_position)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		MapState.set_destination(world_position)
		MapState.select_island("")
	else:
		return

	accept_event()


func _get_clicked_island(world_position: Vector2) -> String:
	var hit_tolerance := 14.0 * MapState.world_bounds.size.x / get_map_rect().size.x
	for island_id in MapState.discovered_islands:
		var island: Dictionary = MapState.discovered_islands[island_id]
		if world_position.distance_to(Vector2(island["position"])) <= hit_tolerance:
			return str(island_id)
	return ""


func _draw() -> void:
	var rect := get_map_rect()
	var bounds: Rect2 = MapState.world_bounds
	var font := ThemeDB.fallback_font
	var pixels_per_world_unit := rect.size.x / bounds.size.x

	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.78))
	draw_rect(rect, Color("#07151e"))

	for cell in MapState.discovered_ocean:
		var ocean_cell := Vector2i(cell)
		var cell_rect: Rect2 = MapState.get_cell_rect(ocean_cell)
		var visible_cell := cell_rect.intersection(bounds)
		if visible_cell.size.x <= 0.0 or visible_cell.size.y <= 0.0:
			continue

		var top_left := world_to_map(visible_cell.position)
		var bottom_right := world_to_map(visible_cell.end)
		var variation := absi(ocean_cell.x * 17 + ocean_cell.y * 31) % 3
		var ocean_color := Color("#20465a") if variation == 0 else Color("#1b3d51")
		draw_rect(Rect2(top_left, bottom_right - top_left), ocean_color)

	# Unexplored regions stay dark; discovered ocean cells retain their grid.
	for i in range(1, 10):
		var fraction := float(i) / 10.0
		var x := rect.position.x + rect.size.x * fraction
		var y := rect.position.y + rect.size.y * fraction
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.6, 0.8, 0.9, 0.08))
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.6, 0.8, 0.9, 0.08))

	for region in MapState.key_regions:
		if MapState.discovered_islands.has(region.island): continue
		var center := world_to_map(region.center)
		var radius: float = region.radius * pixels_per_world_unit
		var color := QuestIsland.key_color(region.key)
		draw_circle(center, radius, Color(color, 0.08))
		draw_arc(center, radius, 0, TAU, 72, color, 2.0, true)
	for island_id in MapState.island_catalog:
		if island_id == "Paradise": continue
		if MapState.discovered_islands.has(island_id): continue
		var point := world_to_map(MapState.island_catalog[island_id].position)
		draw_string(font, point + Vector2(-5,6), "?", HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e5c987"))
	for island_id in MapState.discovered_islands:
		var island: Dictionary = MapState.discovered_islands[island_id]
		var coast: PackedVector2Array = MapState.island_catalog.get(island_id, {}).get("coast", PackedVector2Array())
		var outline := PackedVector2Array()
		for point in coast: outline.append(world_to_map(point))
		if outline.size() >= 3:
			draw_colored_polygon(outline, Color("77956d"))
			outline.append(outline[0])
			draw_polyline(outline,Color("d9c79c"),1.5,true)
		else: draw_circle(world_to_map(island.position),4,Color("77956d"))
		if str(island_id).begins_with("Key_"):
			var key := str(island_id).trim_prefix("Key_")
			var point := world_to_map(island.position)
			draw_circle(point, 6, QuestIsland.key_color(key), false, 2)

	for marker in MapState.markers:
		var marker_position := world_to_map(marker)
		draw_circle(marker_position, 5.0, Color("#ffd166"))
		draw_string(
			font,
			marker_position + Vector2(8, -6),
			"%d m" % MapState.get_marker_distance_meters(marker),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			13,
			Color("#ffe6a6"))

	if MapState.has_player_position:
		var player_map_position := world_to_map(MapState.player_position)
		draw_colored_polygon(heading_marker(player_map_position, 1.35), Color("#f5f1d5"))
		draw_colored_polygon(heading_marker(player_map_position), Color("#e84c4c"))

	if MapState.has_destination:
		var destination_position := world_to_map(MapState.destination)
		draw_circle(destination_position, 12.0, Color("#ff6464"), false, 3.0)
		draw_line(
			destination_position - Vector2(16, 0),
			destination_position + Vector2(16, 0),
			Color("#ff6464"),
			2.0)
		draw_line(
			destination_position - Vector2(0, 16),
			destination_position + Vector2(0, 16),
			Color("#ff6464"),
			2.0)

	if MapState.has_paradise_position:
		var paradise_map_position := world_to_map(MapState.paradise_position)
		draw_circle(paradise_map_position, 12.0, Color("#ffdc78"))
		draw_string(
			font,
			paradise_map_position + Vector2(10, -8),
			"Paradise",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color("#ffdc78"))

	if MapState.selected_island_id != "":
		var selected_island: Dictionary = MapState.discovered_islands.get(
			MapState.selected_island_id,
			{})
		if not selected_island.is_empty():
			var island_position := Vector2(selected_island["position"])
			draw_string(
				font,
				Vector2(rect.position.x + 12.0, rect.position.y + 24.0),
				"%s  |  %d m from ship" % [
					str(selected_island["name"]),
					MapState.get_marker_distance_meters(island_position)
				],
				HORIZONTAL_ALIGNMENT_LEFT,
				rect.size.x - 24.0,
				16,
				Color.WHITE)

	draw_rect(rect, Color("#d5bc84"), false, 3.0)
	draw_string(
		font,
		rect.position - Vector2(0, 15),
		"Left click: select island / add or remove pin | Right click: destination",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE)
	draw_string(
		font,
		Vector2(rect.position.x, rect.end.y + 25.0),
		"C: clear destination | Escape: close",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE)
