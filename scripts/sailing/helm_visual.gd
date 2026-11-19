extends Node2D
## Reads the shared ship angle, including snapshots received by remote crew.
@onready var ship: Ship = get_parent().ship
@onready var wheel: Sprite2D = $Wheel
func _process(_delta: float) -> void:
	wheel.rotation = deg_to_rad(ship.wheel_angle_degrees)
