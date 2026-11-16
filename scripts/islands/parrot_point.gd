class_name ParrotPoint
extends IslandGame

## Parrot Point: fill the parrot's fruit orders.
## The parrot squawks an order ("2 Mango, 1 Banana"). Press E at a bush to
## pick one fruit into your bag, then press E at the parrot to hand over what
## it asked for. Handing over when you have none of the fruit it wants costs
## time. Fill every order and the parrot shows you a freshwater spring
## (Fresh Water into your bag). Spare fruit stays in your bag.
##
## Scene setup: FruitBush children of Bushes, and the Parrot marker.

@export_group("Orders")
@export var bushes_path: NodePath = ^"World/Bushes"
@export var parrot_path: NodePath = ^"World/Parrot"
@export var orders_needed: int = 5
## Most fruit in one order.
@export var max_order_size: int = 3
@export var reach: float = 48.0
@export var wrong_penalty_seconds: float = 4.0
@export var reward_item_id: StringName = &"fresh_water"
@export var reward_amount: int = 2

var orders_done: int = 0
## fruit id -> how many the parrot still wants for the current order.
var order: Dictionary[StringName, int] = {}

var _bushes: Array[FruitBush] = []
var _parrot: Node2D
var _speech: Label
var _time: float = 0.0
var _squawk: float = 0.0


func _setup_game() -> void:
	var bushes := get_node_or_null(bushes_path)
	assert(bushes != null, "ParrotPoint needs FruitBush children under Bushes.")
	for child in bushes.get_children():
		if child is FruitBush:
			_bushes.append(child)
	_parrot = get_node_or_null(parrot_path) as Node2D
	assert(_parrot != null, "ParrotPoint needs a Parrot marker.")
	_parrot.draw.connect(_draw_parrot)
	_speech = Label.new()
	_speech.name = "Speech"
	_speech.position = Vector2(-110, -120)
	_speech.size = Vector2(220, 40)
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech.add_theme_color_override("font_color", Color8(40, 30, 20))
	_speech.add_theme_font_size_override("font_size", 16)
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color(1, 1, 1, 0.9)
	bubble.set_corner_radius_all(8)
	bubble.set_content_margin_all(4)
	_speech.add_theme_stylebox_override("normal", bubble)
	_parrot.add_child(_speech)
	_new_order()


func _game_process(delta: float) -> void:
	_time += delta
	_squawk = maxf(_squawk - delta, 0.0)
	_parrot.queue_redraw()
	if orders_done >= orders_needed:
		set_prompt("")
		return
	if _near(_parrot):
		set_prompt("Press E to hand the parrot its fruit")
	else:
		var bush := _nearest_bush()
		set_prompt("Press E to pick a %s" % _fruit_name(bush.fruit_id) if bush else "")


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or orders_done >= orders_needed:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _near(_parrot):
		_deliver()
		return
	var bush := _nearest_bush()
	if bush:
		give_item(bush.fruit_id, 1)
		refresh_hud()


func _deliver() -> void:
	var inventory := get_inventory()
	var handed := 0
	for fruit in order.keys():
		var wanted: int = order[fruit]
		var have := inventory.get_quantity(fruit) if inventory else 0
		var give := mini(wanted, have)
		if give > 0 and inventory.remove_item(fruit, give):
			order[fruit] = wanted - give
			handed += give
	if handed == 0:
		add_time(-wrong_penalty_seconds)
		_squawk = 0.6
		show_message("SQUAWK! That's not what I asked for! (-%ds)" % int(wrong_penalty_seconds), 1.4)
		return
	_squawk = 0.4
	if _remaining() == 0:
		orders_done += 1
		if orders_done >= orders_needed:
			_speech.text = "Squawk! Follow me!"
			refresh_hud()
			give_item(reward_item_id, reward_amount)
			show_message("The parrot leads you to a freshwater spring!", 2.0)
			return
		show_message("Order filled! (%d / %d)" % [orders_done, orders_needed], 1.0)
		_new_order()
	else:
		_update_speech()
		refresh_hud()


func _new_order() -> void:
	order.clear()
	var fruits: Array[StringName] = []
	for bush in _bushes:
		if not fruits.has(bush.fruit_id):
			fruits.append(bush.fruit_id)
	var size := randi_range(1, max_order_size)
	for i in size:
		var fruit: StringName = fruits.pick_random()
		order[fruit] = order.get(fruit, 0) + 1
	_update_speech()
	refresh_hud()


func _remaining() -> int:
	var total := 0
	for fruit in order:
		total += order[fruit]
	return total


func _order_text() -> String:
	var parts: PackedStringArray = []
	for fruit in order:
		if order[fruit] > 0:
			parts.append("%d %s" % [order[fruit], _fruit_name(fruit)])
	return ", ".join(parts)


func _update_speech() -> void:
	_speech.text = "Squawk! " + _order_text()


func _fruit_name(fruit: StringName) -> String:
	var item: ItemData = ItemDatabase.get_item(fruit)
	return item.display_name if item else String(fruit).capitalize()


func _near(node: Node2D) -> bool:
	return player != null and node != null and player.global_position.distance_to(node.global_position) <= reach


func _nearest_bush() -> FruitBush:
	var best: FruitBush = null
	var best_distance := reach
	for bush in _bushes:
		var distance := player.global_position.distance_to(bush.global_position)
		if distance <= best_distance:
			best = bush
			best_distance = distance
	return best


func _get_objective_text() -> String:
	if orders_done >= orders_needed:
		return "All orders filled! Head to the rowboat."
	return "Order %d / %d: bring %s" % [orders_done + 1, orders_needed, _order_text()]


func _is_objective_complete() -> bool:
	return orders_done >= orders_needed


func _get_incomplete_message() -> String:
	return "The parrot still wants its fruit!"


func _draw_parrot() -> void:
	# Perch.
	_parrot.draw_rect(Rect2(-4, -30, 8, 34), Color8(110, 75, 45))
	_parrot.draw_rect(Rect2(-22, -34, 44, 6), Color8(110, 75, 45))
	var bob := sin(_time * 3.0) * 2.0 - (6.0 if _squawk > 0.0 else 0.0)
	var body := Vector2(0, -52 + bob)
	_parrot.draw_circle(body, 13.0, Color8(220, 40, 40))
	_parrot.draw_rect(Rect2(body + Vector2(-6, 6), Vector2(12, 18)), Color8(40, 110, 220))
	_parrot.draw_circle(body + Vector2(0, -14), 9.0, Color8(230, 50, 45))
	_parrot.draw_circle(body + Vector2(3, -16), 2.5, Color.WHITE)
	_parrot.draw_circle(body + Vector2(3.5, -16), 1.2, Color.BLACK)
	var beak_open := 4.0 if _squawk > 0.0 else 0.0
	_parrot.draw_colored_polygon(PackedVector2Array([
		body + Vector2(7, -16), body + Vector2(16, -12 + beak_open * 0.5), body + Vector2(7, -9 + beak_open),
	]), Color8(250, 200, 60))
