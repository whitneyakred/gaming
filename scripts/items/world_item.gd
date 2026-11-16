class_name WorldItem
extends Area2D

## A pickup that represents one or more catalog items in the active world.
## It only leaves the world after the receiving inventory accepts every item.
signal picked_up(item_id: StringName, quantity: int, picker: Node2D)

@export var item_id: StringName
@export_range(1, 999, 1) var quantity: int = 1

var _ignored_body: Node2D
@onready var marker: Polygon2D = get_node_or_null("Marker") as Polygon2D
@onready var item_icon: Sprite2D = get_node_or_null("ItemIcon") as Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	assert(not item_id.is_empty(), "WorldItem needs an item id.")
	assert(ItemDatabase.get_item(item_id) != null, "Unknown item id: %s" % item_id)
	_update_visual()


## Configures a newly dropped pickup before it enters the scene tree.
func setup(new_item_id: StringName, new_quantity: int = 1, ignored_body: Node2D = null) -> void:
	item_id = new_item_id
	quantity = new_quantity
	_ignored_body = ignored_body


func _on_body_entered(body: Node2D) -> void:
	if body == _ignored_body or not body is CharacterBody2D:
		return

	var inventory := body.get("player_inventory") as PlayerInventory
	if inventory == null:
		return

	if not inventory.try_add(item_id, quantity):
		_show_feedback(body, "Inventory full")
		return

	picked_up.emit(item_id, quantity, body)
	queue_free()


func _on_body_exited(body: Node2D) -> void:
	if body == _ignored_body:
		_ignored_body = null


func _show_feedback(body: Node2D, text: String) -> void:
	if body.has_method("show_feedback"):
		body.call("show_feedback", text)


## Uses the same texture assigned to the item in the inventory hotbar.
## The simple marker remains only for catalog items that do not have an icon yet.
func _update_visual() -> void:
	if item_icon == null:
		return

	var item := ItemDatabase.get_item(item_id)
	if item == null or item.icon == null:
		item_icon.hide()
		if marker != null:
			marker.show()
		return

	item_icon.texture = item.icon
	var icon_size := item.icon.get_size()
	var largest_dimension := maxf(float(icon_size.x), float(icon_size.y))
	item_icon.scale = Vector2.ONE * (24.0 / largest_dimension) if largest_dimension > 24.0 else Vector2.ONE
	item_icon.show()
	if marker != null:
		marker.hide()
