class_name WorldIsland
extends Node2D

## An island placed on the sailing map (child of Ship/Islands in ship.tscn).
## Sail into the yellow circle at its dock point to anchor, then take the
## rowboat over to play its scene. Move the node in the 2D view to place the
## island anywhere on the map.

@export var display_name: String = "Island"
@export_file("*.tscn") var scene: String = ""
## Where the ship's center anchors, relative to this island. The default
## lines the ship's rowboat route up with the island's dock.
@export var dock_offset: Vector2 = Vector2(-400, 40)


func get_dock_position() -> Vector2:
	return to_global(dock_offset)
