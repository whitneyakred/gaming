extends Node
## One in-memory owner across ship/island scenes. No disk save or networking.
signal changed
signal died
signal notice(message: String)

@export_group("Needs")
@export_range(1.0, 1000.0) var maximum_hunger: float = 100.0
@export_range(1.0, 1000.0) var maximum_health: float = 100.0
@export_range(0.0, 10.0) var walking_cost_per_second: float = 0.3
@export_range(0.0, 10.0) var station_cost_per_second: float = 0.16
@export_range(0.0, 10.0) var sailing_cost_per_second: float = 0.06
@export_range(0.0, 100.0) var starvation_damage_per_second: float = 2.0
@export_group("Fatigue")
@export_range(0.01, 1.0) var hunger_threshold: float = 0.4
@export_range(0.01, 1.0) var health_threshold: float = 0.1
@export_range(0.0, 20.0) var wobble_pixels: float = 5.0
@export_group("Supplies")
@export_range(0, 20) var starter_fish: int = 2
@export_range(0, 20) var starter_potatoes: int = 3
@export_range(1, 20) var meal_capacity: int = 8

var hunger: float = 100.0
var health: float = 100.0
var dead: bool = false
var inventory: PlayerInventory
var meals: Array[Dictionary] = []
var ready_meal: Dictionary = {}
var gathered_pickups: Dictionary = {}
var discovered_recipes: Dictionary = {}
var reduced_motion: bool = false
var hunger_warning: bool = false
var fatigue: float = 0.0
var visual_offset := Vector2.ZERO
var visual_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory = _new_inventory()
	hunger = maximum_hunger
	health = maximum_health
	var hud := CanvasLayer.new()
	hud.set_script(preload("res://scripts/survival/survival_hud.gd"))
	add_child(hud)

func _new_inventory() -> PlayerInventory:
	var stock := PlayerInventory.new()
	for id: StringName in [&"fishing_rod", &"fish_cod", &"potato"]:
		var count: int = 1 if id == &"fishing_rod" else (starter_fish if id == &"fish_cod" else starter_potatoes)
		for _i in range(count):
			stock.add_item(ItemDatabase.get_item(id))
	return stock

func _process(delta: float) -> void:
	# Presentation deliberately runs even while gameplay is paused.
	visual_time += delta
	visual_offset = Vector2(sin(visual_time * 1.7), sin(visual_time * 2.1)) * fatigue * wobble_pixels
	if reduced_motion:
		visual_offset = Vector2.ZERO
	var camera := get_viewport().get_camera_2d()
	if camera:
		camera.offset = visual_offset
	if get_tree().paused or dead:
		return
	advance(delta)

func advance(delta: float) -> void:
	if dead or get_tree().paused or delta <= 0:
		return
	if hunger <= 0:
		health = maxf(0.0, health - starvation_damage_per_second * delta)
		_commit()

func spend_hunger(amount: float) -> void:
	if dead or get_tree().paused or amount <= 0:
		return
	hunger = maxf(0.0, hunger - amount)
	_commit()

func _commit() -> void:
	hunger = clampf(hunger, 0.0, maximum_hunger)
	health = clampf(health, 0.0, maximum_health)
	var ratio := hunger / maxf(maximum_hunger, 0.001)
	if ratio < hunger_threshold:
		hunger_warning = true
	elif ratio > hunger_threshold:
		hunger_warning = false
	var hunger_severity := 0.0
	if hunger_warning:
		hunger_severity = 0.15 + 0.85 * clampf((hunger_threshold - ratio) / hunger_threshold, 0, 1)
	var health_ratio := health / maxf(maximum_health, 0.001)
	var health_severity := 0.0
	if health_ratio <= health_threshold:
		health_severity = 0.3 + 0.7 * clampf(1.0 - health_ratio / health_threshold, 0, 1)
	fatigue = maxf(hunger_severity, health_severity)
	if health <= 0 and not dead:
		dead = true
		died.emit()
		get_tree().paused = true
	changed.emit()

func take_meal() -> bool:
	if dead or get_tree().paused or ready_meal.is_empty() or meals.size() >= meal_capacity:
		return false
	meals.append(ready_meal.duplicate(true))
	ready_meal.clear()
	changed.emit()
	return true

func eat(index: int) -> bool:
	var crew := get_tree().get_first_node_in_group("crew")
	if crew and crew.get("using_station"):
		return false
	if dead or get_tree().paused or index < 0 or index >= meals.size():
		return false
	var meal := meals[index]
	var poison := float(meal.get("poison", 0.0))
	if poison <= 0 and (hunger >= maximum_hunger or float(meal.get("hunger", 0)) <= 0) and (health >= maximum_health or float(meal.get("healing", 0)) <= 0):
		notice.emit("Already full and healthy — meal kept.")
		return false
	meals.remove_at(index)
	if poison > 0:
		health -= maximum_health * poison
		notice.emit("Poisonous meal! Lost %d health." % roundi(maximum_health * poison))
	else:
		hunger += float(meal.get("hunger", 0.0))
		health += float(meal.get("healing", 0.0))
		notice.emit("Ate " + str(meal.name))
	_commit()
	return true

func restart() -> void:
	get_tree().paused = false
	dead = false
	hunger = maximum_hunger
	health = maximum_health
	hunger_warning = false
	fatigue = 0
	visual_offset = Vector2.ZERO
	inventory = _new_inventory()
	meals.clear()
	ready_meal.clear()
	gathered_pickups.clear()
	discovered_recipes.clear()
	Ship.returning_from_island = false
	Ship.visited_island_name = &""
	Ship.completed_islands.clear()
	changed.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func eat_coconut() -> bool:
	var crew := get_tree().get_first_node_in_group("crew")
	if dead or get_tree().paused or (crew and crew.get("using_station")):
		return false
	if hunger >= maximum_hunger and health >= maximum_health:
		notice.emit("Already full and healthy — coconut kept.")
		return false
	if not inventory.remove_item(&"coconut"):
		return false
	hunger += 16.0
	health += 5.0
	notice.emit("Ate coconut: +16 hunger, +5 health.")
	_commit()
	return true

func discard_rope() -> void:
	var crew := get_tree().get_first_node_in_group("crew")
	if dead or get_tree().paused or (crew and crew.get("using_station")):
		return
	if inventory.remove_item(&"rope"):
		notice.emit("Discarded one rope to free pack space.")
		changed.emit()
