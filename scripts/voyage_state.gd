extends Node

## Autoload `VoyageState`: in-memory state for one voyage that must outlive
## a scene change (ship -> island -> ship). Nothing here is saved to disk.
##
## Today it holds each crew member's inventory, so items collected on an
## island are still in the bag back on the ship (see docs/design/isle.md,
## "One VoyageState autoload holds everything that must cross a scene change").

## Distinct item types one crew member can carry. The prototype's per-scene
## inventory used 4, which the island rewards outgrow quickly.
## BR-inventory-slots (6 quick slots + TBD expanded slots) is still open (OI-11).
const INVENTORY_SLOTS: int = 12

var _inventories: Dictionary[StringName, PlayerInventory] = {}
## Prototype salvage and damage survive island scene changes, but not restarting.
var collected_wreckage: Dictionary[Vector2i, bool] = {}
var salvaged_wood: int = 0
var ship_holes: Array[int] = []
var next_hole_seconds: float = 40.0


## The same PlayerInventory instance for the whole voyage. An unknown id gets
## a new, empty inventory that is kept from then on.
func get_inventory(player_id: StringName) -> PlayerInventory:
	if not _inventories.has(player_id):
		var inventory := PlayerInventory.new()
		inventory.player_id = player_id
		inventory.max_inv_space = INVENTORY_SLOTS
		_inventories[player_id] = inventory
	return _inventories[player_id]


## Empties every inventory (for a new voyage or BR-capsize-reset later).
func reset() -> void:
	_inventories.clear()
	collected_wreckage.clear()
	salvaged_wood = 0
	ship_holes.clear()
	next_hole_seconds = 40.0
