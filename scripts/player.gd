extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
@export var swim_speed: float = 65.0
var is_overboard: bool = false
var access_motion: StringName = &""
var access_progress: float = 0.0
var access_start := Vector2.ZERO
var on_land: bool = false
var inventory_open: bool = false
var fishing_active: bool = false
var island_challenge: bool = false
var minigame_avatar: bool = false
var health: int = 15
var hunger: int = 15
var hunger_clock: float = 0.0
var starvation_clock: float = 0.0
var regen_clock: float = 0.0
var eat_cooldown: float = 0.0
var eat_serial: int = 0
var heal_serial: int = 0
var chop_serial := 0
var chop_direction := Vector2.RIGHT
var chop_visual := 0.0
var splash_serial: int = 0
var splash_position := Vector2.ZERO
var swim_time: float = 0.0
var danger_time: float = 0.0
var hurt_serial: int = 0
var respawn_serial: int = 0
var _deck_mask: int
var _deck_layer: int
var presentation: Node2D
var presentation_offset := Vector2.ZERO # World-space; never changes collision state.
@export var correction_response := 18.0
var _remote_motion: Dictionary = {}
var _walk_previous := Vector2.ZERO
var _walk_current := Vector2.ZERO
var _walk_offset := Vector2.ZERO
var _walk_sampled := false
var _walk_outside := false
var _walk_respawn := 0
@export var character_appearance: CharacterAppearance = preload("res://assets/player/characters/viking/appearance.tres")
var using_station: bool:
	get:
		return is_instance_valid(active_station)

# Stations claim movement through this small interface, without player-to-helm coupling.
var active_station: Node = null

func try_use_station(station: Node) -> bool:
	if health <= 0: return false
	if inventory_open or fishing_active or is_overboard or not is_instance_valid(station) or using_station or not is_physics_processing():
		return false
	active_station = station
	velocity = Vector2.ZERO
	return true

func leave_station(station: Node) -> void:
	if active_station == station:
		active_station = null

## The voyage owns this resource; stations and UI share the same inventory.
@export var player_inventory: PlayerInventory

@onready var idle_sprite: Sprite2D = $Sprite2D
@onready var fishing_animation: AnimatedSprite2D = $FishingAnimation


func _ready() -> void:
	# Network authority/prediction runs at 50; animation samples at 100.
	process_physics_priority = 60
	process_priority = -50
	presentation = Node2D.new()
	presentation.name = "Presentation"
	add_child(presentation)
	idle_sprite.reparent(presentation, false)
	fishing_animation.reparent(presentation, false)
	var swim_wake := SwimWake.new()
	swim_wake.name = "SwimWake"
	add_child(swim_wake)
	if minigame_avatar:
		return
	var initial_inventory := player_inventory
	var player_id := initial_inventory.player_id if initial_inventory != null else &"player_1"
	player_inventory = VoyageState.get_player_inventory(player_id, initial_inventory)
	# Catalog autoloads and HUD controls can still be initializing during _ready.
	# Defer the starter grant so ItemDatabase is populated and the hotbar receives
	# the inventory_changed signal that renders this item.
	call_deferred(&"_grant_starting_inventory")


func _grant_starting_inventory() -> void:
	# Grant the voyage's starting tools once, including across island visits.
	if not NetworkSession.online or multiplayer.is_server():
		VoyageState.grant_starter(player_inventory)

func _physics_process(_delta: float) -> void:
	if not NetworkSession.online or minigame_avatar:
		move_crew(Input.get_vector("move_left", "move_right", "move_up", "move_down"), _delta)
	capture_walk_sample()

func interpolates_walk() -> bool:
	return minigame_avatar or not NetworkSession.online or NetworkSession.players.get(NetworkSession.local_id) == self

func reset_walk_interpolation() -> void:
	_walk_previous = position
	_walk_current = position
	_walk_offset = Vector2.ZERO
	_walk_sampled = false

func capture_walk_sample() -> void:
	if not interpolates_walk() or access_motion != &"" or using_station or health <= 0:
		reset_walk_interpolation()
		return
	if not _walk_sampled or _walk_outside != is_overboard or _walk_respawn != respawn_serial or position.distance_to(_walk_current) > 80.0:
		_walk_current = position
	_walk_previous = _walk_current
	_walk_current = position
	_walk_outside = is_overboard
	_walk_respawn = respawn_serial
	_walk_sampled = true

func walking_render_offset(fraction: float) -> Vector2:
	# Never blend across a teleport, replay correction or boarding coordinate change.
	if not interpolates_walk() or not _walk_sampled or not position.is_equal_approx(_walk_current) or _walk_outside != is_overboard or _walk_respawn != respawn_serial or access_motion != &"" or using_station or health <= 0:
		return Vector2.ZERO
	var offset := _walk_previous.lerp(_walk_current, clampf(fraction, 0.0, 1.0)) - position
	return offset if is_overboard else get_parent().global_transform.basis_xform(offset)

