extends Node
## A bow against a slanted shore: the nearest-shore normal can differ from
## the edge touched by the bow, as it does around island corners.
class CornerShip extends ShipMotion:
	var side: float = 1.0
	func _is_pose_blocked(at: Vector2, angle: float) -> bool:
		for point in get_hull_polygon(at, angle):
			if side * point.x - point.y > 250.01:
				return true
		return false
	func _get_shore_normal(_at: Vector2) -> Vector2:
		return Vector2.DOWN

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures := 0
	for side: float in [-1.0, 1.0]:
		var ship := CornerShip.new()
		ship.side = side
		ship.hull_outline = PackedVector2Array([Vector2(-50, -200), Vector2(50, -200), Vector2(50, 200), Vector2(-50, 200)])
		get_tree().root.add_child(ship)
		ship.set_physics_process(false)
		ship.set_process(false)
		ship.speed = 110.0
		ship.set_sail_level(3)
		ship.set_wheel_angle(side * 540.0)
		var start := ship.position
		for frame in 120:
			ship._physics_process(1.0 / 60.0)
			if ship._is_pose_blocked(ship.position, ship.rotation):
				push_error("Recovery must never overlap land")
				failures += 1
		if ship.position.distance_to(start) < 20.0:
			push_error("Ship must escape the corner when steering to either side")
			failures += 1
		# A fully stopped anchor must never acquire an outward nudge.
		ship.position = Vector2.ZERO
		ship.rotation = 0.0
		ship.speed = 0.0
		ship.anchor_deployed = true
		for frame in 60:
			ship._physics_process(1.0 / 60.0)
		if ship.position != Vector2.ZERO or ship.rotation != 0.0:
			push_error("Stopped anchored ship must stay fixed beside shore")
			failures += 1
		# Ordinary sailing and helm input still work clear of shore.
		ship.position = Vector2(0, 1000)
		ship.anchor_deployed = false
		for frame in 120:
			ship._physics_process(1.0 / 60.0)
		if ship.aground or ship.position.distance_to(Vector2(0, 1000)) < 20.0 or ship.rotation * side <= 0.0:
			push_error("Open-water sailing and steering must remain responsive")
			failures += 1
		ship.free()
	print("Shore recovery: %d failure(s)" % failures)
	get_tree().quit(1 if failures else 0)
