extends Node

## Autoload `VoyageState`: in-memory state for one voyage that must outlive
## a scene change (ship -> island -> ship). Nothing here is saved to disk.
##
## Carries player inventories, ship storage and scene-local floor items across
## visits. All state resets on a new voyage; it is not a disk save.

## The four hotbar slots are the entire carried inventory.
const INVENTORY_SLOTS: int = 4

var _inventories: Dictionary[StringName, PlayerInventory] = {}
var _starter_granted: Dictionary[StringName, bool] = {}
var ship_storage: ShipInventory
var port_storage: ShipInventory
var floor_items: Dictionary = {}
signal quest_changed
const KEY_IDS := ["bronze", "silver", "gold"]
var paradise_quest: Dictionary = {}

func quest_data() -> Dictionary:
	return paradise_quest.duplicate(true)

func restore_quest(data: Dictionary) -> void:
	if paradise_quest == data: return
	paradise_quest = data.duplicate(true)
	quest_changed.emit()

func has_key(key: String) -> bool:
	return bool(paradise_quest.get(key, false))

func grant_key(key: String, bag: PlayerInventory = null) -> bool:
	if key not in KEY_IDS or bag == null: return false
	reconcile_keys()
	if has_key(key): return false
	if not bag.try_add(StringName(key + "_key")): return false
	paradise_quest[key] = true
	quest_changed.emit()
	return true

func all_keys() -> bool:
	return KEY_IDS.all(func(key: String) -> bool: return has_key(key))

func open_paradise(bag: PlayerInventory = null) -> bool:
	if paradise_quest.get("gate_open", false): return true
	if bag == null: return false
	var changed := false
	for key in KEY_IDS:
		if not paradise_quest.get(key + "_inserted", false) and bag.try_remove(StringName(key + "_key")):
			paradise_quest[key + "_inserted"] = true
			paradise_quest[key] = true
			changed = true
	var unlocked := KEY_IDS.all(func(key: String) -> bool: return paradise_quest.get(key + "_inserted", false))
	if unlocked: paradise_quest["gate_open"] = true
	if changed: quest_changed.emit()
	return unlocked

func complete_voyage() -> bool:
	if not paradise_quest.get("gate_open", false): return false
	paradise_quest["complete"] = true
	quest_changed.emit()
	return true

const GROUND_ITEM_LIFETIME := 300.0

func _physics_process(delta: float) -> void:
	if NetworkSession.online and (not multiplayer.is_server() or not NetworkSession.world_ready): return
	advance_ground_items(delta)
	reconcile_keys()

func advance_ground_items(delta: float) -> void:
	for scene_drops: Dictionary in floor_items.values():
		for drop_id in scene_drops.keys():
			var entry: Dictionary = scene_drops[drop_id]
			entry["age"] = float(entry.get("age", 0.0)) + delta
			if entry.age >= GROUND_ITEM_LIFETIME:
				scene_drops.erase(drop_id)
				for service in get_tree().get_nodes_in_group("inventory_services"):
					if service.drops == scene_drops: service.pickup_inside.erase(drop_id)

func mark_keys(entries: Array, found: Dictionary) -> void:
	for entry: Dictionary in entries:
		if int(entry.get("quantity", 0)) <= 0: continue
		var id := str(entry.get("id", ""))
		for key in KEY_IDS:
			if id == key + "_key": found[key] = true

func reconcile_keys() -> void:
	var found := {}
	if NetworkSession.online:
		var active_tokens := {}
		for id in NetworkSession.services:
			mark_keys(NetworkSession.services[id].inventory.slots, found)
			active_tokens[NetworkSession.identities.get(id, {}).get("token", "")] = true
		# A disconnected sailor's saved bag still owns its key.
		for token in NetworkSession.accounts:
			if not active_tokens.has(token): mark_keys(NetworkSession.accounts[token].get("inventory", []), found)
	else:
		for bag: PlayerInventory in _inventories.values(): mark_keys(bag.slots, found)
	for chest in [ship_storage, port_storage]:
		if chest != null: mark_keys(chest.slots, found)
	for scene_drops: Dictionary in floor_items.values(): mark_keys(scene_drops.values(), found)
	var changed := false
	for key in KEY_IDS:
		# An already opened gate stays open when upgrading an older voyage save.
		var present: bool = found.has(key) or paradise_quest.get(key + "_inserted", false) or paradise_quest.get("gate_open", false)
		if has_key(key) != present:
			paradise_quest[key] = present
			changed = true
	if changed: quest_changed.emit()


func get_ship_storage(capacity: int = 18, chest_id: int = 0) -> ShipInventory:
	if chest_id == 1:
		if port_storage == null:
			port_storage = ShipInventory.new()
			port_storage.max_inv_space = capacity
			var pickaxe := ItemDatabase.get_item(&"pickaxe")
			if pickaxe != null: port_storage.add_items(pickaxe,4)
		return port_storage
	if ship_storage == null:
		ship_storage = ShipInventory.new()
		ship_storage.max_inv_space = capacity
	return ship_storage

func grant_starter(inventory: PlayerInventory) -> void:
	if _starter_granted.has(inventory.player_id):
		return
	var rod_granted := inventory.get_quantity(&"fishing_rod") > 0 or inventory.try_add(&"fishing_rod")
	var spyglass_granted := inventory.get_quantity(&"spyglass") > 0 or inventory.try_add(&"spyglass")
	var axe_granted := inventory.get_quantity(&"axe") > 0 or inventory.try_add(&"axe")
	if rod_granted and spyglass_granted and axe_granted:
		_starter_granted[inventory.player_id] = true


## The same PlayerInventory instance for the whole voyage. An unknown id gets
## a new, empty inventory that is kept from then on.
func get_inventory(player_id: StringName) -> PlayerInventory:
	return get_player_inventory(player_id)


## Both scene players and island rewards use the same voyage inventory.
func get_player_inventory(player_id: StringName, initial_inventory: PlayerInventory = null) -> PlayerInventory:
	var resolved_player_id := player_id if not player_id.is_empty() else &"player_1"
	if not _inventories.has(resolved_player_id):
		var inventory := initial_inventory if initial_inventory != null else PlayerInventory.new()
		inventory.player_id = resolved_player_id
		inventory.max_inv_space = INVENTORY_SLOTS
		_inventories[resolved_player_id] = inventory
	return _inventories[resolved_player_id]


## Empties every inventory for a new voyage.
func reset() -> void:
	_inventories.clear()
	_starter_granted.clear()
	ship_storage = null
	port_storage = null
	floor_items.clear()
	paradise_quest.clear()
	quest_changed.emit()


func clear_voyage() -> void:
	reset()

