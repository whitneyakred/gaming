class_name FishingFight
extends RefCounted
## Frame-rate independent tension model; RNG is injectable for reproducible tests.
var rng := RandomNumberGenerator.new()
var tension: float = 0.5
var green_center: float = 0.5
var green_width: float = 0.28
var progress: float = 0.0
var danger: float = 0.0
var elapsed: float = 0.0
var duration: float = 8.0
var target: float = 0.5
var change_in: float = 1.0
var phase: float = 0.0
var caught: bool = false
var broken: bool = false

func begin(seed_value: int) -> void:
	rng.seed = seed_value
	tension = 0.5
	green_center = 0.5
	progress = 0.0
	danger = 0.0
	elapsed = 0.0
	caught = false
	broken = false
	green_width = rng.randf_range(0.20, 0.26)
	duration = rng.randf_range(8.0, 11.0)
	target = rng.randf_range(0.36, 0.64)
	change_in = rng.randf_range(0.8, 1.7)
	phase = rng.randf_range(0.0, TAU)

func in_green() -> bool:
	return absf(tension - green_center) <= green_width * 0.5

func step(delta: float, held: bool) -> void:
	if caught or broken:
		return
	# Substeps keep long frames from skipping danger or target changes.
	var remaining := maxf(delta, 0.0)
	while remaining > 0.00001 and not caught and not broken:
		var dt := minf(remaining, 1.0 / 60.0)
		remaining -= dt
		elapsed += dt
		change_in -= dt
		if change_in <= 0:
			target = rng.randf_range(0.32, 0.68)
			change_in = rng.randf_range(0.8, 1.7)
		green_center = move_toward(green_center, target, dt * 0.18)
		var pull := sin(elapsed * 2.4 + phase) * 0.09 + sin(elapsed * 4.7 + phase) * 0.035
		tension = clampf(tension + dt * ((0.39 if held else -0.29) + pull), 0.0, 1.0)
		if in_green():
			progress = minf(1.0, progress + dt / duration)
			danger = maxf(0.0, danger - dt * 0.45)
		else:
			var gap := absf(tension - green_center) - green_width * 0.5
			danger = minf(1.0, danger + dt * (0.50 + gap * 2.2))
			progress = maxf(0.0, progress - dt * 0.025)
		caught = progress >= 1.0
		broken = danger >= 1.0 or elapsed >= 35.0
