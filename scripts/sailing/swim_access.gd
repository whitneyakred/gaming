class_name SwimAccess
extends Node2D
## Continuous deck / sea / island travel. No island scene changes.
static var returning_by_swimming: bool = false
static var shore_return: Vector2 = Vector2.ZERO
@export var plank_end: Vector2 = Vector2(-116, -42)
@export var water_entry: Vector2 = Vector2(-145, -42)
@export var ladder_water: Vector2 = Vector2(-92, 12)
@export var ladder_top: Vector2 = Vector2(-45, -15)
@onready var ship: Ship = get_parent()

func _physics_process(_delta: float) -> void:
	if not NetworkSession.online:
		update_crew(ship.player)

func update_crew(crew: CharacterBody2D) -> void:
	if crew.health <= 0: return
	if not crew.is_overboard:
		if not crew.using_station and crew.position.distance_to(plank_end) < 14:
			crew.set_overboard(true)
			crew.global_position = ship.to_global(water_entry)
		return
	if crew.global_position.distance_to(ship.to_global(ladder_water)) < 20:
		crew.set_overboard(false)
		crew.update_land(false)
		crew.position = ladder_top
		return
	var land := false
	for island in ship.get_islands():
		if Geometry2D.is_point_in_polygon(crew.global_position, island.get_coast()):
			land = true
			break
	crew.update_land(land)

func restore_swimmer() -> void:
	returning_by_swimming = false
	ship.player.set_overboard(true)
	ship.player.global_position = shore_return
