class_name SharedChest
extends Area2D

## A ship container backed by one VoyageState inventory.  Any future player
## that opens this chest ID receives the same shared contents.
@export var chest_id: StringName = &"ship_supply_chest"
@export_range(1, 99, 1) var slot_capacity: int = 12
@export var inventory_ui_scene: PackedScene = preload("res://scenes/ui/chest_inventory.tscn")

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: CharacterBody2D
var _inventory_ui: Control


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _inventory_ui != null and _inventory_ui.visible:
		return
	if _player_in_range == null or _player_in_range.using_station:
		return
	if event.is_action_pressed(&"interact") and not event.is_echo():
		open_for(_player_in_range)
		get_viewport().set_input_as_handled()


func open_for(player: CharacterBody2D) -> void:
	if player == null or not player.try_use_station(self):
		return
	var player_inventory: PlayerInventory = player.player_inventory as PlayerInventory
	var chest_inventory: PlayerInventory = VoyageState.get_shared_inventory(chest_id, slot_capacity)
	if player_inventory == null or chest_inventory == null:
		player.leave_station(self)
		return
	if _inventory_ui == null:
		_inventory_ui = inventory_ui_scene.instantiate() as Control
		if _inventory_ui == null:
			push_warning("SharedChest inventory_ui_scene must instantiate a Control.")
			player.leave_station(self)
			return
		# The Ship can be instanced beneath Main, so current_scene is not
		# necessarily the node that owns this chest.  Its HUD is a sibling of
		# the chest under the Ship scene.
		var ship_root := get_parent()
		var hud: Node = ship_root.get_node_or_null(^"HUD") if ship_root != null else null
		if hud == null:
			push_warning("SharedChest could not find the Ship HUD.")
			_inventory_ui.queue_free()
			_inventory_ui = null
			player.leave_station(self)
			return
		hud.add_child(_inventory_ui)
		_inventory_ui.connect(&"close_requested", _close_for_player)
	_inventory_ui.call(&"open_for", player_inventory, chest_inventory)
	prompt_label.hide()


func _close_for_player() -> void:
	if is_instance_valid(_player_in_range):
		_player_in_range.leave_station(self)
	_update_prompt()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = body
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		if _inventory_ui != null and _inventory_ui.visible:
			_inventory_ui.call(&"close")
		_player_in_range = null
		prompt_label.hide()


func _update_prompt() -> void:
	prompt_label.visible = _player_in_range != null and (_inventory_ui == null or not _inventory_ui.visible)
