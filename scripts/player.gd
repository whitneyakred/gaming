extends CharacterBody2D

signal feedback_requested(text: String)

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
@export var drop_distance: float = 32.0
@export var is_overboard: bool = false
@export var world_item_scene: PackedScene = preload("res://scenes/items/world_item.tscn")
var using_station: bool:
	get:
		return is_instance_valid(active_station)

# Stations claim movement through this small interface, without player-to-helm coupling.
var active_station: Node = null
var facing_direction := Vector2.DOWN

func try_use_station(station: Node) -> bool:
	if not is_instance_valid(station) or using_station or not is_physics_processing():
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
	if not direction.is_zero_approx():
		facing_direction = direction.normalized()
	velocity = direction * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()


## Called by the hotbar when the player presses B with a selected item.
func request_drop_item(item_id: StringName) -> void:
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

func play_fishing_animation() -> void:
	if using_station:
		return

	using_station = true
	idle_sprite.hide()
	fishing_animation.show()
	fishing_animation.play(&"fishing_side")

func _on_fishing_animation_animation_finished() -> void:
	fishing_animation.hide()
	idle_sprite.show()
	using_station = false
