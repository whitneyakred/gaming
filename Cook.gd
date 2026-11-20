class_name ShipGrill
extends Node2D
## One authoritative grill, shared by every sailor. Idle fuel never burns.
signal changed
@export_range(1, 60, 0.5) var cook_seconds: float = 8.0
@export var wood_seconds: float = 12.0
@export var coal_seconds: float = 36.0
@export var max_fish: int = 8
@export var interaction_distance: float = 52.0
var fish: Array[Dictionary] = []
var fuel: Dictionary = {}
var burn_remaining: float = 0.0
var burn_capacity: float = 1.0
var next_id: int = 1
var starter_granted: bool = false

func _ready() -> void:
	for node_name in ["Prompt", "Progress", "ReadyIndicator"]:
		get_node(node_name).hide()
	if not NetworkSession.online:
		seed_fuel.call_deferred()

func seed_fuel() -> void:
	if starter_granted:
		return
	starter_granted = true
	var storage := VoyageState.get_ship_storage()
	for entry in [{"id": &"wood", "quantity": 6}, {"id": &"coal", "quantity": 4}]:
		var added := storage.add_items(ItemDatabase.get_item(entry.id), entry.quantity)
		if added < int(entry.quantity):
			var service := get_parent().get_node_or_null("InventorySystem") as InventoryService
			if service != null:
				service._spawn_drop({"id": entry.id, "quantity": int(entry.quantity) - added}, position + Vector2(-25, 12))

func near(service: InventoryService) -> bool:
	return service.can_handle_items() and not service.player.is_overboard and service.player.global_position.distance_to(global_position) <= interaction_distance

func cooking() -> bool:
	return has_raw() and (burn_remaining > 0 or not fuel.is_empty())

func has_raw() -> bool:
	for entry in fish:
		if float(entry.progress) < cook_seconds:
			return true
	return false

func _process(delta: float) -> void:
	if not NetworkSession.online or multiplayer.is_server():
		advance(delta)

func advance(delta: float) -> void:
	# Spend only the portion of this frame needed by unfinished fish.
	while delta > 0.00001 and has_raw():
		if burn_remaining <= 0:
			if fuel.is_empty():
				break
			burn_capacity = coal_seconds if fuel.id == &"coal" else wood_seconds
			burn_remaining = burn_capacity
			fuel.quantity -= 1
			if fuel.quantity <= 0:
				fuel = {}
		var remaining := 0.0
		for entry in fish:
			remaining = maxf(remaining, cook_seconds - float(entry.progress))
		var step := minf(delta, minf(burn_remaining, remaining))
		for entry in fish:
			entry.progress = minf(cook_seconds, float(entry.progress) + step)
		burn_remaining = maxf(0, burn_remaining - step)
		delta -= step
		changed.emit()

func capture() -> Dictionary:
	return {"fish": fish.duplicate(true), "fuel": fuel.duplicate(), "remaining": burn_remaining, "capacity": burn_capacity, "next_id": next_id, "starter": starter_granted}

func restore(data: Dictionary) -> void:
	if fish == data.get("fish", []) and fuel == data.get("fuel", {}) and burn_remaining == data.get("remaining", 0.0) and burn_capacity == data.get("capacity", 1.0) and next_id == data.get("next_id", 1) and starter_granted == data.get("starter", false): return
	fish.assign(data.get("fish", []))
	fuel = data.get("fuel", {}).duplicate()
	burn_remaining = data.get("remaining", 0.0)
	burn_capacity = data.get("capacity", 1.0)
	next_id = data.get("next_id", 1)
	starter_granted = data.get("starter", false)
	changed.emit()

func handle(service: InventoryService, args: Dictionary) -> bool:
	if not near(service) or not service.hud.grill_open:
		return false
	var action: String = args.get("action", "")
	if action == "collect":
		for index in fish.size():
			if fish[index].key == int(args.get("key", -1)):
				var item: StringName = &"dried_fish" if fish[index].progress >= cook_seconds else &"fish_cod"
				fish.remove_at(index) # Remove before granting: repeated commands cannot duplicate meals.
				_give(service, item, 1)
				changed.emit()
				return true
		return false
	if action == "withdraw":
		if fuel.is_empty():
			return false
		var old := fuel.duplicate()
		fuel = {}
		_give(service, old.id, old.quantity)
		changed.emit()
		return true
	if int(args.get("revision", -1)) != service.view_revision:
		service.feedback.emit("Items changed. Try again.")
		return false
	var index: int = args.get("index", -1)
	if index < 0 or index >= service.inventory.slots.size():
		return false
	var entry: Dictionary = service.inventory.slots[index]
	if entry.is_empty():
		return false
	if action == "fuel" and entry.id in [&"wood", &"coal"]:
		if not fuel.is_empty() and fuel.id != entry.id:
			service.feedback.emit("Remove the remaining fuel before changing fuel type.")
			return false
		var quantity := mini(int(entry.quantity), 30 - int(fuel.get("quantity", 0)))
		if quantity <= 0:
			return false
		fuel = {"id": entry.id, "quantity": int(fuel.get("quantity", 0)) + quantity}
		service.inventory.remove(index, quantity)
	elif action == "fish" and entry.id == &"fish_cod":
		if fish.size() >= max_fish:
			service.feedback.emit("The grill is full. Collect a fish first.")
			return false
		var point: Variant = args.get("point", Vector2(0.5, 0.5))
		if not point is Vector2 or not point.is_finite():
			return false
		point = point.clamp(Vector2.ZERO, Vector2.ONE)
		fish.append({"key": next_id, "point": point, "progress": 0.0})
		next_id += 1
		service.inventory.remove(index, 1)
	else:
		return false
	changed.emit()
	return true

func _give(service: InventoryService, item: StringName, quantity: int) -> void:
	var added := service.inventory.add_items(ItemDatabase.get_item(item), quantity)
	if added < quantity:
		service._spawn_drop({"id": item, "quantity": quantity - added}, service.player.position)
		service.feedback.emit("Inventory full — placed beside you.")
