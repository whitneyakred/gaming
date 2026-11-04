class_name SwimAccess
extends Node2D
## Plank exit, ladder return, and shore arrival for the solo sailing map.
static var returning_by_swimming: bool = false
static var shore_return: Vector2 = Vector2.ZERO

@export var plank_end: Vector2 = Vector2(-116, -42)
@export var water_entry: Vector2 = Vector2(-145, -42)
@export var ladder_water: Vector2 = Vector2(-92, 12)
@export var ladder_top: Vector2 = Vector2(-45, -15)
@export var shore_distance: float = 18.0
var _arrival_cooldown: float = 0.0
var _transitioning: bool = false
var _return_island: WorldIsland
@onready var ship: Ship = get_parent()

func _physics_process(delta: float) -> void:
	if _transitioning or ship._state == Ship.State.ROWING:
		return
	_arrival_cooldown = maxf(0.0, _arrival_cooldown - delta)
	var crew := ship.player
	if not crew.is_overboard:
		if not crew.using_station and crew.position.distance_to(plank_end) < 14:
			crew.set_overboard(true)
			crew.global_position = ship.to_global(water_entry)
		return
	if crew.global_position.distance_to(ship.to_global(ladder_water)) < 20:
		crew.set_overboard(false)
		crew.position = ladder_top
		return
	if _arrival_cooldown > 0:
		return
	for island in ship.get_islands():
		var distance := crew.global_position.distance_to(island.get_nearest_coast_point(crew.global_position))
		if island == _return_island:
			if distance > shore_distance + 40:
				_return_island = null
			continue
		if distance <= shore_distance:
			_arrive(island)
			return

func _arrive(island: WorldIsland) -> void:
	_transitioning = true
	shore_return = ship.player.global_position
	returning_by_swimming = true
	Ship.anchored_position = ship.global_position
	Ship.anchored_rotation = ship.global_rotation
	Ship.visited_island_name = island.name
	ship._stop_sailing()
	get_tree().change_scene_to_file.call_deferred(island.scene)

func restore_swimmer() -> void:
	returning_by_swimming = false
	ship.global_position = Ship.anchored_position
	ship.global_rotation = Ship.anchored_rotation
	ship.anchor_deployed = true
	ship.player.set_overboard(true)
	ship.player.global_position = shore_return
	# Require swimming away from shore before another visit can start.
	_arrival_cooldown = 3.0
	_return_island = ship.get_island(Ship.visited_island_name)
	ship._view.view_offset = shore_return - ship.global_position
