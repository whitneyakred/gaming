extends SceneTree
## Run with Godot --headless --path . --script res://tests/survival_integration.gd
var failures: int = 0
var survival: Node

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _set_needs(hunger: float, health: float) -> void:
	survival.hunger = hunger
	survival.health = health
	survival._commit()

func _run() -> void:
	survival = root.get_node("VoyageSurvival")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var ship := current_scene.get_node("Ship") as Ship
	var player: CharacterBody2D = ship.player
	var cook: Node = ship.get_node("Cooking")
	ship.set_physics_process(false)
	player.set_physics_process(false)
	_set_needs(39, 100)
	var initial_fatigue: float = survival.fatigue
	_set_needs(20, 100)
	_check(survival.fatigue > initial_fatigue, "Lower hunger must increase tiredness")
	_set_needs(40, 100)
	_check(survival.hunger_warning, "Exactly 40 retains the prior low warning")
	_set_needs(41, 100)
	_check(not survival.hunger_warning and survival.fatigue == 0, "Above 40 clears hunger fatigue")
	_set_needs(100, 10)
	_check(survival.fatigue > 0, "Health at 10% causes fatigue independently")
	_set_needs(0, 100)
	survival.advance(2)
	_check(is_equal_approx(survival.health, 96), "Zero hunger starts starvation damage")
	_set_needs(1, 96)
	survival.advance(2)
	_check(is_equal_approx(survival.health, 96), "Positive hunger stops starvation damage")
	# Pause must freeze gameplay while presentation continues.
	_set_needs(0, 80)
	paused = true
	var before: Vector2 = survival.visual_offset
	survival._process(0.4)
	_check(survival.health == 80 and survival.visual_offset != before, "Pause animates wobble but applies no starvation damage")
	paused = false
	_set_needs(100, 10)
	survival.meals.append(FoodRecipes.prepare(FoodRecipes.resolve(1, 0), 3))
	_check(survival.eat(0) and survival.health == 22, "Full hunger must not prevent meal healing")
	var poison := FoodRecipes.prepare(FoodRecipes.resolve(2, 1), 3)
	_check(poison.poison >= 0.3 and poison.stars == 3, "Three-star incompatible recipes remain poisonous")
	_set_needs(70, 100)
	survival.meals.append(poison)
	_check(survival.eat(0) and survival.health == 60, "Poison must damage maximum health instead of healing")
	_check(not survival.eat(0), "Repeated eat cannot apply the same serving twice")
	_check(FoodRecipes.prepare(FoodRecipes.resolve(1, 0), 0).poison >= 0.3, "Failed preparation makes a compatible dish poisonous")
	# Use the real station, activity, inventory and ready/collect boundaries.
	player.set_physics_process(true)
	player.position = cook.position + Vector2(-20, 0)
	await physics_frame
	cook._on_body_entered(player)
	var fish_before: int = survival.inventory.get_quantity(&"fish_cod")
	cook.interact()
	cook._select(true)
	cook._start_preparation()
	await process_frame
	var activity: Control = get_first_node_in_group("cooking_activity")
	_check(activity != null and not activity.use_potato and activity.stage == activity.Stage.FISH, "Fish-only recipe omits potato and needs no water")
	activity._advance()
	activity._advance()
	_check(activity.stage == activity.Stage.HEAT, "Recipe advances from fish transfer straight to heat")
	activity.time_left = 5
	paused = true
	await process_frame
	_check(activity.time_left == 5, "Pause freezes recipe countdown")
	paused = false
	cook._cancel()
	await process_frame
	_check(survival.inventory.get_quantity(&"fish_cod") == fish_before and not player.using_station, "Cancelling frees control without losing ingredients")
	cook.interact()
	cook._select(true)
	cook._start_preparation()
	cook._on_preparation_completed(3)
	cook._on_preparation_completed(3)
	_check(survival.inventory.get_quantity(&"fish_cod") == fish_before - 1, "Duplicate completion spends only one batch")
	_check(not survival.ready_meal.is_empty(), "Completed meal stays ready until collected")
	for _i in range(survival.meal_capacity):
		survival.meals.append(FoodRecipes.prepare(FoodRecipes.resolve(1, 0), 3))
	cook.interact()
	_check(not survival.ready_meal.is_empty() and survival.meals.size() == survival.meal_capacity, "Full meal tray must preserve ready output without duplication")
	survival.meals.clear()
	cook.interact()
	var servings: int = survival.meals.size()
	_check(servings == 1 and survival.ready_meal.is_empty(), "Collection grants one owned serving")
	_check(not survival.take_meal(), "Repeated collect cannot duplicate food")
	# Actual island pickup and scene round trip retain supplies and needs.
	var inventory: PlayerInventory = survival.inventory
	_set_needs(65, 75)
	change_scene_to_file("res://scenes/island.tscn")
	await scene_changed
	var pickups := get_nodes_in_group("coconuts")
	_check(not pickups.is_empty(), "Island has food pickups")
	var coconut: Node = pickups[0]
	var island_player: CharacterBody2D = current_scene.player
	var count: int = inventory.get_quantity(&"coconut")
	coconut._on_body_entered(island_player)
	coconut._on_body_entered(island_player)
	_check(inventory.get_quantity(&"coconut") == count + 1, "One island pickup grants real food once")
	change_scene_to_file("res://scenes/ship.tscn")
	await scene_changed
	_check(current_scene.player.player_inventory == inventory, "Inventory owner survives island return")
	_check(survival.hunger <= 65 and survival.health == 75, "Island return does not refill needs")
	# Death must cancel active cooking and reject later callbacks.
	player = current_scene.player
	cook = current_scene.get_node("Cooking")
	player.position = cook.position
	cook._on_body_entered(player)
	cook.interact()
	cook._select(false)
	cook._start_preparation()
	_set_needs(0, 1)
	survival.advance(1)
	_check(survival.dead and paused and not player.using_station, "Death during cooking ends gameplay and releases the station")
	cook._on_preparation_completed(3)
	_check(survival.ready_meal.is_empty() and not survival.eat(0), "Late completion and eating cannot revive a dead character")
	_check(survival.health == 0, "Death clamps health to zero")
	survival.restart()
	await scene_changed
	_check(not paused and not survival.dead and survival.hunger == 100 and survival.health == 100, "New voyage resets terminal state and needs")
	_check(survival.meals.is_empty() and survival.gathered_pickups.is_empty(), "New voyage clears meals and island pickup history")
	_check(survival.inventory.get_quantity(&"fish_cod") == 2 and survival.inventory.get_quantity(&"potato") == 3, "New voyage restores only its starter supplies")
	print("Survival integration: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
