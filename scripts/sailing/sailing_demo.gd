extends Node2D
## Camera following and recycled ocean marks, with only a wind arrow and helm indicator.

@export var ship: ShipMotion
@export var helm: HelmStation
@export var camera: Camera2D
@export var draw_ocean_marks: bool = true
@export_range(1.0, 3.0) var station_zoom_multiplier: float = 1.2
@export_range(1.0, 3.0) var helm_zoom_multiplier: float = 1.05
@export_range(0.0, 0.5) var station_vignette_opacity: float = 0.22
@export_range(1.0, 20.0) var camera_response: float = 7.0
var _normal_zoom: Vector2 = Vector2.ONE
var _station_zoom: float = 1.0
var _focus_offset: Vector2 = Vector2.ZERO
## Rowboat framing is controlled by the ship during island travel.
var view_offset: Vector2 = Vector2.ZERO
@onready var wind_arrow: TextureRect = $HUD/Wind/Arrow
@onready var helm_wheel: HelmWheelWidget = $HUD/HelmWheel
@onready var vignette: ColorRect = $StationOverlay/Vignette

func _ready() -> void:
	if is_instance_valid(camera):
		_normal_zoom = camera.zoom
		get_viewport().size_changed.connect(_refresh_camera_scale)
		GameWindow.preferences_changed.connect(_refresh_camera_scale)
		_refresh_camera_scale()

func _refresh_camera_scale() -> void:
	if is_instance_valid(camera):
		# Match vertical world coverage immediately on resize, independently of UI scale.
		camera.zoom = _normal_zoom * (get_viewport_rect().size.y / 720.0) * float(GameWindow.preferences.camera_zoom) * _station_zoom

func _process(delta: float) -> void:
	if not is_instance_valid(ship):
		return
	_update_camera(delta)
	# Show the actual smoothed wind, not its next random target. The camera does not rotate.
	wind_arrow.rotation = ship.wind_velocity.angle() + PI / 2.0
	wind_arrow.visible = not ship.wind_velocity.is_zero_approx()
	helm_wheel.set_helm_state(is_instance_valid(helm.operator), ship.wheel_angle_degrees)
	queue_redraw()

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	var station: Node2D = null
	if is_instance_valid(helm) and is_instance_valid(helm.local_player):
		station = helm.local_player.get("active_station") as Node2D
	# Rowboat travel also claims the player; only focus on actual deck stations.
	var focused := is_instance_valid(station) and station != ship and ship.stations_enabled
	var target_offset := station.global_position - ship.global_position if focused and station != helm else Vector2.ZERO
	var multiplier := helm_zoom_multiplier if station == helm else station_zoom_multiplier
	var target_zoom := multiplier if focused else 1.0
	var weight := 1.0 - exp(-camera_response * delta)
	_focus_offset = _focus_offset.lerp(target_offset, weight)
	camera.global_position = ship.global_position + _focus_offset + view_offset
	_station_zoom = lerpf(_station_zoom, target_zoom, weight)
	_refresh_camera_scale()
	vignette.modulate.a = lerpf(vignette.modulate.a, station_vignette_opacity if focused else 0.0, weight)

func _draw() -> void:
	if not draw_ocean_marks or not is_instance_valid(camera):
		return
	# Recycle a bounded grid of world-anchored wave marks around the camera.
	# Integer cell coordinates make the pattern repeatable in every direction.
	var cell_size := 100.0
	var half_view := get_viewport_rect().size / camera.zoom * 0.5
	var center := camera.global_position
	var first := Vector2i(floori((center.x - half_view.x) / cell_size) - 1,
		floori((center.y - half_view.y) / cell_size) - 1)
	var last := Vector2i(ceili((center.x + half_view.x) / cell_size) + 1,
		ceili((center.y + half_view.y) / cell_size) + 1)
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			var offset := Vector2(posmod(x * 37 + y * 17, 53), posmod(y * 29 + x * 11, 47))
			var point := to_local(Vector2(x, y) * cell_size + offset)
			draw_line(point, point + Vector2(12, 0), Color(0.35, 0.65, 0.72, 0.4), 2.0)
