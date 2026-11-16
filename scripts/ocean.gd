class_name Ocean
extends Node2D

# Pixel-art ocean that fills the screen and scrolls to show movement.
# Wave marks come from one small deterministic tile that repeats forever
# (recycled), so the water never runs out no matter how far the ship sails.

# How fast the water scrolls past, in pixels per second. The ship scene
# changes this while sailing / anchoring; the island leaves it low.
@export var scroll_speed: float = 0.0
@export var water_color: Color = Color("142f40")
@export var wave_color: Color = Color("1e4054")
@export var foam_color: Color = Color("345a6b")
# Smallest area to cover. The water always grows to fill the whole screen
# around the camera too, however big the window is.
@export var cover_size: Vector2 = Vector2(1600, 1000)
## Use world coordinates for sailing; islands may still use the ambient scroll.
@export var world_anchored: bool = false

const TILE: int = 192
const PIXEL: int = 2   # matches the ship's 2x pixel scale
const WAVE_COUNT: int = 22

var scroll_offset: float = 0.0
var _waves: Array[Vector3] = []   # x, y, length (in tile space)
var _time: float = 0.0

func _ready() -> void:
	# Fixed seed = the same wave pattern every run.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in WAVE_COUNT:
		_waves.append(Vector3(rng.randi_range(0, TILE - 1), rng.randi_range(0, TILE - 1), rng.randi_range(3, 7)))

func _process(delta: float) -> void:
	_time += delta
	scroll_offset = fmod(scroll_offset + scroll_speed * delta, float(TILE))
	queue_redraw()

func _draw() -> void:
	var area := cover_size
	var center := Vector2.ZERO
	var camera := get_viewport().get_camera_2d()
	if is_instance_valid(camera):
		center = to_local(camera.get_screen_center_position())
		area = area.max(get_viewport_rect().size / camera.zoom + Vector2.ONE * TILE * 2)
	else:
		area = area.max(get_viewport_rect().size + Vector2.ONE * TILE * 2)
	draw_set_transform(center)
	var half := area / 2.0
	draw_rect(Rect2(-half, area), water_color)
	if world_anchored:
		var world_center := to_global(center)
		var visible_world := Rect2(world_center-half,area)
		var safe := Rect2(-11000,-11000,22000,22000)
		for red in [Rect2(visible_world.position,Vector2(maxf(0,safe.position.x-visible_world.position.x),area.y)),Rect2(Vector2(maxf(safe.end.x,visible_world.position.x),visible_world.position.y),Vector2(maxf(0,visible_world.end.x-safe.end.x),area.y)),Rect2(visible_world.position,Vector2(area.x,maxf(0,safe.position.y-visible_world.position.y))),Rect2(Vector2(visible_world.position.x,maxf(safe.end.y,visible_world.position.y)),Vector2(area.x,maxf(0,visible_world.end.y-safe.end.y)))]:
			var clipped: Rect2 = red.intersection(visible_world)
			if clipped.has_area(): draw_rect(Rect2(clipped.position-world_center,clipped.size), Color("522331"))
	var tiles_x := int(ceil(area.x / TILE)) + 2
	var tiles_y := int(ceil(area.y / TILE)) + 2
	var start := Vector2(-tiles_x / 2 * TILE, -tiles_y / 2 * TILE)
	# Line the wave tiles up with this node so they stay put when the camera
	# moves (only scroll_offset makes them drift).
	var offset := Vector2(fposmod(-center.x, TILE), fposmod(-center.y + scroll_offset, TILE))
	if world_anchored:
		var world_center := to_global(center)
		offset = Vector2(fposmod(-world_center.x, TILE), fposmod(-world_center.y, TILE))
	for ty in tiles_y:
		for tx in tiles_x:
			var origin := start + Vector2(tx * TILE, ty * TILE) + offset
			for i in _waves.size():
				var w: Vector3 = _waves[i]
				# Small sideways sway so the sea looks alive even at anchor.
				var sway := sin(_time * 1.3 + i) * 2.0
				var p := origin + Vector2(w.x + sway, w.y)
				p = (p / PIXEL).floor() * PIXEL
				if abs(p.x) > half.x or abs(p.y) > half.y:
					continue
				var colour := foam_color if i % 5 == 0 else wave_color
				if world_anchored and WorldLayout.danger(to_global(center+p)): colour = Color("8c3c47") if i%5 == 0 else Color("6a2c39")
				draw_rect(Rect2(p, Vector2(w.z * PIXEL, PIXEL)), colour)
