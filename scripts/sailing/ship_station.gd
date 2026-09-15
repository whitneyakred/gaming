class_name ShipStation
extends Node2D
## Local input adapter. Ownership is explicit so another station can share the player API.

signal operator_changed(crew: CharacterBody2D)

@export var ship: ShipMotion
@export var local_player: CharacterBody2D
@export_range(8.0, 100.0) var interaction_distance: float = 46.0
@export_range(8.0, 200.0) var release_distance: float = 72.0

var operator: CharacterBody2D = null

func can_interact(crew: CharacterBody2D) -> bool:
	return is_instance_valid(crew) and global_position.distance_to(crew.global_position) <= interaction_distance

func try_take_control(crew: CharacterBody2D) -> bool:
	if not is_instance_valid(ship) or is_instance_valid(operator) or not can_interact(crew):
		return false
	if not crew.has_method("try_use_station") or not crew.call("try_use_station", self):
		return false
	operator = crew
	operator.tree_exiting.connect(release_control, CONNECT_ONE_SHOT)
	_control_changed()
	operator_changed.emit(operator)
	return true

func release_control() -> void:
	if is_instance_valid(operator):
		if operator.tree_exiting.is_connected(release_control):
			operator.tree_exiting.disconnect(release_control)
		operator.call("leave_station", self)
	operator = null
	if is_instance_valid(ship):
		_control_changed()
	operator_changed.emit(null)

func _exit_tree() -> void:
	release_control()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("station_interact") and not event.is_echo():
		if is_instance_valid(operator) and operator == local_player:
			release_control()
			get_viewport().set_input_as_handled()
		elif is_instance_valid(local_player) and try_take_control(local_player):
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(operator):
		return
	if not is_instance_valid(ship):
		release_control()
		return
	if global_position.distance_to(operator.global_position) > maxf(release_distance, interaction_distance):
		release_control()
		return
	if operator != local_player:
		return
	_apply_controls(delta)

func _control_changed() -> void:
	pass

func _apply_controls(_delta: float) -> void:
	pass


