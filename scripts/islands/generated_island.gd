class_name GeneratedIsland
extends WorldIsland
## Geometry is built once from a per-island seed. All clients use the same layout.
const VERTICES := 96
const CLEARING := Rect2(-560, -380, 1120, 760)
var terrain_seed := 1
var coast_points := PackedVector2Array()
var footprint := 0.0
var terrain: Node2D

static func outline(seed_value: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var size := Vector2(rng.randf_range(1550,2150),rng.randf_range(1250,1850))
	var phase := Vector3(rng.randf_range(0,TAU),rng.randf_range(0,TAU),rng.randf_range(0,TAU))
	var turn := rng.randf_range(0,TAU)
	var lobes := rng.randi_range(2,4)
	var points := PackedVector2Array()
	for i in VERTICES:
		var angle := TAU*i/VERTICES
		var direction := Vector2.from_angle(angle)
		var ellipse := (direction*size).length()
		var shape := 1.0 + sin(angle*lobes+phase.x)*0.16 + sin(angle*5.0+phase.y)*0.085 + sin(angle*9.0+phase.z)*0.025
		# A guaranteed wide interior keeps the clearing and its approaches playable.
		points.append((direction*maxf(ellipse*shape,1030.0)).rotated(turn).snapped(Vector2(3,3)))
	return points

func configure(seed_value: int) -> void:
	terrain_seed = seed_value
	coast_points = outline(seed_value)
	for point in coast_points: footprint = maxf(footprint,point.length())
	# Choose a real shoreline landing; never inherit the old picture's dock.
	dock_offset = coast_points[VERTICES/4].normalized()*(coast_points[VERTICES/4].length()+100.0)
	var land := StaticBody2D.new()
	land.name = "Land"
	var coast := CollisionPolygon2D.new()
	coast.name = "Coast"
	coast.polygon = coast_points
	land.add_child(coast)
	add_child(land)

func _ready() -> void:
	super._ready()
	terrain = IslandGround.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(coast_points,terrain_seed,true)

func challenge_position() -> Vector2:
	return to_global(Vector2(0,-220))
