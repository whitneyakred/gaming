class_name FoliageVisual
extends Node2D
var forest: IslandFoliage
var entry: Dictionary
func _draw() -> void:
	if not entry.is_empty(): forest.paint(self,entry)
