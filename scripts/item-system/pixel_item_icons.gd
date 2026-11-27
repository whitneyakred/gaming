class_name PixelItemIcons
extends RefCounted
const ATLAS := preload("res://assets/items/pixel_items.png")
const IDS := [&"axe",&"pickaxe",&"fishing_rod",&"spyglass",&"wood",&"stone",&"coal",&"rope",&"string",&"leather",&"medpack",&"bronze_key",&"silver_key",&"gold_key",&"coconut",&"fish_cod",&"dried_fish",&"gold_coin",&"crab_meat",&"mango",&"banana",&"papaya",&"fresh_water",&"compass",&"gunpowder",&"glow_jar",&"cannonball",&"torch",&"honey"]
static var cache: Dictionary = {}
static var source_image: Image
static func get_icon(id: StringName) -> Texture2D:
	if id == &"dried_fish": return preload("res://assets/cooking/kabob_pixel.tres")
	if id == &"medpack": return TotemArt.texture(1)
	var index := IDS.find(id)
	return texture(index) if index >= 0 else null
static func texture(index: int) -> AtlasTexture:
	if cache.has(index): return cache[index]
	var cell := Vector2i(ATLAS.get_width()/8,ATLAS.get_height()/4)
	var region := Rect2i(Vector2i(index%8,index/8)*cell,cell)
	# The neighboring axe spills into the first pixels of the pickaxe cell.
	if index == 1:
		region.position.x += 16
		region.size.x -= 16
	# Scan once per icon; trim transparent padding without changing source pixels.
	if source_image == null: source_image = ATLAS.get_image()
	var image := source_image.get_region(region)
	var bounds := image.get_used_rect()
	var result := AtlasTexture.new()
	result.atlas = ATLAS
	result.region = Rect2(region.position+bounds.position,bounds.size)
	result.filter_clip = true
	cache[index] = result
	return result
