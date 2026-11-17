extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
@export var swim_speed: float = 65.0
var is_overboard: bool = false
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
var swim_time: float = 0.0
var danger_time: float = 0.0
var hurt_serial: int = 0
var respawn_serial: int = 0
var _deck_mask: int
var _deck_layer: int
var _sprite_position: Vector2
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
	if NetworkSession.online and not minigame_avatar:
		return
	move_crew(Input.get_vector("move_left", "move_right", "move_up", "move_down"), _delta)

func _process(_delta: float) -> void:
	global_rotation = 0.0
	visible = health > 0

func move_crew(direction: Vector2, _delta: float) -> void:
	if health <= 0 or using_station or inventory_open or island_challenge:
		velocity = Vector2.ZERO
		return
	# Read WASD / arrow keys; diagonal movement stays the same speed.

	if is_overboard:
		velocity = direction * (walk_speed if on_land else swim_speed)
		var next := global_position + velocity * _delta
		var ship := get_parent() as Ship
		if ship:
			var hull := ship.get_hull_polygon(ship.global_position, ship.global_rotation)
			if not Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([global_position, next]), hull).is_empty():
				return
		global_position = next
		return
	velocity = direction * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()

func set_overboard(value: bool) -> void:
	if value == is_overboard:
		return
	if value:
		if is_instance_valid(active_station) and active_station.has_method("release_control"):
			active_station.release_control()
		active_station = null
		_deck_mask = collision_mask
		_deck_layer = collision_layer
		_sprite_position = idle_sprite.position
		collision_mask = 0
		collision_layer = 0
		var world := global_transform
		set_as_top_level(true)
		global_transform = world
		global_rotation = 0
		idle_sprite.region_enabled = true
		# Crop the existing portrait to helmet and face, above the shoulders.
		var size := idle_sprite.texture.get_size()
		idle_sprite.region_rect = Rect2(size * Vector2(0.31, 0.07), size * Vector2(0.36, 0.35))
		idle_sprite.position = Vector2(0, -7)
	else:
		set_as_top_level(false)
		rotation = 0
		collision_mask = _deck_mask
		collision_layer = _deck_layer
		idle_sprite.region_enabled = false
		idle_sprite.position = _sprite_position
	is_overboard = value
	queue_redraw()
	fishing_animation.stop()
	fishing_animation.hide()
	idle_sprite.show()
	velocity = Vector2.ZERO

func _draw() -> void:
	if is_overboard and not on_land:
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
	on_land = is_overboard and is_land
	if is_overboard:
		idle_sprite.region_enabled = not on_land
		idle_sprite.position = _sprite_position if on_land else Vector2(0, -7)
	queue_redraw()
