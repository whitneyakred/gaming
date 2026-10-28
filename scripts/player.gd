extends CharacterBody2D

# Exposed as Walk Speed in the Inspector (pixels per second).
@export var walk_speed: float = 145.0
var using_station: bool:
	get:
		return is_instance_valid(active_station) or fishing_animating

# Stations claim movement through this small interface, without player-to-helm coupling.
var active_station: Node = null
var fishing_animating: bool = false

func try_use_station(station: Node) -> bool:
	if VoyageSurvival.dead or not is_instance_valid(station) or using_station or not is_physics_processing():
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
	player_inventory = VoyageSurvival.inventory
	VoyageSurvival.died.connect(_on_survival_death)

func _physics_process(delta: float) -> void:
	if VoyageSurvival.dead:
		return
	var ship := get_parent() as ShipMotion
	if ship and absf(ship.speed) > 5.0:
		VoyageSurvival.spend_hunger(VoyageSurvival.sailing_cost_per_second * delta)
	if using_station:
		velocity = Vector2.ZERO
		VoyageSurvival.spend_hunger(VoyageSurvival.station_cost_per_second * delta)
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	move_and_slide()
	if get_real_velocity().length() > 1.0:
		VoyageSurvival.spend_hunger(VoyageSurvival.walking_cost_per_second * delta)

func _on_survival_death() -> void:
	var station := active_station
	active_station = null
	velocity = Vector2.ZERO
	fishing_animating = false
	if is_instance_valid(station):
		if station.has_method("release_control"):
			station.call("release_control")
		elif station.has_method("cancel_for_death"):
			station.call("cancel_for_death")

func play_fishing_animation() -> void:
	if using_station:
		return

	fishing_animating = true
	idle_sprite.hide()
	fishing_animation.show()
	fishing_animation.play(&"fishing_side")

func _on_fishing_animation_animation_finished() -> void:
	fishing_animation.hide()
	idle_sprite.show()
	fishing_animating = false