func _process(_delta: float) -> void:
	global_rotation = 0.0
	if not _remote_motion.is_empty():
		if is_overboard != _remote_motion.outside or on_land != _remote_motion.land or respawn_serial != _remote_motion.respawn or access_motion != &"" or health <= 0 or using_station or position.distance_to(_remote_motion.target) > 0.01:
			_remote_motion.clear()
			presentation_offset = Vector2.ZERO
		else:
			_remote_motion.elapsed = minf(_remote_motion.elapsed + _delta, _remote_motion.duration)
			var point: Vector2 = Vector2(_remote_motion.start).lerp(_remote_motion.target, _remote_motion.elapsed / _remote_motion.duration)
			var world_point: Vector2 = point if is_overboard else get_parent().to_global(point)
			presentation_offset = world_point - global_position
			if _remote_motion.elapsed >= _remote_motion.duration: _remote_motion.clear()
	else:
		presentation_offset *= exp(-correction_response * _delta)
	if presentation_offset.length_squared() < 0.0001: presentation_offset = Vector2.ZERO
	_walk_offset = walking_render_offset(Engine.get_physics_interpolation_fraction())
	if presentation != null:
		presentation.position = global_transform.basis_xform_inv(presentation_offset + _walk_offset)
	var label := get_node_or_null("CrewName") as Control
	if label != null: label.position = Vector2(-50, -42) + global_transform.basis_xform_inv(presentation_offset + _walk_offset)
	visible = health > 0
	# Deck props sit at zero. Water is below the hull, plank and ladder;
	# shoreline walkers and crew on deck stay above the scenery.
	z_index = -1 if is_overboard and not on_land and access_motion in [&"", &"dunk", &"surface", &"align"] else 1

func smooth_correction(previous_visual: Vector2) -> void:
	# Shift both samples with replay so routine acknowledgements do not restart
	# walking interpolation at snapshot frequency (even when error is zero).
	if _walk_sampled and interpolates_walk() and position.distance_to(_walk_current) <= 80.0:
		_walk_previous += position - _walk_current
		_walk_current = position
	else:
		reset_walk_interpolation()
	_remote_motion.clear()
	presentation_offset = (previous_visual - global_position - _walk_offset).limit_length(80.0)

func smooth_remote_motion(previous_visual: Vector2, duration: float) -> void:
	# The host has already simulated and acknowledged the whole input batch.
	# Display that displacement over its duration without delaying collisions.
	if access_motion != &"" or health <= 0 or using_station or previous_visual.distance_to(global_position) > 80.0:
		_remote_motion.clear()
		presentation_offset = Vector2.ZERO
		return
	var start: Vector2 = previous_visual if is_overboard else get_parent().to_local(previous_visual)
	_remote_motion = {"start": start, "target": position, "elapsed": 0.0, "duration": clampf(duration, 1.0 / 60.0, 0.15), "outside": is_overboard, "land": on_land, "respawn": respawn_serial}
	presentation_offset = previous_visual - global_position

func visual_position() -> Vector2:
	return global_position + presentation_offset + _walk_offset

func move_crew(direction: Vector2, _delta: float) -> void:
	if health <= 0 or using_station or inventory_open or island_challenge or access_motion != &"":
		velocity = Vector2.ZERO
		return
	# Read WASD / arrow keys; diagonal movement stays the same speed.

	if is_overboard:
		velocity = direction * (walk_speed if on_land else swim_speed)
		var next := global_position + velocity * _delta
		var ship := get_parent() as Ship
		if ship:
			var hull := ship.get_swimming_hull_polygon()
			if not Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([global_position, next]), hull).is_empty():
				return
			for island in ship.get_islands():
				if island is QuestIsland and island.blocks_path(global_position, next): return
			if is_instance_valid(ship.foliage):
				next = ship.foliage.collision.move(global_position,next-global_position,ship.foliage.changes)
		velocity = (next-global_position)/maxf(_delta,0.000001)
		global_position = next
		return
	velocity = direction * walk_speed
	# Explicit delta is essential during replay: move_and_slide chooses its time
	# step from the current engine callback, which can be render rather than physics
	# when an ENet snapshot arrives. Host, guest, and replay use this same sweep.
	var motion := velocity * _delta
	for slide in max_slides:
		var collision := move_and_collide(motion, false, safe_margin)
		if collision == null: break
		motion = collision.get_remainder().slide(collision.get_normal())
		velocity = velocity.slide(collision.get_normal())
		if motion.length_squared() < 0.000001: break

func set_overboard(value: bool) -> void:
	# Respawn/teleport callers must not leave a stale traversal controlling movement.
	if not value:
		access_motion = &""
		access_progress = 0.0
	if value == is_overboard:
		return
	if value:
		if is_instance_valid(active_station) and active_station.has_method("release_control"):
			active_station.release_control()
		active_station = null
		_deck_mask = collision_mask
		_deck_layer = collision_layer
		collision_mask = 0
		collision_layer = 0
		var world := global_transform
		set_as_top_level(true)
		global_transform = world
		global_rotation = 0
	else:
		set_as_top_level(false)
		rotation = 0
		collision_mask = _deck_mask
		collision_layer = _deck_layer
	is_overboard = value
	reset_walk_interpolation()
	if idle_sprite is CrewSprite: idle_sprite.refresh(0)
	queue_redraw()
	fishing_animation.stop()
	fishing_animation.hide()
	idle_sprite.show()
	velocity = Vector2.ZERO

func _draw() -> void:
	if is_overboard and not on_land and not idle_sprite is CrewSprite:
		draw_arc(Vector2(0, 3), 12, 0.0, PI, 16, Color(0.7, 0.9, 1.0, 0.6), 1.5)

func play_fishing_animation() -> void:
	# Keep the normal sailor visible; the line and bobber provide fishing feedback.
	fishing_animation.stop()
	fishing_animation.hide()
	idle_sprite.show()

func _on_fishing_animation_animation_finished() -> void:
	fishing_animation.hide()
	idle_sprite.show()

func update_land(is_land: bool) -> void:
	if on_land == (is_overboard and is_land): return
	on_land = is_overboard and is_land
	if idle_sprite is CrewSprite: idle_sprite.refresh(0)
	queue_redraw()
