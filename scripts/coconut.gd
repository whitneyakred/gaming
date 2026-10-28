extends Area2D

# A pickup lying on the ground. Walking over it puts the item in that crew
# member's voyage inventory. If the bag is full, it stays on the ground.
# The island's CollectIsland script listens for `collected` to update the
# on-screen count.

# Emitted only after the item was stored in the inventory.
signal collected(item_id: StringName)

# Which catalog item this pickup gives (see scripts/item-system/items.gd).
# Change it in the Inspector to reuse this scene for other island pickups.
@export var item_id: StringName = &"coconut"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	assert(ItemDatabase.get_item(item_id) != null, "Unknown item id: %s" % item_id)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("crew"):
		return
	var stored := false
	var game := _find_island_game()
	if game:
		stored = game.give_item(item_id, 1, body) > 0
	else:
		var inventory := body.get("player_inventory") as PlayerInventory
		stored = inventory != null and inventory.add_item(ItemDatabase.get_item(item_id))
	if stored:
		collected.emit(item_id)
		queue_free()

func _find_island_game() -> IslandGame:
	var node := get_parent()
	while node != null and not (node is IslandGame):
		node = node.get_parent()
	return node as IslandGame
