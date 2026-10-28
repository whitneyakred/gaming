extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
@export var swim_speed: float = 65.0
var is_overboard: bool = false
var _deck_mask: int
var _deck_layer: int
var _sprite_position: Vector2
var using_station: bool:
	get:
		return is_instance_valid(active_station)

# Stations claim movement through this small interface, without player-to-helm coupling.
var active_station: Node = null

func try_use_station(station: Node) -> bool:
	if is_overboard or not is_instance_valid(station) or using_station or not is_physics_processing():
		return false
	active_station = station
	velocity = Vector2.ZERO
	return true

func leave_station(station: Node) -> void:
	if active_station == station:
		active_station = null

## Each player owns a separate inventory so station checks remain player-specific
## when local multiplayer is added later.
@export var player_inventory: PlayerInventory

@onready var idle_sprite: Sprite2D = $Sprite2D
@onready var fishing_animation: AnimatedSprite2D = $FishingAnimation


func _ready() -> void:
	# The voyage keeps one inventory per crew member, so what you collect on
	# an island is still in your bag back on the ship (scripts/voyage_state.gd).
	var player_id: StringName = &"player_1"
	if player_inventory != null and not player_inventory.player_id.is_empty():
		player_id = player_inventory.player_id
	player_inventory = VoyageState.get_inventory(player_id)

	# The prototype starts each crew member with the tool needed for its only
	# available station. Other acquisition systems can add this item later.
	var fishing_rod := ItemDatabase.get_item(&"fishing_rod")
	if fishing_rod != null and player_inventory.get_quantity(fishing_rod.id) == 0:
		player_inventory.add_item(fishing_rod)

func _physics_process(_delta: float) -> void:
	if using_station:
		velocity = Vector2.ZERO
		return
	# Read WASD / arrow keys; diagonal movement stays the same speed.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if is_overboard:
		velocity = direction * swim_speed
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
	if is_overboard:
		draw_arc(Vector2(0, 3), 12, 0.0, PI, 16, Color(0.7, 0.9, 1.0, 0.6), 1.5)

func play_fishing_animation() -> void:
	idle_sprite.hide()
	fishing_animation.show()
	fishing_animation.play(&"fishing_side")

func _on_fishing_animation_animation_finished() -> void:
	fishing_animation.hide()
	idle_sprite.show()
