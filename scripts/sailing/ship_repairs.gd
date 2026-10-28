extends Node2D
## Temporary unlimited materials; collected salvage is a separate voyage tally.
signal hole_opened(slot: int)
signal hole_repaired(slot: int)
@export var minimum_interval: float = 35.0
@export var maximum_interval: float = 60.0
@export_range(1, 5) var maximum_holes: int = 3
@export var repair_distance: float = 34.0
@export var hole_positions: PackedVector2Array = PackedVector2Array([Vector2(-25, -150), Vector2(26, -85), Vector2(-32, 5), Vector2(32, 150), Vector2(-26, 180)])
var _rng := RandomNumberGenerator.new()
var _nearest: int = -1
var _label: Label
@onready var ship: Ship = get_parent()

func _ready() -> void:
	_label = Label.new()
	ship.get_node("HUD").add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_label.position = Vector2(18, 65)
	_label.anchor_right = 1.0
	_label.offset_right = -18
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1

func _physics_process(delta: float) -> void:
	if ship.stations_enabled and ship._state != Ship.State.ROWING:
		VoyageState.next_hole_seconds -= delta
		if VoyageState.next_hole_seconds <= 0:
			open_hole()
			VoyageState.next_hole_seconds = _rng.randf_range(minimum_interval, maxf(minimum_interval, maximum_interval))
	_nearest = nearest_hole()
	_label.text = "Wood collected: %d | Repairs: unlimited wood\nOpen holes: %d/%d" % [VoyageState.salvaged_wood, VoyageState.ship_holes.size(), maximum_holes]
	if _nearest >= 0:
		_label.text += " | E / Space: repair"
	queue_redraw()

func open_hole() -> int:
	if VoyageState.ship_holes.size() >= maximum_holes:
		return -1
	var available: Array[int] = []
	for i in hole_positions.size():
		if not VoyageState.ship_holes.has(i):
			available.append(i)
	if available.is_empty():
		return -1
	var slot := available[_rng.randi_range(0, available.size() - 1)]
	VoyageState.ship_holes.append(slot)
	hole_opened.emit(slot)
	return slot

func nearest_hole() -> int:
	if ship.player.is_overboard or ship.player.using_station or not ship.stations_enabled:
		return -1
	var nearest := -1
	var distance := repair_distance
	for slot in VoyageState.ship_holes:
		var d := ship.player.global_position.distance_to(to_global(hole_positions[slot]))
		if d <= distance:
			distance = d
			nearest = slot
	return nearest

func repair_nearest() -> bool:
	var slot := nearest_hole()
	if slot < 0:
		return false
	VoyageState.ship_holes.erase(slot)
	hole_repaired.emit(slot)
	queue_redraw()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and repair_nearest():
		get_viewport().set_input_as_handled()

func _draw() -> void:
	for slot in VoyageState.ship_holes:
		var point := hole_positions[slot]
		draw_circle(point, 14, Color("513421"))
		draw_circle(point, 10, Color("162c41"))
		draw_line(point + Vector2(-6, 2), point + Vector2(5, 2), Color("5f84a8"), 3)
		if slot == _nearest:
			draw_arc(point, 18, 0, TAU, 24, Color("eed48a"), 2)
