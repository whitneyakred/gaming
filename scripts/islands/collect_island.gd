class_name CollectIsland
extends IslandGame

## "Collect them all, then get back to the rowboat" island.
## Used by the coconut island; reuse it for any pickup game by putting your
## pickups in a group and setting Pickup Group / Item Id in the Inspector.
## Each pickup needs a `collected` signal (scenes/coconut.tscn has one).

@export_group("Pickups")
## Every node in this group counts toward the goal.
@export var pickup_group: StringName = &"coconuts"
## Catalog item (scripts/item-system/items.gd) whose name the HUD shows.
@export var item_id: StringName = &"coconut"

var collected_count: int = 0
var total_count: int = 0
var _item_name: String = "Item"


func _setup_game() -> void:
	var item: ItemData = ItemDatabase.get_item(item_id)
	_item_name = item.display_name if item else String(item_id).capitalize()

	var pickups := get_tree().get_nodes_in_group(pickup_group)
	total_count = pickups.size()
	for pickup in pickups:
		if pickup.has_signal("collected"):
			pickup.collected.connect(_on_item_collected)


func _on_item_collected(_item_id: StringName) -> void:
	collected_count += 1
	refresh_hud()


func _get_objective_text() -> String:
	return "%ss: %d / %d" % [_item_name, collected_count, total_count]


func _is_objective_complete() -> bool:
	return collected_count >= total_count


func win(message: String = "") -> void:
	if not is_running() or VoyageSurvival.dead:
		return
	var reward_key := "pantry:" + scene_file_path
	var previous: int = int(VoyageSurvival.gathered_pickups.get(reward_key, 0))
	if previous < 3:
		var granted := 0
		for _i in range(3 - previous):
			if VoyageSurvival.inventory.add_item(ItemDatabase.get_item(&"potato")):
				granted += 1
		# Record only granted units, so a full pack cannot silently erase the reward.
		if granted > 0:
			VoyageSurvival.gathered_pickups[reward_key] = previous + granted
			VoyageSurvival.notice.emit("Island supplies: %d potatoes" % granted)
			VoyageSurvival.changed.emit()
	super.win(message)
