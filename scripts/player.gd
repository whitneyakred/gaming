extends CharacterBody2D

signal feedback_requested(text: String)

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
@export var drop_distance: float = 32.0
@export var world_item_scene: PackedScene = preload("res://scenes/items/world_item.tscn")
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
var fishing_animating: bool = false
var facing_direction := Vector2.DOWN

func try_use_station(station: Node) -> bool:
	if VoyageSurvival.dead or is_overboard or not is_instance_valid(station) or using_station or not is_physics_processing():
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
	var initial_inventory := player_inventory
	var player_id := initial_inventory.player_id if initial_inventory != null else &"player_1"
	player_inventory = VoyageState.get_player_inventory(player_id, initial_inventory)
	if player_inventory.player_id == &"player_1":
		VoyageSurvival.inventory = player_inventory
	VoyageSurvival.died.connect(_on_survival_death)

	# The prototype starts each crew member with the tool needed for its only
	# available station. Other acquisition systems can add this item later.
	var fishing_rod := ItemDatabase.get_item(&"fishing_rod")
	if fishing_rod != null and player_inventory.get_quantity(fishing_rod.id) == 0:
		player_inventory.add_item(fishing_rod)

func _physics_process(_delta: float) -> void:
	if VoyageSurvival.dead:
		return
	var moving_ship := get_parent() as ShipMotion
	if moving_ship and absf(moving_ship.speed) > 5.0:
		VoyageSurvival.spend_hunger(VoyageSurvival.sailing_cost_per_second * _delta)
	if using_station:
		velocity = Vector2.ZERO
		VoyageSurvival.spend_hunger(VoyageSurvival.station_cost_per_second * _delta)
		return
	# Read WASD / arrow keys; diagonal movement stays the same speed.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not direction.is_zero_approx():
		facing_direction = direction.normalized()
	if is_overboard:
		velocity = direction * swim_speed
		var next := global_position + velocity * _delta
		var ship := get_parent() as Ship
		if ship:
			var hull := ship.get_hull_polygon(ship.global_position, ship.global_rotation)
			if not Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([global_position, next]), hull).is_empty():
				return
		global_position = next
		if not direction.is_zero_approx():
			VoyageSurvival.spend_hunger(VoyageSurvival.walking_cost_per_second * _delta)
		return
	velocity = direction * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()
	if get_real_velocity().length() > 1.0:
		VoyageSurvival.spend_hunger(VoyageSurvival.walking_cost_per_second * _delta)

## Called by the hotbar when the player presses B with a selected item.
func request_drop_item(item_id: StringName) -> void:
	if VoyageSurvival.dead or using_station or get_tree().paused:
		return
	if is_overboard:
		show_feedback("Can't drop items in the water")
		return
	if player_inventory == null or player_inventory.get_quantity(item_id) < 1:
		show_feedback("No item selected")
		return
	if world_item_scene == null or get_parent() == null:
		push_warning("Cannot drop item without a world-item scene and parent.")
		return

	var dropped_item := world_item_scene.instantiate() as WorldItem
	if dropped_item == null:
		push_warning("World-item scene must instantiate a WorldItem.")
		return

	dropped_item.setup(item_id, 1, self)
	get_parent().add_child(dropped_item)
	dropped_item.global_position = global_position + facing_direction * drop_distance
	if not player_inventory.try_remove(item_id, 1):
		dropped_item.queue_free()
		return
	show_feedback("Dropped %s" % _get_item_name(item_id))


func show_feedback(text: String) -> void:
	feedback_requested.emit(text)


func _get_item_name(item_id: StringName) -> String:
	var item := ItemDatabase.get_item(item_id)
	return item.display_name if item != null else String(item_id)

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
	fishing_animating = false
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
	if VoyageSurvival.dead or using_station:
		return
	fishing_animating = true
	idle_sprite.hide()
	fishing_animation.show()
	fishing_animation.play(&"fishing_side")

func _on_fishing_animation_animation_finished() -> void:
	fishing_animating = false
	fishing_animation.hide()
	idle_sprite.show()

func _on_survival_death() -> void:
	var station := active_station
	active_station = null
	fishing_animating = false
	velocity = Vector2.ZERO
	if is_instance_valid(station):
		if station.has_method("release_control"):
			station.call("release_control")
		elif station.has_method("cancel_for_death"):
			station.call("cancel_for_death")
