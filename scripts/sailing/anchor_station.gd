class_name AnchorStation
extends ShipStation
## Presentation follows the existing authoritative deployed flag; no extra RPCs.
const WINCH := preload("res://assets/props/anchor_winch_pixel.tres")
const ANCHOR := preload("res://assets/props/anchor_pixel.tres")
const SPLASH := preload("res://scripts/visuals/water_splash.gd")
@export var water_offset := Vector2(-65, 18)
@export var stowed_offset := Vector2(-17, -2)
@export var winch_size := Vector2(29, 22)
@export var anchor_size := Vector2(18, 26)
@export_range(0.2, 3.0) var lower_seconds := 0.85
@export_range(0.2, 3.0) var raise_seconds := 1.15
var deployment := 0.0
var target_deployed := false
var splash_count := 0
var _splash_pending := false
var _observed_state := false
var _splash_sound: AudioStreamWAV
var _voice: AudioStreamPlayer2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deployment = 1.0 if is_instance_valid(ship) and ship.anchor_deployed else 0.0
	target_deployed = deployment > 0.0
	ship.anchor_changed.connect(_update_artwork)
	var synth := FishingAudio.new()
	_splash_sound = synth.synthesize("splash")
	synth.free()
	_voice = AudioStreamPlayer2D.new()
	_voice.bus = "Effects"
	_voice.stream = _splash_sound
	_voice.volume_db = -6.0
	_voice.pitch_scale = 0.7
	_voice.max_distance = 650
	add_child(_voice)

func try_take_control(crew: CharacterBody2D) -> bool:
	if not super.try_take_control(crew): return false
	ship.anchor_deployed = not ship.anchor_deployed
	release_control()
	return true

func _update_artwork(deployed: bool) -> void:
	target_deployed = deployed
	# Restores and the first join snapshot describe state, not a fresh splash.
	if not _observed_state:
		deployment = 1.0 if deployed else 0.0
		_splash_pending = false
	else:
		_splash_pending = deployed and deployment < 0.78
	queue_redraw()

func _process(delta: float) -> void:
	if not NetworkSession.online or NetworkSession.world_ready:
		_observed_state = true
	var destination := 1.0 if target_deployed else 0.0
	if is_equal_approx(deployment, destination): return
	deployment = move_toward(deployment, destination, delta / (lower_seconds if target_deployed else raise_seconds))
	if _splash_pending and deployment >= 0.78:
		_splash_pending = false
		_spawn_splash()
	queue_redraw()

func _spawn_splash() -> void:
	var splash := SPLASH.new()
	ship.add_child(splash)
	splash.global_position = to_global(water_offset)
	_voice.position = water_offset
	_voice.play()
	splash_count += 1

func anchor_point() -> Vector2:
	var flight := clampf(deployment / 0.78, 0.0, 1.0)
	var point := stowed_offset.lerp(water_offset, smoothstep(0.0, 1.0, flight))
	point.y -= sin(flight * PI) * 15.0
	point.y += maxf(0.0, deployment - 0.78) * 30.0
	return point

func _draw() -> void:
	var point := anchor_point()
	var ring := point + Vector2(0, -anchor_size.y * 0.42)
	if deployment >= 0.78: ring = water_offset
	var rope := PackedVector2Array([Vector2(0, -2)])
	var fairlead := Vector2(-24, -4)
	var bend := stowed_offset.lerp(fairlead, clampf(deployment * 4.0, 0, 1))
	rope.append(bend)
	for i in range(1, 13):
		var t := i / 12.0
		rope.append(bend.lerp(ring, t) + Vector2(0, sin(t * PI) * (4.0 + 3.0 * deployment)))
	PixelRope.draw(self, rope)
	draw_texture_rect(WINCH, Rect2(-winch_size * 0.5, winch_size), false)
	if deployment < 1.0:
		var fade := 1.0 - smoothstep(0.78, 1.0, deployment)
		draw_texture_rect(ANCHOR, Rect2(point - anchor_size * 0.5, anchor_size), false, Color(1, 1, 1, fade))
