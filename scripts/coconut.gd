extends Area2D

# Emitted when the player walks over this coconut.
# The island's CollectIsland script listens for this to update the on-screen count.
signal collected(item_id: StringName)

# Which catalog item this pickup gives (see scripts/item-system/items.gd).
# Change it in the Inspector to reuse this scene for other island pickups.
@export var item_id: StringName = &"coconut"

var pickup_key: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	assert(ItemDatabase.get_item(item_id) != null, "Unknown item id: %s" % item_id)
	pickup_key = "%s:%s" % [get_tree().current_scene.scene_file_path, get_path()]
	if VoyageSurvival.gathered_pickups.has(pickup_key):
		hide()
		set_deferred("monitoring", false)
		collected.emit.call_deferred(item_id)

func _on_body_entered(body: Node2D) -> void:
	if body is not CharacterBody2D or VoyageSurvival.dead or VoyageSurvival.gathered_pickups.has(pickup_key):
		return
	if not VoyageSurvival.inventory.add_item(ItemDatabase.get_item(item_id)):
		VoyageSurvival.notice.emit("Food pack full — eat or cook to make room.")
		return
	VoyageSurvival.gathered_pickups[pickup_key] = true
	VoyageSurvival.changed.emit()
	collected.emit(item_id)
	hide()
	set_deferred("monitoring", false)
