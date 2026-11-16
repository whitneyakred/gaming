class_name FireflyHollow
extends IslandGame

## Firefly Hollow: catch fireflies in the dark.
## It's night, and you can only see a small circle around you. Fireflies
## drift around the hollow and blink on and off. Press E next to one while
## it's lit to net it; swish at a dark one and it slips away. Catch enough
## to fill a Glow Jar, then find your way back to the rowboat.
##
## Scene setup: the Meadow marker is the centre of the area the fireflies
## fly around in (Meadow Size wide and tall).

@export_group("Fireflies")
@export var meadow_path: NodePath = ^"World/Meadow"
@export var meadow_size: Vector2 = Vector2(400, 280)
@export var firefly_count: int = 10
@export var fireflies_needed: int = 6
@export var reward_item_id: StringName = &"glow_jar"
@export var drift_speed: float = 32.0
## Seconds a firefly stays lit.
@export var lit_seconds: float = 1.4
## A dark spell lasts between these many seconds.
@export var dark_seconds_min: float = 1.4
@export var dark_seconds_max: float = 3.4
@export var reach: float = 42.0

@export_group("Darkness")
@export var light_radius: float = 105.0
@export var light_softness: float = 50.0
@export_range(0.0, 1.0) var darkness: float = 0.9

const DARKNESS_SHADER := """
shader_type canvas_item;
uniform float radius = 105.0;
uniform float softness = 50.0;
uniform float strength = 0.9;
uniform vec2 rect_size = vec2(3000.0, 3000.0);
void fragment() {
	float d = distance(UV * rect_size, rect_size * 0.5);
	COLOR = vec4(0.01, 0.02, 0.08, smoothstep(radius, radius + softness, d) * strength);
}
"""
const DARKNESS_SIZE: float = 3000.0

var caught_count: int = 0
var jar_filled: bool = false
## Each firefly: {pos: Vector2, vel: Vector2, lit: bool, timer: float}
var fireflies: Array[Dictionary] = []

var _meadow: Node2D
var _bodies: Node2D    # drawn under the darkness: only seen in your light
var _glows: Node2D     # drawn over the darkness: seen from anywhere
var _darkness: Node2D
var _time: float = 0.0


func _setup_game() -> void:
	_meadow = get_node_or_null(meadow_path) as Node2D
	assert(_meadow != null, "FireflyHollow needs a Meadow marker.")
	fireflies_needed = mini(fireflies_needed, firefly_count)
	var area := _meadow_rect()
	for i in firefly_count:
		var pos := area.position + Vector2(randf() * area.size.x, randf() * area.size.y)
		fireflies.append({"pos": pos, "vel": Vector2.from_angle(randf() * TAU) * drift_speed,
				"lit": randf() < 0.4, "timer": randf_range(0.2, dark_seconds_max)})

	_bodies = Node2D.new()
	_bodies.name = "Fireflies"
	_bodies.z_index = 10
	_bodies.draw.connect(_draw_bodies)
	add_child(_bodies)
	_glows = Node2D.new()
	_glows.name = "FireflyGlow"
	_glows.z_index = 60
	_glows.draw.connect(_draw_glows)
	add_child(_glows)
	_build_darkness()


func _meadow_rect() -> Rect2:
	return Rect2(_meadow.global_position - meadow_size / 2.0, meadow_size)


func _game_process(delta: float) -> void:
	_time += delta
	var area := _meadow_rect()
	for fly in fireflies:
		var pos: Vector2 = fly["pos"]
		var vel: Vector2 = fly["vel"]
		vel = vel.rotated(randf_range(-2.0, 2.0) * delta)
		pos += vel * delta
		if pos.x < area.position.x or pos.x > area.end.x:
			vel.x = -vel.x
		if pos.y < area.position.y or pos.y > area.end.y:
			vel.y = -vel.y
		fly["pos"] = pos.clamp(area.position, area.end)
		fly["vel"] = vel
		fly["timer"] = float(fly["timer"]) - delta
		if float(fly["timer"]) <= 0.0:
			var lit: bool = not fly["lit"]
			fly["lit"] = lit
			fly["timer"] = lit_seconds if lit else randf_range(dark_seconds_min, dark_seconds_max)
	if player:
		_darkness.global_position = player.global_position
		set_prompt("Press E to net it!" if not jar_filled and _nearest_firefly(true) >= 0 else "")
	_bodies.queue_redraw()
	_glows.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not is_running() or jar_filled or not event.is_action_pressed("interact") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	swing_net()


