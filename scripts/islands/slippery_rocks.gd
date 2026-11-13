class_name SlipperyRocks
extends IslandGame

## Slippery Rocks: an ice-slide puzzle on wet, slimy rock.
## Walk onto the mat at the bottom of the rock shelf and press E to step on.
## On the shelf you can't stop: each move key sends you sliding until you hit
## a boulder or the edge. Land on the chest to open it (5-30 gold coins).
## Press E on the shelf to go back to the mat and start over (costs time).
##
## Scene setup: the Shelf marker is the centre of the grid. The mat sits
## below the middle of its bottom edge. Boulders and the chest are set in
## the Inspector as grid cells (column, row), with (0, 0) at the top left.

@export_group("Shelf")
@export var shelf_path: NodePath = ^"World/Shelf"
@export var columns: int = 9
@export var rows: int = 7
@export var cell_size: float = 48.0
@export var chest_cell: Vector2i = Vector2i(7, 0)
@export var boulders: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(5, 2), Vector2i(5, 3), Vector2i(6, 0), Vector2i(6, 2),
	Vector2i(6, 3), Vector2i(6, 4), Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6),
	Vector2i(8, 0), Vector2i(8, 3), Vector2i(8, 4),
]
## The fewest moves that solve the default layout; shown as a target.
@export var par_moves: int = 7
## Seconds per square while sliding.
@export var slide_seconds_per_cell: float = 0.06
@export var restart_penalty_seconds: float = 2.0
@export var reach: float = 40.0

var on_shelf: bool = false
var chest_opened: bool = false
var moves: int = 0
var player_cell: Vector2i

var _shelf: Node2D
var _sliding: bool = false
var _time: float = 0.0


func _setup_game() -> void:
	_shelf = get_node_or_null(shelf_path) as Node2D
	assert(_shelf != null, "SlipperyRocks needs a Shelf marker.")
	_shelf.z_index = -5
	_shelf.draw.connect(_draw_shelf)
	player_cell = mat_cell()
	_build_walls()


## The mat is a cell just below the middle of the bottom row.
func mat_cell() -> Vector2i:
	return Vector2i(floori(columns / 2.0), rows)


func cell_center(cell: Vector2i) -> Vector2:
	return _shelf.to_global(_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size)


func _build_walls() -> void:
	# A low wall all round the shelf: the only way on is from the mat.
	var o := _origin()
	var size := Vector2(columns, rows) * cell_size
	var t := 12.0
	var rects: Array[Rect2] = [
		Rect2(o.x - t, o.y - t, t, size.y + t * 2.0),
		Rect2(o.x + size.x, o.y - t, t, size.y + t * 2.0),
		Rect2(o.x - t, o.y - t, size.x + t * 2.0, t),
		Rect2(o.x - t, o.y + size.y, size.x + t * 2.0, t),
	]
	var body := StaticBody2D.new()
	body.name = "Ledge"
	for rect in rects:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)
	_shelf.add_child(body)


func _game_process(delta: float) -> void:
	_time += delta
	_shelf.queue_redraw()
	if on_shelf:
		set_prompt("" if _sliding else "Move keys slide   E: start over")
	elif not chest_opened and _near_mat():
		set_prompt("Press E to step onto the rocks")
	else:
		set_prompt("")


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or event.is_echo():
		return
	if event.is_action_pressed("interact"):
		if on_shelf:
			get_viewport().set_input_as_handled()
			if not _sliding:
				restart()
		elif not chest_opened and _near_mat():
			get_viewport().set_input_as_handled()
			step_on()
		return
	if not on_shelf or _sliding:
		return
	for pair in [["move_up", Vector2i.UP], ["move_down", Vector2i.DOWN],
			["move_left", Vector2i.LEFT], ["move_right", Vector2i.RIGHT]]:
		if event.is_action_pressed(pair[0]):
			get_viewport().set_input_as_handled()
			slide(pair[1])
			return


func step_on() -> void:
	if player.has_method("try_use_station") and not player.try_use_station(self):
		return
	on_shelf = true
	moves = 0
	player_cell = mat_cell()
	player.global_position = cell_center(player_cell)
	refresh_hud()


