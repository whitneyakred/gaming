class_name ChallengeItems
extends RefCounted
## Private objective counters, never registered as voyage loot.
const TOKENS := [&"gold_coin", &"crab_meat", &"mango", &"banana", &"papaya", &"fresh_water", &"compass", &"gunpowder", &"glow_jar", &"cannonball", &"torch", &"honey"]
static var definitions: Dictionary = {}
static func definition(id: StringName) -> ItemData:
	var item: ItemData = ItemDatabase.get_item(id)
	if item != null or id not in TOKENS: return item
	if definitions.has(id): return definitions[id]
	item = ItemData.new()
	item.id = id
	item.display_name = String(id).replace("_", " ").capitalize()
	item.max_stack = 999
	definitions[id] = item
	return item
