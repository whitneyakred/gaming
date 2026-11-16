class_name OvergrownIsle
extends IslandGame

## Overgrown Isle: find the lost compass in a dark jungle maze.
## The jungle is so thick you can only see a small circle around you. The
## maze is different every visit. Find the compass (it goes into your bag),
## then find your way back out to the rowboat.
##
## Scene setup: the Maze marker is the centre of the maze. The entrance is in
## the middle of its bottom edge, so put the dock below it.

@export_group("Maze")
@export var maze_path: NodePath = ^"World/Maze"
@export var columns: int = 9
@export var rows: int = 7
@export var cell_size: float = 64.0
@export var wall_thickness: float = 12.0
## Leave empty for a new maze every visit; set a number for the same maze.
@export var fixed_seed: int = 0
@export var reward_item_id: StringName = &"compass"

@export_group("Darkness")
@export var light_radius: float = 95.0
@export var light_softness: float = 45.0
## Darkness inside the jungle and out on the beach (0 = none, 1 = black).
@export_range(0.0, 1.0) var jungle_darkness: float = 0.96
@export_range(0.0, 1.0) var beach_darkness: float = 0.88

const DARKNESS_SHADER := """
shader_type canvas_item;
uniform float radius = 95.0;
uniform float softness = 45.0;
uniform float strength = 0.96;
uniform vec2 rect_size = vec2(3000.0, 3000.0);
void fragment() {
	float d = distance(UV * rect_size, rect_size * 0.5);
	COLOR = vec4(0.01, 0.04, 0.02, smoothstep(radius, radius + softness, d) * strength);
}
"""
const DARKNESS_SIZE: float = 3000.0

var compass_found: bool = false

var _maze: Node2D
var _walls: Array[Rect2] = []        # maze-local
var _compass_cell: Vector2i
var _darkness: Node2D
var _darkness_material: ShaderMaterial
var _strength: float = 0.0
var _time: float = 0.0


func _setup_game() -> void:
	_maze = get_node_or_null(maze_path) as Node2D
	assert(_maze != null, "OvergrownIsle needs a Maze marker.")
	_maze.z_index = -5
	_maze.draw.connect(_draw_maze)
	_generate()
	_build_darkness()


func _game_process(delta: float) -> void:
	_time += delta
	if player == null:
		return
	if not compass_found and player.global_position.distance_to(_cell_center(_compass_cell)) < 22.0:
		_take_compass()
	var target := jungle_darkness if _in_maze(player.global_position) else beach_darkness
	_strength = move_toward(_strength, target, delta * 1.5)
	_darkness.global_position = player.global_position
	_darkness_material.set_shader_parameter("strength", _strength)
	_maze.queue_redraw()


func _take_compass() -> void:
	compass_found = true
	give_item(reward_item_id, 1)
	refresh_hud()
	show_message("You found the lost compass! Now find your way out.", 2.0)


# --- Maze ---------------------------------------------------------------------

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	if fixed_seed != 0:
		rng.seed = fixed_seed
	else:
		rng.randomize()
	# open[cell] = list of neighbouring cells with no wall in between.
	var open: Dictionary[Vector2i, Array] = {}
	for c in columns:
		for r in rows:
			open[Vector2i(c, r)] = []
	# Depth-first "recursive backtracker": long winding corridors.
	var entrance := Vector2i(floori(columns / 2.0), rows - 1)
	var stack: Array[Vector2i] = [entrance]
	var visited: Dictionary[Vector2i, bool] = {entrance: true}
	while not stack.is_empty():
		var cell: Vector2i = stack.back()
		var options: Array[Vector2i] = []
		for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + step
			if open.has(next) and not visited.has(next):
				options.append(next)
		if options.is_empty():
			stack.pop_back()
			continue
		var chosen := options[rng.randi() % options.size()]
		open[cell].append(chosen)
		open[chosen].append(cell)
		visited[chosen] = true
		stack.append(chosen)

	# Hide the compass in the cell farthest (by walking) from the entrance.
	var distance: Dictionary[Vector2i, int] = {entrance: 0}
	var queue: Array[Vector2i] = [entrance]
	_compass_cell = entrance
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if distance[cell] > distance[_compass_cell]:
			_compass_cell = cell
		for next in open[cell]:
			if not distance.has(next):
				distance[next] = distance[cell] + 1
				queue.append(next)

	_build_walls(open, entrance)


