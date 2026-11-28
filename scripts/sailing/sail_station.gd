class_name SailStation
extends ShipStation
## Furled plus three reef settings. Only visual cloth is animated, never physics.
const CLOTH := preload("res://assets/props/sail_pixel.tres")
const STRIPS := 16
@export_range(1.0, 90.0) var trim_speed_degrees: float = 34.0
@export var sail_width := 256.0
@export var reef_heights := PackedFloat32Array([0.0, 22.0, 38.0, 58.0])
@export_range(0.1, 1.0) var obscured_opacity := 0.4
var cloth_height := 0.0
var cloth_opacity := 1.0
var wind_phase := 0.0
var visual_speed := 0.0
var _previous_ship_position := Vector2.ZERO

func _ready() -> void:
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ship.sail_changed.connect(queue_redraw)
	cloth_height = reef_heights[ship.sail_level]
	_previous_ship_position = ship.global_position

func _apply_controls(delta: float) -> void:
	ship.set_sail_angle(ship.sail_angle_degrees + Input.get_axis("move_left", "move_right") * trim_speed_degrees * delta)
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		ship.set_sail_level((ship.sail_level + 1) % 4)

func _process(delta: float) -> void:
	if not is_instance_valid(ship): return
	var travelled := ship.global_position.distance_to(_previous_ship_position)
	_previous_ship_position = ship.global_position
	var measured := travelled / maxf(delta, 0.0001)
	if not NetworkSession.online or multiplayer.is_server(): measured = absf(ship.speed)
	if measured > ship.maximum_speed * 4.0: measured = 0.0 # Teleport is not wind.
	visual_speed = lerpf(visual_speed, clampf(measured, 0, ship.maximum_speed), 1.0 - exp(-4.0 * delta))
	wind_phase = fmod(wind_phase + delta * (1.8 + 3.0 * speed_ratio() + ship.wind_velocity.length()), TAU)
	cloth_height = lerpf(cloth_height, reef_heights[ship.sail_level], 1.0 - exp(-8.0 * delta))
	if is_instance_valid(local_player) and local_player.active_station == self:
		cloth_opacity = 1.0
	else:
		cloth_opacity = lerpf(cloth_opacity, obscured_opacity if crew_under_sail() else 1.0, 1.0 - exp(-12.0 * delta))
	queue_redraw()

func speed_ratio() -> float:
	return clampf(visual_speed / maxf(ship.maximum_speed, 1.0), 0, 1)

func crew_under_sail() -> bool:
	if not is_instance_valid(local_player) or local_player.is_overboard or local_player.island_challenge: return false
	if local_player.active_station == self: return false
	var head: Vector2 = to_local(local_player.visual_position() + Vector2(0, -18)).rotated(-deg_to_rad(ship.sail_angle_degrees))
	# The canvas billows toward local UP, matching ShipMotion's wind-catching normal.
	head.y = -head.y
	return Rect2(-sail_width * 0.5 - 8, -12, sail_width + 16, cloth_height + 25).has_point(head)

func _draw() -> void:
	if not is_instance_valid(ship): return
	draw_set_transform(Vector2.ZERO, deg_to_rad(ship.sail_angle_degrees), Vector2(1, -1))
	var source := CLOTH.get_size()
	var yard_height := source.y * 0.3
	var tint := Color(1, 1, 1, cloth_opacity)
	draw_texture_rect_region(CLOTH, Rect2(-sail_width * 0.5, -5, sail_width, 6), Rect2(0, 0, source.x, yard_height), tint)
	if cloth_height < 0.5:
		return
	var width := sail_width / STRIPS
	var amplitude := (0.6 + 1.8 * speed_ratio()) * minf(cloth_height / 14.0, 1.0)
	for i in STRIPS:
		var u := (i + 0.5) / STRIPS
		# Ends stay tied; the free hem billows while the straight yard stays fixed.
		var wave := sin(wind_phase + u * TAU) * sin(u * PI) * amplitude
		var rect := Rect2(-sail_width * 0.5 + i * width, 1, width, cloth_height + wave)
		var region := Rect2(i * source.x / STRIPS, yard_height, source.x / STRIPS, source.y - yard_height)
		draw_texture_rect_region(CLOTH, rect, region, tint)
