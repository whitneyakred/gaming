@tool
class_name FruitBush
extends Node2D

## A bush you can pick fruit from with E (used on Parrot Point).
## Set Fruit Id to any catalog item (scripts/item-system/items.gd); the bush
## colours itself to match. Bushes never run out.

const FRUIT_COLORS: Dictionary[StringName, Color] = {
	&"mango": Color8(245, 150, 40),
	&"banana": Color8(245, 220, 70),
	&"papaya": Color8(235, 95, 110),
}

@export var fruit_id: StringName = &"mango":
	set(value):
		fruit_id = value
		queue_redraw()


func get_fruit_color() -> Color:
	return FRUIT_COLORS.get(fruit_id, Color.WHITE)


func _draw() -> void:
	draw_circle(Vector2(0, 4), 26.0, Color(0, 0, 0, 0.2))
	draw_circle(Vector2(-12, -4), 18.0, Color8(48, 120, 56))
	draw_circle(Vector2(12, -4), 18.0, Color8(44, 110, 50))
	draw_circle(Vector2(0, -14), 20.0, Color8(58, 136, 62))
	var fruit := get_fruit_color()
	for spot in [Vector2(-12, -10), Vector2(8, -18), Vector2(13, -2), Vector2(-3, -1)]:
		draw_circle(spot, 5.0, fruit)
