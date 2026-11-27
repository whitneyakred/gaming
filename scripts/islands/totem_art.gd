class_name TotemArt
extends RefCounted
const ATLAS := preload("res://assets/items/totem_medpack.png")
static var cache: Dictionary = {}
static func texture(index: int) -> AtlasTexture:
	if cache.has(index): return cache[index]
	var cell := Vector2i(ATLAS.get_width() / 2, ATLAS.get_height())
	var origin := Vector2i(index * cell.x, 0)
	var bounds := ATLAS.get_image().get_region(Rect2i(origin, cell)).get_used_rect()
	var result := AtlasTexture.new()
	result.atlas = ATLAS
	result.region = Rect2(origin + bounds.position, bounds.size)
	# Ignore stray near-transparent pixels around the medical kit silhouette.
	if index == 1: result.region = Rect2(1200,223,398,460)
	result.filter_clip = true
	cache[index] = result
	return result