## Where a slide from `from` in `direction` stops.
func slide_target(from: Vector2i, direction: Vector2i) -> Vector2i:
	var cell := from
	while true:
		var next := cell + direction
		var on_grid := next.x >= 0 and next.y >= 0 and next.x < columns and next.y < rows
		if not (on_grid or next == mat_cell()) or boulders.has(next):
			return cell
		cell = next
		if cell == chest_cell:
			return cell
	return cell


## Slides the player one move. Returns the cell they stop on.
func slide(direction: Vector2i) -> Vector2i:
	var target := slide_target(player_cell, direction)
	if target == player_cell:
		show_message("Thud!", 0.3)
		return target
	moves += 1
	var cells := (target - player_cell).length()
	player_cell = target
	_sliding = true
	refresh_hud()
	var tween := create_tween()
	tween.tween_property(player, "global_position", cell_center(target), slide_seconds_per_cell * cells)
	tween.finished.connect(_on_slide_finished)
	return target


func _on_slide_finished() -> void:
	_sliding = false
	if player_cell == chest_cell and not chest_opened:
		_open_chest()


func restart() -> void:
	moves = 0
	player_cell = mat_cell()
	player.global_position = cell_center(player_cell)
	add_time(-restart_penalty_seconds)
	refresh_hud()
	show_message("Back to the mat. (-%ds)" % int(restart_penalty_seconds), 1.0)


func _open_chest() -> void:
	chest_opened = true
	var bragging := "In just %d moves!" % moves if moves <= par_moves else ""
	give_treasure("You opened the chest! %s" % bragging)
	_step_off()


func _step_off() -> void:
	on_shelf = false
	player_cell = mat_cell()
	player.global_position = cell_center(mat_cell()) + Vector2(0, cell_size * 0.6)
	if player.has_method("leave_station"):
		player.leave_station(self)
	refresh_hud()


func _near_mat() -> bool:
	return player != null and player.global_position.distance_to(cell_center(mat_cell())) <= reach


func _origin() -> Vector2:
	return -Vector2(columns, rows) * cell_size / 2.0


func _get_objective_text() -> String:
	if chest_opened:
		return "Chest opened! Head to the rowboat."
	if on_shelf:
		return "Slide onto the chest   Moves: %d (best: %d)" % [moves, par_moves]
	return "Step onto the slippery rocks and reach the chest"


func _is_objective_complete() -> bool:
	return chest_opened


func _get_incomplete_message() -> String:
	return "The chest is still up on the slippery rocks!"


func _draw_shelf() -> void:
	var o := _origin()
	var size := Vector2(columns, rows) * cell_size
	_shelf.draw_rect(Rect2(o, size).grow(12.0), Color8(80, 84, 90))
	for c in columns:
		for r in rows:
			var rect := Rect2(o + Vector2(c, r) * cell_size, Vector2.ONE * cell_size).grow(-1.5)
			var wet := 0.06 * sin(_time * 1.5 + c * 0.9 + r * 1.3)
			_shelf.draw_rect(rect, Color8(96, 132, 140).lightened(wet + (0.05 if (c + r) % 2 == 0 else 0.0)))
	# Mat.
	var mat := _shelf.to_local(cell_center(mat_cell()))
	_shelf.draw_rect(Rect2(mat - Vector2(cell_size, cell_size) * 0.45, Vector2(cell_size, cell_size) * 0.9), Color8(150, 110, 70))
	_shelf.draw_rect(Rect2(mat - Vector2(cell_size, cell_size) * 0.45, Vector2(cell_size, cell_size) * 0.9), Color8(110, 76, 44), false, 3.0)
	for boulder in boulders:
		var at := _shelf.to_local(cell_center(boulder))
		_shelf.draw_circle(at + Vector2(2, 4), cell_size * 0.42, Color(0, 0, 0, 0.25))
		_shelf.draw_circle(at, cell_size * 0.42, Color8(120, 116, 110))
		_shelf.draw_circle(at + Vector2(-6, -6), cell_size * 0.18, Color8(150, 146, 140))
	var chest := _shelf.to_local(cell_center(chest_cell))
	_shelf.draw_rect(Rect2(chest + Vector2(-15, -9), Vector2(30, 20)), Color8(150, 90, 40))
	_shelf.draw_rect(Rect2(chest + Vector2(-15, -15), Vector2(30, 7)), Color8(80, 50, 20) if chest_opened else Color8(120, 70, 30))
	_shelf.draw_rect(Rect2(chest + Vector2(-3, -7), Vector2(6, 6)), Color8(230, 200, 80))
