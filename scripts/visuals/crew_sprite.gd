class_name CrewSprite
extends Sprite2D
## Animation is presentation-only: local deck motion avoids walking while sailing.
var facing: int = 0
var clock: float = 0.0
var swimming: bool = false
var moving: bool = false
var last_position: Vector2
var last_outside: bool = false
var last_respawn: int = 0
var last_hurt := -1
var hurt_flash := 0.0
@onready var crew: CharacterBody2D = get_parent()

func _ready() -> void:
	# Sample after movement, once per physics tick. Render-only frames must not
	# reset the walk cycle when no new physics displacement has occurred.
	process_physics_priority = 100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	last_position = crew.position
	refresh(0)

func _physics_process(delta: float) -> void:
	refresh(delta)

func refresh(delta: float) -> void:
	var appearance: CharacterAppearance = crew.character_appearance
	if appearance == null: return
	var presented: Vector2 = crew.position + (crew.presentation_offset if crew.is_overboard else crew.get_parent().global_transform.basis_xform_inv(crew.presentation_offset))
	var displacement := presented - last_position
	if not crew.is_overboard and crew.get_parent() is Node2D:
		displacement = crew.get_parent().global_transform.basis_xform(displacement)
	var transition: bool = last_outside != crew.is_overboard or last_respawn != crew.respawn_serial
	last_position = presented
	last_outside = crew.is_overboard
	last_respawn = crew.respawn_serial
	if last_hurt >= 0 and crew.hurt_serial != last_hurt: hurt_flash = 0.35
	last_hurt = crew.hurt_serial
	hurt_flash = maxf(0.0, hurt_flash - delta)
	self_modulate = Color(1.0, 0.3, 0.25) if hurt_flash > 0.0 else Color.WHITE
	# Only rotate the climbing art: name labels, wake and walking stay upright.
	rotation = crew.get_parent().global_rotation if crew.access_motion == &"climb" else 0.0
	if _show_action(appearance):
		return
	var traversing: bool = crew.access_motion != &""
	var next_swimming: bool = crew.is_overboard and not crew.on_land and (not traversing or crew.access_motion in [&"surface", &"align"])
	if swimming != next_swimming or transition: clock = 0
	swimming = next_swimming
	moving = not transition and delta > 0 and displacement.length() > 0.03 and displacement.length() < 150 and not crew.using_station and not crew.inventory_open and not crew.island_challenge
	if moving:
		# Keep the chosen axis near diagonals and ignore tiny reconciliation nudges.
		if displacement.length() > 0.4:
			var horizontal := absf(displacement.x) > absf(displacement.y) * (0.8 if facing in [1, 2] else 1.25)
			if horizontal: facing = 2 if displacement.x > 0 else 1
			else: facing = 0 if displacement.y > 0 else 3
	if traversing:
		moving = true
		if crew.access_motion in [&"jump", &"dunk", &"surface"]: facing = 1
		elif crew.access_motion == &"climb": facing = 3
		elif crew.access_motion == &"step_on":
			var direction: Vector2 = crew.get_parent().global_transform.basis_xform(Vector2.RIGHT)
			facing = (2 if direction.x > 0 else 1) if absf(direction.x) > absf(direction.y) else (0 if direction.y > 0 else 3)
	var atlas := appearance.swim_atlas if swimming else appearance.walk_atlas
	if atlas == null: return
	texture = atlas
	region_enabled = false
	hframes = appearance.columns
	vframes = appearance.rows
	var rate := appearance.swim_fps if swimming else appearance.walk_fps
	# A gentle continuous tread when stationary in water; no idle foot shuffling.
	if swimming or moving: clock += delta * (rate if moving else 2.5)
	else: clock = 0
	# Each appearance declares its authored stride order and neutral passing pose.
	var cycle := appearance.walk_cycle
	var column: int = int(clock) % hframes if swimming else (cycle[int(clock) % cycle.size()] if moving and not cycle.is_empty() else appearance.idle_column)
	# A single side row removes differences in generated left/right silhouettes.
	flip_h = facing == 2
	frame = (1 if facing == 2 else facing) * hframes + column
	# Keep the head anchored even when source-sheet padding varies by column.
	var offsets := appearance.swim_column_offsets if swimming else appearance.walk_column_offsets
	var correction: float = offsets[column] if column < offsets.size() else 0.0
	offset = Vector2(correction if flip_h else -correction, 0)
	scale = Vector2.ONE * appearance.frame_world_size / (atlas.get_width() / float(hframes))
	position = Vector2(0, -appearance.frame_world_size * ((appearance.water_anchor if swimming else appearance.feet_anchor) - 0.5))
	if crew.chop_visual > 0:
		var swing := sin((1.0-crew.chop_visual/0.48)*PI)
		rotation += swing*0.15*signf(crew.chop_direction.x)
		position += crew.chop_direction*swing*3.0
		facing = (2 if crew.chop_direction.x > 0 else 1) if absf(crew.chop_direction.x)>absf(crew.chop_direction.y) else (0 if crew.chop_direction.y>0 else 3)
		frame = (1 if facing==2 else facing)*hframes+appearance.idle_column
		flip_h = facing==2
	if swimming:
		# Continuous stroke phase avoids snapping at frame boundaries. Only the
		# visual moves: collision, movement and the water wake stay at the surface.
		position.y += sin(clock * TAU / hframes) * appearance.swim_bob_height
	if crew.access_motion == &"jump":
		position.y -= sin(crew.access_progress * PI) * 18.0
	elif crew.access_motion == &"climb":
		position.y -= sin(crew.access_progress * TAU * 2.0)
	elif crew.access_motion == &"surface":
		var rise: float = smoothstep(0.0, 1.0, crew.access_progress)
		position.y += (1.0 - rise) * 9.0
		self_modulate = Color(0.4, 0.67, 0.85, 0.25).lerp(Color.WHITE, rise)
	elif crew.access_motion == &"dunk":
		position.y += crew.access_progress * 10.0
		self_modulate = Color(0.4, 0.67, 0.85, 0.3)

