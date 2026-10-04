extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0

## Each player owns a separate inventory so station checks remain player-specific
## when local multiplayer is added later.
@export var player_inventory: PlayerInventory

@onready var idle_sprite: Sprite2D = $Sprite2D
@onready var fishing_animation: AnimatedSprite2D = $FishingAnimation

var is_performing_action: bool = false

func _ready() -> void:
	if player_inventory == null:
		player_inventory = PlayerInventory.new()

	# The prototype starts each crew member with the tool needed for its only
	# available station. Other acquisition systems can add this item later.
	var fishing_rod := ItemDatabase.get_item(&"fishing_rod")
	if fishing_rod != null and player_inventory.get_quantity(fishing_rod.id) == 0:
		player_inventory.add_item(fishing_rod)

func _physics_process(_delta: float) -> void:
	if is_performing_action:
		velocity = Vector2.ZERO
		return

	# Read WASD / arrow keys; diagonal movement stays the same speed.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	# Godot moves the body and handles collisions with the deck boundary.
	move_and_slide()

func play_fishing_animation() -> void:
	if is_performing_action:
		return

	is_performing_action = true
	idle_sprite.hide()
	fishing_animation.show()
	fishing_animation.play(&"fishing_side")

func _on_fishing_animation_animation_finished() -> void:
	fishing_animation.hide()
	idle_sprite.show()
	is_performing_action = false
