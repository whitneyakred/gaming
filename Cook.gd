class_name ShipGrill
extends Node2D
## Teammate's galley activity with host-owned ingredient escrow and rewards.
signal changed
@export var interaction_distance := 52.0
var fish: Array[Dictionary] = [] # Recoverable stock from legacy furnace saves.
var fuel: Dictionary = {}
var burn_remaining := 0.0
var burn_capacity := 1.0
var cook_seconds := 8.0
var next_id := 1
var starter_granted := true
var active_id := 0
var token := 0
var started := 0

func _ready() -> void:
	for node_name in ["Prompt", "Progress", "ReadyIndicator"]: get_node(node_name).hide()
func seed_fuel() -> void:
	pass # The activity supplies preparation ingredients; only a caught fish is spent.
func near(service: InventoryService) -> bool:
	return service.can_handle_items() and not service.player.is_overboard and service.player.global_position.distance_to(global_position) <= interaction_distance
func cooking() -> bool: return active_id != 0
func _process(_delta: float) -> void:
	if NetworkSession.online and not multiplayer.is_server(): return
	if active_id == 0: return
	var service: InventoryService = NetworkSession.services.get(active_id) if NetworkSession.online else get_parent().get_node("InventorySystem")
	if service == null: release_for(active_id); return
	if not near(service) or not service.hud.grill_open: release_for(active_id)
func advance(_delta: float) -> void:
	pass
func capture() -> Dictionary:
	return {"fish": fish.duplicate(true), "fuel": fuel.duplicate(), "remaining": burn_remaining, "capacity": burn_capacity, "next_id": next_id, "starter": starter_granted, "active": active_id, "token": token}
func restore(data: Dictionary) -> void:
	fish.assign(data.get("fish", []))
	fuel = data.get("fuel", {}).duplicate()
	# Preparation is not resumed from a save; escrow is returned to stock.
	if not NetworkSession.online or multiplayer.is_server():
		if int(data.get("active", 0)) != 0: fish.append({"key": int(data.get("next_id", 1)), "point": Vector2.ZERO, "progress": 0.0})
		active_id = 0
	else: active_id = int(data.get("active", 0))
	token = int(data.get("token", 0))
	next_id = int(data.get("next_id", 1)) + (1 if active_id == 0 and int(data.get("active", 0)) != 0 else 0)
	changed.emit()
func release_for(id: int) -> void:
	if active_id != id: return
	active_id = 0 # Clear before refund so repeated cancellation cannot duplicate fish.
	var service: InventoryService = NetworkSession.services.get(id) if NetworkSession.online else get_parent().get_node("InventorySystem")
	if service != null: _give(service, &"fish_cod", 1)
	else: fish.append({"key": next_id, "point": Vector2.ZERO, "progress": 0.0}); next_id += 1
	changed.emit()
func handle(service: InventoryService, args: Dictionary) -> bool:
	if NetworkSession.online and not multiplayer.is_server(): return false
	if not args.get("action") is String: return false
	var id := service.network_id if NetworkSession.online else 1
	if args.action == "cancel":
		if active_id != id or not args.get("token") is int or args.token != token: return false
		release_for(id)
		return true
	if not near(service) or not service.hud.grill_open: return false
	if args.action == "recover":
		for entry in fish: _give(service, &"dried_fish" if float(entry.progress) >= cook_seconds else &"fish_cod", 1)
		fish.clear()
		if not fuel.is_empty(): _give(service, fuel.id, fuel.quantity)
		fuel.clear()
		return true
	if args.action == "start":
		if active_id != 0 or not args.get("revision") is int or args.revision != service.view_revision: return false
		if not args.get("index") is int or args.index < 0 or args.index >= service.inventory.slots.size(): return false
		var entry: Dictionary = service.inventory.slots[args.index]
		if entry.get("id") != &"fish_cod": return false
		active_id = id
		token += 1
		started = Time.get_ticks_msec()
		service.inventory.remove(args.index, 1)
	elif args.action == "finish":
		if active_id != id or not args.get("token") is int or args.token != token: return false
		if Time.get_ticks_msec() - started < 8000: return false
		active_id = 0
		_give(service, &"dried_fish", 1)
		service.hud.close()
		service.feedback.emit("Fish kabob ready!")
	else: return false
	changed.emit()
	return true
func _give(service: InventoryService, item: StringName, quantity: int) -> void:
	var added := service.inventory.add_items(ItemDatabase.get_item(item), quantity)
	if added < quantity: service._spawn_drop({"id": item, "quantity": quantity - added}, service.player.position)