func _show_action(appearance: CharacterAppearance) -> bool:
	var phase: StringName = crew.access_motion
	if phase not in [&"jump", &"dunk", &"climb"] or appearance.action_atlas == null:
		return false
	var frames := appearance.climb_frames if phase == &"climb" else appearance.jump_frames
	if frames.is_empty(): return false
	var t: float = crew.access_progress
	var index: int
	if phase == &"climb": index = int(t * frames.size() * 2.0) % frames.size()
	elif phase == &"dunk": index = frames.size() - 1
	else: index = mini(int(t * frames.size()), frames.size() - 1)
	var source: int = frames[index]
	if source < 0 or source >= appearance.action_regions.size() or source >= appearance.action_anchors.size():
		return false
	texture = appearance.action_atlas
	hframes = 1
	vframes = 1
	frame = 0
	region_enabled = true
	region_filter_clip_enabled = true
	region_rect = appearance.action_regions[source]
	offset = region_rect.size * 0.5 - (appearance.action_anchors[source] - region_rect.position)
	scale = Vector2.ONE * appearance.action_pixel_scale
	flip_h = false
	facing = 3 if phase == &"climb" else 1
	swimming = false
	moving = true
	position = Vector2.ZERO
	if phase == &"jump":
		var flight := clampf((t - 0.15) / 0.85, 0, 1)
		position.y -= sin(flight * PI) * 22.0
	elif phase == &"climb":
		position.y -= sin(t * TAU * 2.0)
	else:
		# The tucked body sinks into the sea before the swimming silhouette rises.
		position.y += smoothstep(0, 1, t) * 14.0
		scale *= lerpf(1.0, 0.9, t)
		self_modulate = Color.WHITE.lerp(Color(0.35, 0.6, 0.82, 0.18), smoothstep(0, 0.8, t))
	return true
