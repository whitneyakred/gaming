class_name Ocean
extends Node2D

# Pixel-art ocean that fills the screen and scrolls to show movement.
# Wave marks come from one small deterministic tile that repeats forever
# (recycled), so the water never runs out no matter how far the ship sails.

# How fast the water scrolls past, in pixels per second. The ship scene
# changes this while sailing / anchoring; the island leaves it low.
@export var scroll_speed: float = 0.0
@export var water_color: Color = Color8(64, 68, 130)
@export var wave_color: Color = Color8(78, 92, 149)
@export var foam_color: Color = Color8(95, 132, 168)
# Area to cover around this node (bigger than the 1280x720 viewport).
@export var cover_size: Vector2 = Vector2(1600, 1000)

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
	var half := cover_size / 2.0
	draw_rect(Rect2(-half, cover_size), water_color)
	var tiles_x := int(ceil(cover_size.x / TILE)) + 1
	var tiles_y := int(ceil(cover_size.y / TILE)) + 2
	var start := Vector2(-tiles_x / 2 * TILE, -tiles_y / 2 * TILE)
	for ty in tiles_y:
		for tx in tiles_x:
			var origin := start + Vector2(tx * TILE, ty * TILE + scroll_offset)
			for i in _waves.size():
				var w: Vector3 = _waves[i]
				# Small sideways sway so the sea looks alive even at anchor.
				var sway := sin(_time * 1.3 + i) * 2.0
				var p := origin + Vector2(w.x + sway, w.y)
				p = (p / PIXEL).floor() * PIXEL
				if abs(p.x) > half.x or abs(p.y) > half.y:
					continue
				var colour := foam_color if i % 5 == 0 else wave_color
				draw_rect(Rect2(p, Vector2(w.z * PIXEL, PIXEL)), colour)
