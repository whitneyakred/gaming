extends Node2D
## Camera following and recycled ocean marks, with only a wind arrow and helm indicator.

@export var ship: ShipMotion
@export var helm: HelmStation
@export var camera: Camera2D
@onready var wind_arrow: Label = $HUD/Wind/Arrow
@onready var helm_wheel: HelmWheelWidget = $HUD/HelmWheel

func _process(_delta: float) -> void:
	if not is_instance_valid(ship):
		return
	camera.global_position = ship.global_position
	# The camera does not rotate, so the arrow uses the world wind direction.
	wind_arrow.rotation = ship.wind_velocity.angle() + PI / 2.0
	wind_arrow.visible = not ship.wind_velocity.is_zero_approx()
	var using_helm := is_instance_valid(helm.local_player) and helm.operator == helm.local_player
	helm_wheel.set_helm_state(using_helm, ship.wheel_angle_degrees)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(camera):
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
