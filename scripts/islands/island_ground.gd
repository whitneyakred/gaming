class_name IslandGround
extends Node2D
## Static layered polygons share one terrain atlas. No per-frame rebuilds or tiles.
const ATLAS := preload("res://assets/terrain/island_materials.png")
const GROUND := preload("res://shaders/island_ground.gdshader")
const SHORE := preload("res://shaders/island_shore.gdshader")
var polygon_count := 0
var clearing_polygon := PackedVector2Array()
var path_polygon := PackedVector2Array()

func ring(points: PackedVector2Array, distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points: result.append(point.normalized()*maxf(1.0,point.length()+distance))
	return result

func fill(points: PackedVector2Array, color: Color, type: int = -1, shift := Vector2.ZERO) -> Polygon2D:
	var surface := Polygon2D.new()
	surface.polygon = points
	surface.color = color
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if type >= 0:
		var paint := ShaderMaterial.new()
		paint.shader = GROUND
		paint.set_shader_parameter("atlas",ATLAS)
		paint.set_shader_parameter("quadrant",Vector2(type%2,type/2))
		paint.set_shader_parameter("offset",shift)
		paint.set_shader_parameter("tone",color.r)
		surface.material = paint
	add_child(surface)
	polygon_count += 1
	return surface

func edge(points: PackedVector2Array, width: float, color: Color) -> void:
	var line := Line2D.new()
	line.points = points
	line.closed = true
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.round_precision = 2
	add_child(line)

func blob(center: Vector2, radius: Vector2, phase: float, count: int = 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count:
		var angle := TAU*i/count
		points.append((center+Vector2.from_angle(angle)*radius*(1.0+sin(angle*5.0+phase)*0.04+sin(angle*9.0+phase)*0.015)).snapped(Vector2(3,3)))
	return points

func build(coast: PackedVector2Array, seed_value: int, clearing: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var shift := Vector2(rng.randf_range(0,2400),rng.randf_range(0,2400))
	# One narrow mesh shades just the water margin, not the entire island rectangle.
	var shallows := Polygon2D.new()
	shallows.polygon = coast+ring(coast,190)
	var colors := PackedColorArray()
	for i in coast.size(): colors.append(Color(0,0,0,1))
	for i in coast.size(): colors.append(Color(1,0,0,1))
	shallows.vertex_colors = colors
	var faces: Array[PackedInt32Array] = []
	for i in coast.size():
		var j := (i+1)%coast.size()
		faces.append(PackedInt32Array([i,j,j+coast.size(),i+coast.size()]))
	shallows.polygons = faces
	var water := ShaderMaterial.new()
	water.shader = SHORE
	shallows.material = water
	add_child(shallows)
	polygon_count += 1
	fill(coast,Color.WHITE,1,shift)
	edge(ring(coast,-3),3,Color("f4e4c9"))
	var grass := ring(coast,-130.0)
	for i in grass.size(): grass[i] += grass[i].normalized()*sin(i*0.61+seed_value)*20.0
	fill(ring(grass,15),Color("bda17f"))
	fill(ring(grass,5),Color("586d4b"))
	fill(grass,Color.WHITE,0,shift)
	edge(grass,3,Color("9cad78"))
	# Ground variation only: future interactable trees/ores remain separate nodes.
	for patch in range(3):
		var angle := rng.randf_range(0,TAU)
		var center := Vector2.from_angle(angle)*rng.randf_range(800,1000)
		var points := blob(center,Vector2(rng.randf_range(110,190),rng.randf_range(85,150)),rng.randf_range(0,TAU))
		var inside := true
		for point in points:
			if not Geometry2D.is_point_in_polygon(point,grass) or (clearing and GeneratedIsland.CLEARING.grow(90).has_point(point)):
				inside = false
				break
		if not inside: continue
		edge(points,8,Color("586c56"))
		fill(points,Color(0.95,0.95,0.95),2,shift)
	if clearing:
		var court := blob(Vector2.ZERO,Vector2(800,620),rng.randf_range(0,TAU),48)
		clearing_polygon = court
		edge(court,18,Color("677d54"))
		fill(court,Color(1.04,1.04,1.04),3,shift)
		edge(court,4,Color("c4ae7f"))
