extends Node

## In-memory state that belongs to the active voyage rather than one scene.
## It is deliberately not saved to disk; restarting the game starts a new voyage.

var _inventories_by_player_id: Dictionary[StringName, PlayerInventory] = {}


func get_player_inventory(player_id: StringName, initial_inventory: PlayerInventory = null) -> PlayerInventory:
	var resolved_player_id := player_id if not player_id.is_empty() else &"player_1"
	if _inventories_by_player_id.has(resolved_player_id):
		return _inventories_by_player_id[resolved_player_id]

	var inventory := initial_inventory if initial_inventory != null else PlayerInventory.new()
	inventory.player_id = resolved_player_id
	_inventories_by_player_id[resolved_player_id] = inventory
	return inventory


func clear_voyage() -> void:
	_inventories_by_player_id.clear()
