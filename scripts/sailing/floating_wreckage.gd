extends Node2D
## A bounded deterministic field around the swimmer. No world-sized node list.
signal wood_collected(total: int)
@export var cell_size: float = 720.0
@export var pickup_distance: float = 26.0
@export var world_seed: int = 7319
var planks: Dictionary[Vector2i, Vector2] = {}
@onready var ship: Ship = get_parent()

func _ready() -> void:
	set_as_top_level(true)
	global_transform = Transform2D.IDENTITY
	z_index = -5

func plank_position(cell: Vector2i) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, world_seed))
	return Vector2(cell) * cell_size + Vector2(rng.randf_range(40, cell_size - 40), rng.randf_range(40, cell_size - 40))

func _physics_process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var center := ship.player.global_position
	var half := Vector2(800, 500)
	if camera:
		center = camera.get_screen_center_position()
		half = get_viewport_rect().size / camera.zoom * 0.5
	var first := Vector2i(((center - half) / cell_size).floor()) - Vector2i.ONE
	var last := Vector2i(((center + half) / cell_size).ceil()) + Vector2i.ONE
	planks.clear()
	var hull := ship.get_hull_polygon(ship.global_position, ship.global_rotation)
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			var cell := Vector2i(x, y)
			if VoyageState.collected_wreckage.has(cell):
				continue
			var point := plank_position(cell)
			if Geometry2D.is_point_in_polygon(point, hull):
				continue
			var on_land := false
			for island in ship.get_islands():
				if Geometry2D.is_point_in_polygon(point, island.get_coast()) or point.distance_to(island.get_nearest_coast_point(point)) < 45:
					on_land = true
					break
			if on_land:
				continue
			planks[cell] = point
			if ship.player.is_overboard and ship.player.global_position.distance_to(point) <= pickup_distance:
				VoyageState.collected_wreckage[cell] = true
				VoyageState.salvaged_wood += 1
				planks.erase(cell)
				wood_collected.emit(VoyageState.salvaged_wood)
	queue_redraw()

func _draw() -> void:
	for cell in planks:
		var point: Vector2 = planks[cell]
		draw_set_transform(point, float(posmod(cell.x * 17 + cell.y * 31, 12)) * PI / 12.0)
		draw_rect(Rect2(-20, -6, 40, 12), Color("513421"))
		draw_rect(Rect2(-18, -4, 36, 8), Color("b88851"))
		draw_line(Vector2(-15, 0), Vector2(15, 0), Color("805632"), 2)
		draw_circle(Vector2(-12, 1), 1.5, Color("423528"))
		draw_circle(Vector2(12, 1), 1.5, Color("423528"))
