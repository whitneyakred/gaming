class_name SailStation
extends ShipStation
## Four deployment states share a centered pivot. Artwork is vertical in its PNG.

@export_range(1.0, 90.0) var trim_speed_degrees: float = 34.0
@export var sail_textures: Array[Texture2D] = []
@onready var artwork: Sprite2D = $SailArtwork

func _ready() -> void:
	ship.sail_changed.connect(_update_artwork)
	_update_artwork()

func apply_controls(direction: Vector2, action_pressed: bool, delta: float) -> void:
	apply_sailing(direction.x, action_pressed, delta)

func capture_state() -> Dictionary:
	return {"level": ship.sail_level, "angle": ship.sail_angle_degrees}

func restore_state(state: Dictionary) -> void:
	ship.set_sail_level(state.level)
	ship.set_sail_angle(state.angle)

func apply_sailing(trim_input: float, cycle: bool, delta: float) -> void:
	ship.set_sail_angle(ship.sail_angle_degrees + trim_input * trim_speed_degrees * delta)
	# One deliberate press per step; holding a key cannot skip a deployment state.
	if cycle:
		ship.set_sail_level((ship.sail_level + 1) % 4)

func _update_artwork() -> void:
	if sail_textures.size() == 4:
		artwork.texture = sail_textures[ship.sail_level]
	# Cloth extends right in the PNG. Rotate it toward the bow so its billow
	# matches the forward sail normal used by ShipMotion's wind calculation.
	artwork.rotation = deg_to_rad(-90.0 + ship.sail_angle_degrees)
