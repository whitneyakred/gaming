extends Area2D

# Emitted when the player walks over this coconut.
# island.gd listens for this to update the on-screen count.
signal collected(item_id: StringName)

# Which catalog item this pickup gives (see scripts/item-system/items.gd).
# Change it in the Inspector to reuse this scene for other island pickups.
@export var item_id: StringName = &"coconut"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	assert(ItemDatabase.get_item(item_id) != null, "Unknown item id: %s" % item_id)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit(item_id)
		queue_free()
