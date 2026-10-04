class_name SailStation
extends ShipStation
## Four deployment states. Simple pixel cloth matches the main ship's palette.

@export_range(1.0, 90.0) var trim_speed_degrees: float = 34.0
@export var sail_textures: Array[Texture2D] = []
@onready var artwork: Sprite2D = $SailArtwork

func _ready() -> void:
	ship.sail_changed.connect(_update_artwork)
	_update_artwork()

func _apply_controls(delta: float) -> void:
	var trim_input := Input.get_axis("move_left", "move_right")
	ship.set_sail_angle(ship.sail_angle_degrees + trim_input * trim_speed_degrees * delta)
	# One deliberate press per step; holding a key cannot skip a deployment state.
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		ship.set_sail_level((ship.sail_level + 1) % 4)

func _update_artwork() -> void:
	artwork.visible = sail_textures.size() == 4
	if sail_textures.size() == 4:
		artwork.texture = sail_textures[ship.sail_level]
	# Cloth extends right in the PNG. Rotate it toward the bow so its billow
	# matches the forward sail normal used by ShipMotion's wind calculation.
	artwork.rotation = deg_to_rad(-90.0 + ship.sail_angle_degrees)
	queue_redraw()

func _draw() -> void:
	if sail_textures.size() == 4 or not is_instance_valid(ship):
		return
	draw_set_transform(Vector2.ZERO, deg_to_rad(ship.sail_angle_degrees))
	var cloth_height := 6.0 + float(ship.sail_level) * 12.0
	var cloth := Rect2(-52, -cloth_height, 104, cloth_height)
	draw_rect(cloth.grow(2), Color("594737"))
	draw_rect(cloth, Color("d8c5a0"))
	for seam in range(-40, 50, 16):
		draw_line(Vector2(seam, -cloth_height), Vector2(seam, 0), Color("ac9272"), 2)
	draw_rect(Rect2(-58, 0, 116, 6), Color("594737"))
	draw_rect(Rect2(-56, 0, 112, 2), Color("ac9272"))
	draw_rect(Rect2(-4, -4, 8, 12), Color("594737"))
