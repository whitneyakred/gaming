class_name CraftingStation
extends Node2D
## Recipes transact against a private copy so full bags never consume ingredients.
@export var interaction_distance: float = 42.0
const RECIPES := {
	"fishing_rod": {"wood": 3, "rope": 1, "string": 1},
	"pickaxe": {"wood": 3, "stone": 3},
	"axe": {"wood": 3, "stone": 2},
	"spyglass": {"wood": 2, "stone": 2, "rope": 1},
}

func near(service: InventoryService) -> bool:
	return service.can_handle_items() and not service.player.is_overboard and service.player.global_position.distance_to(global_position) <= interaction_distance

func craft(service: InventoryService, recipe: String, revision: int) -> bool:
	if NetworkSession.online and not multiplayer.is_server(): return false
	if not RECIPES.has(recipe) or not near(service) or not service.hud.crafting_open or revision != service.view_revision: return false
	var sources: Array[ShipInventory] = [service.inventory, VoyageState.get_ship_storage(service.storage_slots), VoyageState.get_ship_storage(service.storage_slots, 1)]
	var copies: Array[PlayerInventory] = []
	for source in sources:
		var copy := PlayerInventory.new()
		copy.max_inv_space = source.max_inv_space
		copy.restore(source.capture())
		copies.append(copy)
	for material: String in RECIPES[recipe]:
		var remaining: int = RECIPES[recipe][material]
		for copy in copies:
			var amount := mini(remaining, copy.get_quantity(StringName(material)))
			if amount > 0: copy.try_remove(StringName(material), amount)
			remaining -= amount
		if remaining > 0:
			service.feedback.emit("Not enough materials in your bag and ship chests.")
			return false
	if not copies[0].try_add(StringName(recipe)):
		service.feedback.emit("Make room in your inventory first.")
		return false
	# No await: concurrent crew commands see the committed stock, never a reservation.
	for i in sources.size(): sources[i].restore(copies[i].capture())
	service.feedback.emit("Crafted %s!" % ItemDatabase.get_item(StringName(recipe)).display_name)
	return true

static func available(service: InventoryService, material: StringName) -> int:
	var total := service.inventory.get_quantity(material)
	for chest_id in 2:
		for entry in VoyageState.get_ship_storage(service.storage_slots, chest_id).capture():
			if entry.get("id") == material: total += int(entry.quantity)
	return total