## Swings the net at the nearest firefly. Returns true if one was caught.
func swing_net() -> bool:
	var lit_fly := _nearest_firefly(true)
	if lit_fly >= 0:
		_catch(lit_fly)
		return true
	var dark_fly := _nearest_firefly(false)
	if dark_fly >= 0:
		# It slips away while it's dark.
		var fly := fireflies[dark_fly]
		var pos: Vector2 = fly["pos"]
		fly["vel"] = (pos - player.global_position).normalized() * drift_speed * 2.5
		show_message("Swish! It slipped away in the dark.", 0.8)
	else:
		show_message("Swish!", 0.4)
	return false


func _catch(index: int) -> void:
	fireflies.remove_at(index)
	caught_count += 1
	refresh_hud()
	if caught_count >= fireflies_needed:
		jar_filled = true
		set_prompt("")
		give_item(reward_item_id, 1)
		show_message("The jar is glowing! Find your way back to the rowboat.", 2.5)
	else:
		show_message("Got one!", 0.6)


func _nearest_firefly(want_lit: bool) -> int:
	if player == null:
		return -1
	var best := -1
	var best_distance := reach
	for i in fireflies.size():
		if bool(fireflies[i]["lit"]) != want_lit:
			continue
		var distance := player.global_position.distance_to(fireflies[i]["pos"])
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _build_darkness() -> void:
	_darkness = Node2D.new()
	_darkness.name = "Darkness"
	_darkness.z_index = 50
	var cover := ColorRect.new()
	cover.size = Vector2.ONE * DARKNESS_SIZE
	cover.position = -cover.size / 2.0
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = DARKNESS_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("radius", light_radius)
	mat.set_shader_parameter("softness", light_softness)
	mat.set_shader_parameter("rect_size", cover.size)
	mat.set_shader_parameter("strength", darkness)
	cover.material = mat
	_darkness.add_child(cover)
	add_child(_darkness)
	if player:
		_darkness.global_position = player.global_position


func _get_objective_text() -> String:
	if jar_filled:
		return "Jar full! Find your way back to the rowboat."
	return "Fireflies caught: %d / %d" % [caught_count, fireflies_needed]


func _is_objective_complete() -> bool:
	return jar_filled


func _get_incomplete_message() -> String:
	return "Catch %d fireflies first!" % fireflies_needed


func _draw_bodies() -> void:
	for fly in fireflies:
		var pos: Vector2 = fly["pos"]
		var wing := 0.6 + 0.4 * sin(_time * 30.0 + pos.x)
		_bodies.draw_circle(pos + Vector2(-3, -2), 2.5 * wing, Color(0.85, 0.9, 1.0, 0.6))
		_bodies.draw_circle(pos + Vector2(3, -2), 2.5 * wing, Color(0.85, 0.9, 1.0, 0.6))
		_bodies.draw_circle(pos, 2.5, Color8(40, 34, 30))


func _draw_glows() -> void:
	for fly in fireflies:
		if not fly["lit"]:
			continue
		var pos: Vector2 = fly["pos"]
		var timer: float = fly["timer"]
		# Fade in and out at the ends of a blink.
		var fade := clampf(minf(timer, lit_seconds - timer) / 0.25, 0.25, 1.0)
		_glows.draw_circle(pos, 16.0, Color(0.85, 1.0, 0.35, 0.18 * fade))
		_glows.draw_circle(pos, 8.0, Color(0.9, 1.0, 0.45, 0.45 * fade))
		_glows.draw_circle(pos + Vector2(0, 2), 3.0, Color(1.0, 1.0, 0.7, fade))
	if jar_filled and player:
		var at := player.global_position + Vector2(14, -10)
		_glows.draw_circle(at, 10.0, Color(0.85, 1.0, 0.35, 0.35))
		_glows.draw_rect(Rect2(at + Vector2(-5, -6), Vector2(10, 12)), Color(0.9, 1.0, 0.5, 0.8))
