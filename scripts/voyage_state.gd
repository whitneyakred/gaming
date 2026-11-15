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
var floor_items: Dictionary = {}

func get_ship_storage(capacity: int = 18) -> ShipInventory:
	if ship_storage == null:
		ship_storage = ShipInventory.new()
		ship_storage.max_inv_space = capacity
	return ship_storage

func grant_starter(inventory: PlayerInventory) -> void:
	if _starter_granted.has(inventory.player_id):
		return
	if inventory.get_quantity(&"fishing_rod") > 0 or inventory.try_add(&"fishing_rod"):
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
	floor_items.clear()


func clear_voyage() -> void:
	reset()
