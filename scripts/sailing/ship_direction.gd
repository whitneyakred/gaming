extends Control
## Screen-space bearing back to the ship, independent of the wind arrow.
@export var edge_margin: float = 48.0
@export var far_distance: float = 650.0
var ship: Ship
var _point: Vector2
var _direction: Vector2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship = get_parent().get_parent().ship as Ship

func _process(_delta: float) -> void:
	visible = is_instance_valid(ship) and ship.player.is_overboard
	if not visible:
		return
	var viewport_size := get_viewport_rect().size
	var margin := minf(edge_margin, minf(viewport_size.x, viewport_size.y) * 0.2)
	var screen_ship := ship.get_global_transform_with_canvas().origin
	var safe := Rect2(Vector2.ONE * margin, viewport_size - Vector2.ONE * margin * 2)
	visible = not safe.has_point(screen_ship) or ship.player.global_position.distance_to(ship.global_position) > far_distance
	if not visible:
		return
	var center := viewport_size * 0.5
	_direction = (screen_ship - center).normalized()
	var half := (viewport_size * 0.5 - Vector2.ONE * margin).max(Vector2.ONE)
	var reach := minf(half.x / maxf(absf(_direction.x), 0.001), half.y / maxf(absf(_direction.y), 0.001))
	_point = center + _direction * reach
	queue_redraw()

func _draw() -> void:
	draw_circle(_point, 22, Color(0.04, 0.07, 0.12, 0.8))
	var side := _direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([_point + _direction * 16, _point - _direction * 10 + side * 9, _point - _direction * 10 - side * 9]), Color("f2d58b"))
	var label := _point - _direction * 40 + Vector2(-15, 5)
	draw_string(ThemeDB.fallback_font, label, "Ship", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
