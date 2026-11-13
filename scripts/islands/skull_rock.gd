class_name SkullRock
extends IslandGame

## Skull Rock Ruins: a push-the-boulders puzzle.
## Walk into a boulder to push it one square (it only moves if the square
## behind it is free). Cover every pressure plate to open the shrine gate,
## then grab the idol inside: 5-30 gold coins go into your bag.
## Stuck? Press E at the skull stone to put the boulders back (costs time).
##
## Scene setup: the Courtyard marker is the centre of the boulder grid and the
## Skull marker is the reset stone. Cells are (column, row) from the
## courtyard's top-left. The gate is in the top wall above `gate_column`, the
## way in is in the bottom wall below it.

@export_group("Puzzle")
@export var courtyard_path: NodePath = ^"World/Courtyard"
@export var skull_path: NodePath = ^"World/Skull"
@export var columns: int = 7
@export var rows: int = 5
@export var cell_size: float = 48.0
@export var boulder_cells: Array[Vector2i] = [Vector2i(2, 2), Vector2i(4, 3), Vector2i(5, 3)]
@export var plate_cells: Array[Vector2i] = [Vector2i(1, 1), Vector2i(3, 1), Vector2i(5, 1)]
@export var gate_column: int = 3
## How long you must lean on a boulder before it moves.
@export var push_delay: float = 0.15
@export var reset_penalty_seconds: float = 5.0
@export var skull_reach: float = 50.0

const WALL_THICKNESS: float = 12.0
const PLAYER_RADIUS: float = 7.0

var gate_open: bool = false
var idol_taken: bool = false

var _courtyard: Node2D
var _skull: Node2D
var _boulders: Array[StaticBody2D] = []
var _boulder_cells: Array[Vector2i] = []
var _moving: Array[bool] = []
var _walls: Array[Rect2] = []   # in courtyard-local coordinates
var _gate_rect: Rect2
var _gate_body: StaticBody2D
var _push_time: float = 0.0


func _setup_game() -> void:
	_courtyard = get_node_or_null(courtyard_path) as Node2D
	assert(_courtyard != null, "SkullRock needs a Courtyard marker.")
	_courtyard.z_index = -5
	_courtyard.draw.connect(_draw_courtyard)
	_skull = get_node_or_null(skull_path) as Node2D
	if _skull:
		_skull.draw.connect(_draw_skull)
		_skull.queue_redraw()
	_build_walls()
	for cell in boulder_cells:
		var boulder := StaticBody2D.new()
		boulder.name = "Boulder%d" % (_boulders.size() + 1)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2.ONE * (cell_size - 4.0)
		shape.shape = rect
		boulder.add_child(shape)
		boulder.draw.connect(_draw_boulder.bind(boulder))
		_courtyard.get_parent().add_child.call_deferred(boulder)
		_boulders.append(boulder)
		_boulder_cells.append(cell)
		_moving.append(false)
	_place_boulders.call_deferred()


