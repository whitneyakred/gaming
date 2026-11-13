class_name CrabCove
extends IslandGame

## Crab Cove: herd the crabs into the pen.
## Crabs run away from you, so walk around behind them to push them toward
## the pen (the roped square). Each crab you pen goes into your bag as
## Crab Meat. Pen them all, then get back to the rowboat.
##
## Scene setup: Marker2D children of CrabSpawns are where crabs start, and
## the Pen marker is the pen's centre.

@export_group("Crabs")
@export var spawns_path: NodePath = ^"World/CrabSpawns"
@export var pen_path: NodePath = ^"World/Pen"
@export var pen_size: Vector2 = Vector2(120, 90)
@export var reward_item_id: StringName = &"crab_meat"
@export var crab_flee_speed: float = 125.0

var crabs: Array[IslandCrab] = []
var penned_count: int = 0

var _pen: Node2D


func _setup_game() -> void:
	_pen = get_node_or_null(pen_path) as Node2D
	assert(_pen != null, "CrabCove needs a Pen marker.")
	_pen.draw.connect(_draw_pen)
	_pen.queue_redraw()

	var spawns := get_node_or_null(spawns_path)
	assert(spawns != null, "CrabCove needs Marker2D children under CrabSpawns.")
	for marker in spawns.get_children():
		if marker is Node2D:
			var crab := IslandCrab.new()
			crab.name = "Crab%d" % (crabs.size() + 1)
			crab.flee_speed = crab_flee_speed
			crab.threat = player
			crab.position = marker.position
			spawns.add_child(crab)
			crabs.append(crab)


func _game_process(_delta: float) -> void:
	var pen_rect := get_pen_rect()
	for crab in crabs:
		if not crab.penned and pen_rect.has_point(crab.global_position):
			_pen_crab(crab)


func get_pen_rect() -> Rect2:
	if _pen == null:
		return Rect2()
	return Rect2(_pen.global_position - pen_size / 2.0, pen_size)


func _pen_crab(crab: IslandCrab) -> void:
	crab.penned = true
	penned_count += 1
	# Line penned crabs up inside the pen so they're easy to count.
	var columns := 4
	var slot := Vector2((penned_count - 1) % columns, floori((penned_count - 1) / float(columns)))
	var start := get_pen_rect().position + Vector2(22, 24)
	var tween := create_tween()
	tween.tween_property(crab, "global_position", start + slot * Vector2(25, 30), 0.25)
	give_item(reward_item_id, 1)
	refresh_hud()
	if penned_count >= crabs.size():
		show_message("All crabs penned! Back to the rowboat!", 2.0)


func _get_objective_text() -> String:
	if penned_count >= crabs.size() and not crabs.is_empty():
		return "All crabs penned! Head to the rowboat."
	return "Crabs penned: %d / %d" % [penned_count, crabs.size()]


func _is_objective_complete() -> bool:
	return penned_count >= crabs.size()


func _get_incomplete_message() -> String:
	return "Pen all the crabs first!"


func _draw_pen() -> void:
	var half := pen_size / 2.0
	var rect := Rect2(-half, pen_size)
	_pen.draw_rect(rect, Color(0.85, 0.75, 0.5, 0.35))
	var rope := Color8(150, 110, 60)
	_pen.draw_rect(rect, rope, false, 3.0)
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		_pen.draw_circle(corner, 5.0, rope.darkened(0.4))
