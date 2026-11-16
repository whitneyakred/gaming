class_name QuicksandFlats
extends IslandGame

## Quicksand Flats: find the hidden safe path to the stranded chest.
## The flats are a grid of sand squares, and most of them are quicksand. One
## winding path of firm squares leads from the marked stepping stone to the
## chest; it's different every visit. Firm squares you step on show your
## footprints. Step on quicksand and you sink: you're pulled back to the edge
## and lose time, but that square stays marked so you won't step there
## again. Open the chest (5-30 gold coins), then walk back out the way you
## came.
##
## Scene setup: the Flats marker is the centre of the grid. The way in is
## along its bottom edge, so put the dock below it.

@export_group("Flats")
@export var flats_path: NodePath = ^"World/Flats"
@export var columns: int = 7
@export var rows: int = 7
@export var cell_size: float = 52.0
## How far into a quicksand square you can step before you sink. Lets you
## brush a corner without being pulled under.
@export var sink_margin: float = 10.0
@export var sink_penalty_seconds: float = 3.0
@export var wall_thickness: float = 14.0
## Leave at 0 for a new path every visit; set a number for the same path.
@export var fixed_seed: int = 0

var chest_found: bool = false
var sink_count: int = 0
## The firm squares, in order from the stepping stone to the chest.
var path: Array[Vector2i] = []

var _firm: Dictionary[Vector2i, bool] = {}
var _revealed: Dictionary[Vector2i, bool] = {}   # stepped on (firm) or sunk in (quicksand)
var _flats: Node2D
var _time: float = 0.0
var _sinking: float = 0.0


func _setup_game() -> void:
	_flats = get_node_or_null(flats_path) as Node2D
	assert(_flats != null, "QuicksandFlats needs a Flats marker.")
	_flats.z_index = -5
	_flats.draw.connect(_draw_flats)
	_generate_path()
	_build_walls()


func _generate_path() -> void:
	var rng := RandomNumberGenerator.new()
	if fixed_seed != 0:
		rng.seed = fixed_seed
	else:
		rng.randomize()
	path.clear()
	_firm.clear()
	var column := rng.randi_range(1, columns - 2)
	for row in range(rows - 1, -1, -1):
		_add_firm(Vector2i(column, row))
		if row == 0:
			break
		# Wander sideways along this row before stepping up to the next one.
		if rng.randf() < 0.75:
			var target := rng.randi_range(0, columns - 1)
			var step := 1 if target > column else -1
			while column != target:
				column += step
				_add_firm(Vector2i(column, row))
	# The stepping stone at the start is always visible.
	_revealed[path[0]] = true


func _add_firm(cell: Vector2i) -> void:
	if not _firm.has(cell):
		_firm[cell] = true
		path.append(cell)


func _build_walls() -> void:
	# Reed walls on the left, right and top so the only way in is from the
	# bottom edge.
	var o := _origin()
	var size := Vector2(columns, rows) * cell_size
	var t := wall_thickness
	var rects: Array[Rect2] = [
		Rect2(o.x - t, o.y - t, t, size.y + t),
		Rect2(o.x + size.x, o.y - t, t, size.y + t),
		Rect2(o.x - t, o.y - t, size.x + t * 2.0, t),
	]
	var body := StaticBody2D.new()
	body.name = "Reeds"
	for rect in rects:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)
	_flats.add_child(body)


func _game_process(delta: float) -> void:
	_time += delta
	_sinking = maxf(_sinking - delta, 0.0)
	_flats.queue_redraw()
	if player == null:
		return
	var cell := cell_at(player.global_position)
	if not is_in_grid(cell):
		return
	if _firm.has(cell):
		_revealed[cell] = true
		if cell == path.back() and not chest_found:
			_open_chest()
	elif _deep_in_cell(player.global_position, cell):
		_sink(cell)


func cell_at(point: Vector2) -> Vector2i:
	var local := _flats.to_local(point) - _origin()
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))


func is_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows


func is_firm(cell: Vector2i) -> bool:
	return _firm.has(cell)


func cell_center(cell: Vector2i) -> Vector2:
	return _flats.to_global(_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size)


## Where you're put back after sinking: just below the stepping stone.
func entry_point() -> Vector2:
	return cell_center(path[0]) + Vector2(0, cell_size * 0.9)


