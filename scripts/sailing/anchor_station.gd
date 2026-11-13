class_name AnchorStation
extends ShipStation
## A one-press station: toggle the anchor, then immediately return crew control.

@export var water_offset: Vector2 = Vector2(-60, 25)
@onready var artwork: Sprite2D = $AnchorArtwork
@onready var prompt: Label = $Prompt

func _ready() -> void:
	if is_instance_valid(ship):
		ship.anchor_changed.connect(_update_artwork)
	_update_artwork(false)

func try_take_control(crew: CharacterBody2D) -> bool:
	if not super.try_take_control(crew):
		return false
	ship.anchor_deployed = not ship.anchor_deployed
	release_control()
	return true

func _process(_delta: float) -> void:
	prompt.visible = false

func _update_artwork(_deployed: bool) -> void:
	artwork.visible = not is_instance_valid(ship) or not ship.anchor_deployed
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(ship) or not ship.anchor_deployed:
		return
	var ring := water_offset + Vector2(0, -13)
	var rope := PackedVector2Array([Vector2(0, -13), Vector2(-26, -12), ring * 0.65 + Vector2(0, 6), ring])
	draw_polyline(rope, Color("4c2d17"), 4.0, true)
	draw_polyline(rope, Color("d4a55b"), 2.0, true)
	draw_circle(Vector2(0, -13), 4.0, Color("d4a55b"))
