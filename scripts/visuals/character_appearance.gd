class_name CharacterAppearance
extends Resource
## A replaceable character atlas pair. Rows: down, left, right, up.
@export var display_name: String = "Sailor"
@export var walk_atlas: Texture2D
@export var swim_atlas: Texture2D
## Optional action art. Regions/anchors allow trimmed, registered source frames
## without rewriting the generated sheet or relying on an exact grid size.
@export var action_atlas: Texture2D
@export var action_regions: Array[Rect2] = []
@export var action_anchors: PackedVector2Array = PackedVector2Array()
@export var action_pixel_scale: float = 0.125
@export var jump_frames: PackedInt32Array = PackedInt32Array([0, 1, 2, 3])
@export var climb_frames: PackedInt32Array = PackedInt32Array([4, 5, 6, 7])
@export var columns: int = 4
@export var rows: int = 4
@export var frame_world_size: float = 48.0
@export var feet_anchor: float = 0.88
@export var water_anchor: float = 0.86
@export var walk_fps: float = 8.0
@export var swim_fps: float = 6.0
## Visual-only rise/dip in world pixels, once per swimming stroke.
@export_range(0.0, 4.0, 0.1) var swim_bob_height: float = 1.4
@export var idle_column: int = 0
@export var walk_cycle: PackedInt32Array = PackedInt32Array([1, 2, 3, 2])
## Authored head-center offsets within atlas cells, in source pixels.
@export var walk_column_offsets: PackedFloat32Array = PackedFloat32Array()
@export var swim_column_offsets: PackedFloat32Array = PackedFloat32Array()

func portrait() -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = walk_atlas
	var cell := walk_atlas.get_size() / Vector2(columns, rows)
	var frame_rect := Rect2i(Vector2i(int(cell.x) * idle_column, 0), Vector2i(cell))
	# Center the silhouette rather than the uneven transparent atlas padding.
	var bounds := walk_atlas.get_image().get_region(frame_rect).get_used_rect()
	result.region = Rect2(frame_rect.position + bounds.position, bounds.size) if bounds.has_area() else Rect2(frame_rect)
	return result