func _build_walls(open: Dictionary[Vector2i, Array], entrance: Vector2i) -> void:
	var o := _origin()
	var t := wall_thickness
	_walls.clear()
	# Horizontal walls: row lines 0..rows.
	for r in rows + 1:
		for c in columns:
			var above := Vector2i(c, r - 1)
			var below := Vector2i(c, r)
			var wall := r == 0 or r == rows or not open[above].has(below)
			if r == rows and c == entrance.x:
				wall = false
			if wall:
				_walls.append(Rect2(o.x + c * cell_size - t / 2.0, o.y + r * cell_size - t / 2.0, cell_size + t, t))
	# Vertical walls: column lines 0..columns.
	for c in columns + 1:
		for r in rows:
			var left := Vector2i(c - 1, r)
			var right := Vector2i(c, r)
			if c == 0 or c == columns or not open[left].has(right):
				_walls.append(Rect2(o.x + c * cell_size - t / 2.0, o.y + r * cell_size - t / 2.0, t, cell_size + t))
	var body := StaticBody2D.new()
	body.name = "Hedges"
	for rect in _walls:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)
	_maze.add_child(body)


func _origin() -> Vector2:
	return -Vector2(columns, rows) * cell_size / 2.0

func _cell_center(cell: Vector2i) -> Vector2:
	return _maze.to_global(_origin() + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size)

func _in_maze(point: Vector2) -> bool:
	var local := _maze.to_local(point)
	return Rect2(_origin(), Vector2(columns, rows) * cell_size).has_point(local)


func _build_darkness() -> void:
	_darkness = Node2D.new()
	_darkness.name = "Darkness"
	_darkness.z_index = 50
	var cover := ColorRect.new()
	cover.size = Vector2.ONE * DARKNESS_SIZE
	cover.position = -cover.size / 2.0
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = DARKNESS_SHADER
	_darkness_material = ShaderMaterial.new()
	_darkness_material.shader = shader
	_darkness_material.set_shader_parameter("radius", light_radius)
	_darkness_material.set_shader_parameter("softness", light_softness)
	_darkness_material.set_shader_parameter("rect_size", cover.size)
	_darkness_material.set_shader_parameter("strength", 0.0)
	cover.material = _darkness_material
	_darkness.add_child(cover)
	add_child(_darkness)


# --- HUD and drawing ----------------------------------------------------------

func _get_objective_text() -> String:
	if compass_found:
		return "Compass found! Find your way back to the rowboat."
	return "Find the lost compass in the jungle maze"


func _is_objective_complete() -> bool:
	return compass_found


func _get_incomplete_message() -> String:
	return "The compass is still somewhere in the jungle!"


func _draw_maze() -> void:
	var o := _origin()
	_maze.draw_rect(Rect2(o, Vector2(columns, rows) * cell_size), Color8(74, 104, 52))
	for rect in _walls:
		_maze.draw_rect(rect, Color8(32, 70, 30))
		_maze.draw_rect(rect.grow(-3.0), Color8(44, 92, 40))
	if not compass_found:
		var at := _maze.to_local(_cell_center(_compass_cell))
		var glint := 0.6 + 0.4 * sin(_time * 5.0)
		_maze.draw_circle(at, 10.0, Color8(190, 150, 70))
		_maze.draw_circle(at, 7.0, Color8(235, 225, 190))
		_maze.draw_line(at + Vector2(0, -6), at + Vector2(0, 2), Color(0.8, 0.1, 0.1), 2.0)
		_maze.draw_circle(at + Vector2(5, -6), 2.0, Color(1, 1, 1, glint))
