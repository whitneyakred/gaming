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
	if not RECIPES.has(recipe) or not near(service) or not service.hud.crafting_open or revision != service.view_revision: return false
	var bag := PlayerInventory.new()
	bag.max_inv_space = service.inventory.max_inv_space
	bag.restore(service.inventory.capture())
	for material: String in RECIPES[recipe]:
		if not bag.try_remove(StringName(material), RECIPES[recipe][material]):
			service.feedback.emit("Not enough materials in your inventory.")
			return false
	if not bag.try_add(StringName(recipe)):
		service.feedback.emit("Make room in your inventory first.")
		return false
	service.inventory.restore(bag.capture())
	service.feedback.emit("Crafted %s!" % ItemDatabase.get_item(StringName(recipe)).display_name)
	return true
