class_name UprightVisual
extends Node2D
## Attach to artwork only: its parent keeps the gameplay position and rotation.
## Runs after ship interpolation/camera updates on each local client.
var anchor_offset: Vector2

func _ready() -> void:
	anchor_offset = position
	process_priority = 100
	_process(0.0)

func _process(_delta: float) -> void:
	var anchor := get_parent() as Node2D
	if anchor == null:
		return
	var angle := -get_canvas_transform().get_rotation()
	global_rotation = angle
	global_position = anchor.global_position + anchor_offset.rotated(angle)

static func draw_rotation(artwork: Node2D) -> float:
	return -artwork.get_canvas_transform().get_rotation() - artwork.global_rotation