func _game_process(delta: float) -> void:
	_courtyard.queue_redraw()
	if player == null:
		return
	if gate_open and not idol_taken and player.global_position.distance_to(_idol_position()) < 24.0:
		_take_idol()
	var near_skull := _skull != null and player.global_position.distance_to(_skull.global_position) <= skull_reach
	set_prompt("Press E to reset the boulders" if near_skull and not gate_open else "")
	_try_push(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or gate_open or _skull == null or player == null:
		return
	if event.is_action_pressed("interact") and not event.is_echo() \
			and player.global_position.distance_to(_skull.global_position) <= skull_reach:
		get_viewport().set_input_as_handled()
		_reset_boulders()


# --- Pushing ------------------------------------------------------------------

func _try_push(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input == Vector2.ZERO:
		_push_time = 0.0
		return
	var axis := Vector2i(int(signf(input.x)), 0) if absf(input.x) > absf(input.y) else Vector2i(0, int(signf(input.y)))
	var axis_vector := Vector2(axis)
	for i in _boulders.size():
		if _moving[i]:
			continue
		var offset := _cell_center(_boulder_cells[i]) - player.global_position
		var along := offset.dot(axis_vector)
		var across := absf(offset.dot(axis_vector.orthogonal()))
		if along > 0.0 and along < cell_size / 2.0 + PLAYER_RADIUS + 6.0 and across < cell_size * 0.35:
			_push_time += delta
			if _push_time >= push_delay:
				_push_time = 0.0
				_push(i, axis)
			return
	_push_time = 0.0


func _push(index: int, axis: Vector2i) -> void:
	var target := _boulder_cells[index] + axis
	if target.x < 0 or target.y < 0 or target.x >= columns or target.y >= rows:
		return
	if _boulder_cells.has(target):
		return
	_boulder_cells[index] = target
	_moving[index] = true
	var tween := create_tween()
	tween.tween_property(_boulders[index], "global_position", _cell_center(target), 0.15)
	tween.finished.connect(func() -> void:
		_moving[index] = false
		_check_plates())


func _check_plates() -> void:
	if gate_open:
		return
	refresh_hud()
	for plate in plate_cells:
		if not _boulder_cells.has(plate):
			return
	gate_open = true
	if is_instance_valid(_gate_body):
		_gate_body.queue_free()
	refresh_hud()
	show_message("The shrine gate rumbles open!", 2.0)


func _reset_boulders() -> void:
	_boulder_cells = boulder_cells.duplicate()
	_place_boulders()
	add_time(-reset_penalty_seconds)
	refresh_hud()
	show_message("The boulders roll back. (-%ds)" % int(reset_penalty_seconds), 1.2)


func _place_boulders() -> void:
	for i in _boulders.size():
		_boulders[i].global_position = _cell_center(_boulder_cells[i])
		_boulders[i].queue_redraw()


func _take_idol() -> void:
	idol_taken = true
	refresh_hud()
	give_treasure("You grabbed the golden idol!")


# --- Layout -------------------------------------------------------------------

func _grid_origin() -> Vector2:
	# Courtyard-local top-left of the grid.
	return -Vector2(columns, rows) * cell_size / 2.0

func _cell_center(cell: Vector2i) -> Vector2:
	return _courtyard.to_global(_grid_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size)

func _idol_position() -> Vector2:
	var o := _grid_origin()
	return _courtyard.to_global(Vector2(o.x + (gate_column + 0.5) * cell_size, o.y - WALL_THICKNESS - cell_size))


func _build_walls() -> void:
	var o := _grid_origin()
	var w := columns * cell_size
	var h := rows * cell_size
	var t := WALL_THICKNESS
	var gap_l := o.x + gate_column * cell_size
	var gap_r := gap_l + cell_size
	# Courtyard: top wall (gate gap), bottom wall (entrance gap), sides.
	_walls = [
		Rect2(o.x - t, o.y - t, gap_l - (o.x - t), t),
		Rect2(gap_r, o.y - t, o.x + w + t - gap_r, t),
		Rect2(o.x - t, o.y + h, gap_l - (o.x - t), t),
		Rect2(gap_r, o.y + h, o.x + w + t - gap_r, t),
		Rect2(o.x - t, o.y, t, h),
		Rect2(o.x + w, o.y, t, h),
	]
	# Shrine room above the gate, three cells wide and two deep.
	var room_l := gap_l - cell_size
	var room_r := gap_r + cell_size
	var room_top := o.y - t - cell_size * 2.0
	_walls.append(Rect2(room_l - t, room_top - t, room_r - room_l + t * 2.0, t))
	_walls.append(Rect2(room_l - t, room_top, t, cell_size * 2.0))
	_walls.append(Rect2(room_r, room_top, t, cell_size * 2.0))
	var body := StaticBody2D.new()
	body.name = "RuinWalls"
	for rect in _walls:
		body.add_child(_rect_shape(rect))
	_courtyard.add_child(body)
	_gate_rect = Rect2(gap_l, o.y - t, cell_size, t)
	_gate_body = StaticBody2D.new()
	_gate_body.name = "Gate"
	_gate_body.add_child(_rect_shape(_gate_rect))
	_courtyard.add_child(_gate_body)


func _rect_shape(rect: Rect2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	return shape


# --- Drawing ------------------------------------------------------------------

func _get_objective_text() -> String:
	if idol_taken:
		return "Idol taken! Head to the rowboat."
	if gate_open:
		return "The gate is open! Grab the idol."
	var covered := 0
	for plate in plate_cells:
		if _boulder_cells.has(plate):
			covered += 1
	return "Plates covered: %d / %d" % [covered, plate_cells.size()]


func _is_objective_complete() -> bool:
	return idol_taken


func _get_incomplete_message() -> String:
	return "The idol is still in the shrine!"


func _draw_courtyard() -> void:
	var o := _grid_origin()
	var floor_color := Color8(150, 146, 136)
	_courtyard.draw_rect(Rect2(o, Vector2(columns, rows) * cell_size), floor_color)
	var room := Rect2(o.x + (gate_column - 1) * cell_size, o.y - WALL_THICKNESS - cell_size * 2.0, cell_size * 3.0, cell_size * 2.0 + WALL_THICKNESS)
	_courtyard.draw_rect(room, floor_color.darkened(0.15))
	for c in columns:
		for r in rows:
			var cell := Rect2(o + Vector2(c, r) * cell_size, Vector2.ONE * cell_size)
			_courtyard.draw_rect(cell, Color(0, 0, 0, 0.12), false, 1.0)
	for plate in plate_cells:
		var rect := Rect2(o + Vector2(plate) * cell_size, Vector2.ONE * cell_size).grow(-8.0)
		var pressed := _boulder_cells.has(plate)
		_courtyard.draw_rect(rect, Color8(120, 200, 120) if pressed else Color8(200, 170, 70))
		_courtyard.draw_rect(rect, Color(0, 0, 0, 0.4), false, 2.0)
	for rect in _walls:
		_courtyard.draw_rect(rect, Color8(92, 88, 84))
	if not gate_open:
		_courtyard.draw_rect(_gate_rect, Color8(110, 70, 40))
		for i in 4:
			var x := _gate_rect.position.x + 6.0 + i * 12.0
			_courtyard.draw_line(Vector2(x, _gate_rect.position.y), Vector2(x, _gate_rect.end.y), Color8(60, 40, 25), 2.0)
	if not idol_taken:
		var idol := _courtyard.to_local(_idol_position())
		_courtyard.draw_rect(Rect2(idol + Vector2(-8, -4), Vector2(16, 18)), Color8(240, 200, 50))
		_courtyard.draw_circle(idol + Vector2(0, -10), 8.0, Color8(250, 215, 70))


func _draw_boulder(boulder: StaticBody2D) -> void:
	var half := (cell_size - 6.0) / 2.0
	boulder.draw_circle(Vector2(0, 3), half, Color(0, 0, 0, 0.25))
	boulder.draw_circle(Vector2.ZERO, half, Color8(124, 96, 72))
	boulder.draw_circle(Vector2(-6, -6), half * 0.45, Color8(156, 124, 96))


func _draw_skull() -> void:
	_skull.draw_rect(Rect2(-20, -6, 40, 14), Color8(100, 96, 90))
	_skull.draw_circle(Vector2(0, -18), 16.0, Color8(230, 226, 210))
	_skull.draw_circle(Vector2(-6, -20), 4.5, Color8(30, 30, 30))
	_skull.draw_circle(Vector2(6, -20), 4.5, Color8(30, 30, 30))
	_skull.draw_rect(Rect2(-6, -8, 12, 5), Color8(230, 226, 210))