func _deep_in_cell(point: Vector2, cell: Vector2i) -> bool:
	var local := _flats.to_local(point) - _origin() - Vector2(cell) * cell_size
	var m := sink_margin
	return local.x > m and local.y > m and local.x < cell_size - m and local.y < cell_size - m


func _sink(cell: Vector2i) -> void:
	_revealed[cell] = true
	sink_count += 1
	_sinking = 0.6
	player.global_position = entry_point()
	player.velocity = Vector2.ZERO
	add_time(-sink_penalty_seconds)
	show_message("Quicksand! You were pulled back to the edge. (-%ds)" % int(sink_penalty_seconds), 1.4)


func _open_chest() -> void:
	chest_found = true
	# Show the whole path so the way back is easy.
	for cell in path:
		_revealed[cell] = true
	refresh_hud()
	give_treasure("You found the stranded chest!")


func _origin() -> Vector2:
	return -Vector2(columns, rows) * cell_size / 2.0


func _get_objective_text() -> String:
	if chest_found:
		return "Chest opened! Follow your footprints back to the rowboat."
	return "Find the safe path to the chest   Sunk: %d" % sink_count


func _is_objective_complete() -> bool:
	return chest_found


func _get_incomplete_message() -> String:
	return "The chest is still out on the flats!"


func _draw_flats() -> void:
	var o := _origin()
	var size := Vector2(columns, rows) * cell_size
	var t := wall_thickness
	_flats.draw_rect(Rect2(o, size), Color8(184, 160, 104))
	for c in columns:
		for r in rows:
			var cell := Vector2i(c, r)
			var rect := Rect2(o + Vector2(cell) * cell_size, Vector2.ONE * cell_size).grow(-2.0)
			var shade := 0.04 * sin(c * 1.7 + r * 2.3)
			_flats.draw_rect(rect, Color8(196, 172, 116).lightened(shade))
			if not _revealed.has(cell):
				continue
			if _firm.has(cell):
				_flats.draw_rect(rect, Color8(150, 126, 84))
				var mid := rect.get_center()
				_flats.draw_circle(mid + Vector2(-6, 6), 4.0, Color8(110, 90, 60))
				_flats.draw_circle(mid + Vector2(6, -6), 4.0, Color8(110, 90, 60))
			else:
				var swirl := _time * 2.0 + c + r
				_flats.draw_rect(rect, Color8(140, 108, 60))
				_flats.draw_arc(rect.get_center(), cell_size * 0.3, swirl, swirl + PI * 1.4, 16, Color8(100, 74, 40), 3.0)
				_flats.draw_arc(rect.get_center(), cell_size * 0.15, -swirl, -swirl + PI * 1.4, 12, Color8(100, 74, 40), 2.0)
	# Stepping stone marker.
	var start := _flats.to_local(cell_center(path[0]))
	_flats.draw_circle(start + Vector2(0, cell_size * 0.5), 7.0, Color8(240, 230, 200))
	# Chest.
	var chest := _flats.to_local(cell_center(path.back()))
	var lid := Color8(120, 70, 30) if not chest_found else Color8(80, 50, 20)
	_flats.draw_rect(Rect2(chest + Vector2(-14, -8), Vector2(28, 18)), Color8(150, 90, 40))
	_flats.draw_rect(Rect2(chest + Vector2(-14, -14), Vector2(28, 7)), lid)
	_flats.draw_rect(Rect2(chest + Vector2(-3, -6), Vector2(6, 6)), Color8(230, 200, 80))
	# Reeds.
	var reed := Color8(90, 120, 60)
	_flats.draw_rect(Rect2(o.x - t, o.y - t, t, size.y + t), reed)
	_flats.draw_rect(Rect2(o.x + size.x, o.y - t, t, size.y + t), reed)
	_flats.draw_rect(Rect2(o.x - t, o.y - t, size.x + t * 2.0, t), reed)
	if _sinking > 0.0 and player:
		var at := _flats.to_local(player.global_position)
		_flats.draw_arc(at, 20.0 * (1.0 - _sinking), 0.0, TAU, 16, Color(1, 1, 1, _sinking), 2.0)
