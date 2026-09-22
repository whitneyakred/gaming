class_name AnchorStation
extends ShipStation
## One-shot interaction, validated by the host through the normal station path.

@export var water_offset: Vector2 = Vector2(-85, 25)
@onready var artwork: Sprite2D = $AnchorArtwork

func _ready() -> void:
	_update_artwork()

func try_take_control(crew: CharacterBody2D) -> bool:
	if not super.try_take_control(crew):
		return false
	ship.anchor_deployed = not ship.anchor_deployed
	_update_artwork()
	release_control()
	return true

func capture_state() -> Dictionary:
	return {"deployed": ship.anchor_deployed}

func restore_state(state: Dictionary) -> void:
	ship.anchor_deployed = bool(state.get("deployed", false))
	_update_artwork()

func _update_artwork() -> void:
	artwork.visible = not ship.anchor_deployed
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(ship) or not ship.anchor_deployed:
		return
	# The anchor is submerged; only its rope remains visible over the side.
	var ring := water_offset + Vector2(0, -13)
	var rope := PackedVector2Array([Vector2(0, -13), Vector2(-26, -12), ring * 0.65 + Vector2(0, 6), ring])
	draw_polyline(rope, Color("4c2d17"), 4.0, true)
	draw_polyline(rope, Color("d4a55b"), 2.0, true)
	# A small attachment point keeps the interaction location visible on deck.
	draw_circle(Vector2(0, -13), 4.0, Color("d4a55b"))
