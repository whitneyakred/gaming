class_name PixelRope
extends RefCounted
## Bounded pixel braid with a dark edge, tan body and alternating thread marks.
static func draw(canvas: CanvasItem, points: PackedVector2Array) -> void:
	if points.size() < 2: return
	canvas.draw_polyline(points, Color("51483e"), 4.0, false)
	canvas.draw_polyline(points, Color("b49b73"), 2.5, false)
	var travelled := 0.0
	var next_mark := 1.5
	var mark := 0
	for i in range(1, points.size()):
		var segment := points[i] - points[i-1]
		var length := segment.length()
		if length < 0.01: continue
		var direction := segment / length
		var normal := direction.orthogonal()
		while next_mark < travelled + length:
			var point := points[i-1] + direction * (next_mark - travelled)
			canvas.draw_line(point - normal * 0.7, point + normal * 0.7 + direction, Color("ddc7a1") if mark % 2 == 0 else Color("887157"), 1.0, false)
			next_mark += 3.0
			mark += 1
		travelled += length
