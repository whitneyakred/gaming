extends Area2D

# Emitted after this pickup is successfully stored in the player's inventory.
# The island's CollectIsland script listens for this to update the on-screen count.
signal collected(item_id: StringName)

# Which catalog item this pickup gives (see scripts/item-system/items.gd).
# Change it in the Inspector to reuse this scene for other island pickups.
@export var item_id: StringName = &"coconut"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	assert(ItemDatabase.get_item(item_id) != null, "Unknown item id: %s" % item_id)

func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	var player_inventory := body.get("player_inventory") as PlayerInventory
	var item: ItemData = ItemDatabase.get_item(item_id)
	if player_inventory == null or item == null:
		push_warning("Coconut pickup could not find a player inventory or item: %s" % item_id)
		return

	if not player_inventory.add_item(item):
		return

	collected.emit(item_id)
	queue_free()
