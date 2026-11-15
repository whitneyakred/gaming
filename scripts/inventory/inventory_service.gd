class_name InventoryService
extends Node2D
## Single-player adaptation of inventory-system's chest, drag and pickup service.
signal updated
signal feedback(message: String)
@export var player_path: NodePath = ^"../Player"
@export var chest_enabled: bool = true
@export var storage_slots: int = 18
@export var storage_position := Vector2(45, -45)
@export var interaction_distance: float = 38.0
@export var pickup_distance: float = 24.0
var network_id: int = 1
var player: CharacterBody2D
var inventory: PlayerInventory
var storage: ShipInventory
var drops: Dictionary = {}
var pickup_inside: Dictionary = {}
var next_drop_id: int = 1
var view_revision: int = 0
var local_slots: Array[Dictionary] = []
var storage_view: Array[Dictionary] = []
var scene_key: String
var hud: CanvasLayer

func _ready() -> void:
	player = get_node(player_path) as CharacterBody2D
	inventory = player.get("player_inventory") as PlayerInventory
	storage = VoyageState.get_ship_storage(storage_slots)
	scene_key = "ship" if chest_enabled else get_parent().scene_file_path
	drops = VoyageState.floor_items.get(scene_key, {})
	VoyageState.floor_items[scene_key] = drops
	for id: int in drops:
		next_drop_id = maxi(next_drop_id, id + 1)
		pickup_inside[id] = player.position.distance_to(drops[id].position) <= pickup_distance
	inventory.inventory_changed.connect(publish)
	storage.inventory_changed.connect(publish)
	hud = get_node("InventoryHUD")
	publish()
	hud.bind_service(self)

func _exit_tree() -> void:
	if inventory != null and inventory.inventory_changed.is_connected(publish):
		inventory.inventory_changed.disconnect(publish)
	if storage != null and storage.inventory_changed.is_connected(publish):
		storage.inventory_changed.disconnect(publish)

func can_handle_items() -> bool:
	if not is_instance_valid(player) or not player.is_physics_processing() or player.using_station or (player.is_overboard and not player.on_land):
		return false
	if NetworkSession.online:
		if network_id == NetworkSession.local_id and (MapState.map_open or PauseMenu.is_paused()):
			return false
		return not NetworkSession.inputs.get(network_id, {}).get("blocked", false)
	return not MapState.map_open and not get_tree().paused

func near_storage() -> bool:
	return chest_enabled and not player.is_overboard and can_handle_items() and player.position.distance_to(storage_position) <= interaction_distance

func chest_is_nearest() -> bool:
	if not near_storage():
		return false
	var distance := player.position.distance_to(storage_position)
	for node in get_parent().get_children():
		if node is ShipStation and node.can_interact(player) and node.global_position.distance_to(player.global_position) < distance:
			return false
	return true

func request(action: String, index: int) -> void:
	if NetworkSession.online and not NetworkSession.applying:
		NetworkSession.command("transfer", {"action": action, "index": index, "revision": view_revision})
		return
	if not can_handle_items() or not near_storage() or not hud.storage_open:
		return
	var source: ShipInventory = storage if action == "take" else inventory
	var target: ShipInventory = inventory if action == "take" else storage
	if source.transfer_to(index, target) == 0:
		feedback.emit("No room for that stack.")

func request_drag(data: Dictionary, destination: int = -1, to_storage: bool = false) -> void:
	if NetworkSession.online and not NetworkSession.applying:
		NetworkSession.command("drag", {"index": data.get("index", -1), "storage": data.get("storage", false), "revision": data.get("revision", -1), "destination": destination, "to_storage": to_storage})
		return
	if not can_handle_items() or data.get("service_id", 0) != get_instance_id():
		return
	if data.get("revision", -1) != view_revision:
		feedback.emit("Items changed. Try dragging again.")
		return
	var from_storage: bool = data.get("storage", false)
	if (from_storage or to_storage) and (not near_storage() or not hud.storage_open):
		return
	var source: ShipInventory = storage if from_storage else inventory
	var target: ShipInventory = storage if to_storage else inventory
	var index: int = data.get("index", -1)
	if destination >= 0:
		source.move_to(index, target, destination)
	elif index >= 0 and index < source.slots.size() and not source.slots[index].is_empty():
		var entry := source.slots[index].duplicate()
		_spawn_drop(entry, player.position)
		source.remove(index, entry.quantity)

func _spawn_drop(entry: Dictionary, point: Vector2) -> void:
	# Parent coordinates keep drops on the moving ship; island drops stay ashore.
	if NetworkSession.online:
		next_drop_id = NetworkSession.dropped_id
		NetworkSession.dropped_id += 1
	drops[next_drop_id] = {"id": entry.id, "quantity": entry.quantity, "position": point, "world": player.is_overboard}
	pickup_inside[next_drop_id] = player.position.distance_to(point) <= pickup_distance
	next_drop_id += 1

func _physics_process(_delta: float) -> void:
	if not NetworkSession.online:
		server_pickups()

func server_pickups() -> void:
	if not can_handle_items():
		return
	for id: int in drops.keys():
		var entry: Dictionary = drops[id]
		var drop_world: Vector2 = entry.position if entry.get("world", false) else get_parent().to_global(entry.position)
		if player.global_position.distance_to(drop_world) > pickup_distance:
			pickup_inside[id] = false
			continue
		if pickup_inside.get(id, false):
			continue
		pickup_inside[id] = true
		var added := inventory.add_items(ItemDatabase.get_item(entry.id), entry.quantity)
		if added == 0:
			continue
		entry.quantity -= added
		if entry.quantity == 0:
			drops.erase(id)
			pickup_inside.erase(id)
		publish()

func publish() -> void:
	view_revision += 1
	local_slots = inventory.capture()
	storage_view = storage.capture()
	updated.emit()
