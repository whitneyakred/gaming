extends Control
## Small replaceable vector icons; no texture/shader dependency.
var is_health: bool = true
var shown: float = 1.0
var target: float = 1.0
var low: bool = false
var age: float = 0.0
var bump: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(155, 30)
	mouse_filter = Control.MOUSE_FILTER_PASS

func update_value(ratio: float, warning: bool) -> void:
	var next := clampf(ratio, 0, 1)
	if next > target + 0.01:
		bump = 1.0
	target = next
	low = warning
	tooltip_text = "%s: %d%%" % ["Health" if is_health else "Hunger", roundi(target * 100)]

func _process(delta: float) -> void:
	shown = move_toward(shown, target, delta * 1.7)
	bump = maxf(0, bump - delta * 3)
	age += delta
	queue_redraw()

func _draw() -> void:
	var ink := Color("#efdfbc")
	var filled := Color("#cb6861") if is_health else Color("#d5aa63")
	if low and not VoyageSurvival.reduced_motion:
		filled = filled.lerp(ink, (sin(age * 3.5) * 0.5 + 0.5) * 0.25)
	var points := PackedVector2Array([
		Vector2(1, 5), Vector2(3, 2), Vector2(7, 2), Vector2(10, 5),
		Vector2(13, 2), Vector2(17, 2), Vector2(19, 5), Vector2(19, 9),
		Vector2(10, 18), Vector2(1, 9)])
	if not is_health:
		points = PackedVector2Array([Vector2(1, 6), Vector2(3, 2), Vector2(8, 1),
			Vector2(13, 3), Vector2(15, 7), Vector2(12, 12), Vector2(7, 14), Vector2(2, 11)])
	for index in range(5):
		var y := 5.0
		if not VoyageSurvival.reduced_motion:
			y -= sin(float(index) * 0.6 + age * 4) * bump * 2
		draw_set_transform(Vector2(index * 23, y))
		if not is_health:
			draw_line(Vector2(11, 10), Vector2(17, 17), ink.darkened(0.25), 3)
			draw_circle(Vector2(18, 16), 2, ink)
			draw_circle(Vector2(16, 18), 2, ink)
		draw_colored_polygon(points, Color("#453b32"))
		var amount := clampf(shown * 5 - index, 0, 1)
		if amount > 0:
			var mask := PackedVector2Array([Vector2(0, 0), Vector2(20 * amount, 0),
				Vector2(20 * amount, 20), Vector2(0, 20)])
			for polygon in Geometry2D.intersect_polygons(points, mask):
				draw_colored_polygon(polygon, filled)
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, ink.darkened(0.4), 1, true)
	draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(120, 22), "%d" % roundi(target * 100),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
