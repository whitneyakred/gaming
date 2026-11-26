class_name SpyglassController
extends Node2D
## An independent temporary camera avoids fighting station/ship camera tracking.
@export_range(0.25, 0.9) var zoom_multiplier: float = 0.6
@export_range(0.0, 1200.0) var max_pan_distance: float = 450.0
@export_range(1.0, 6.0) var mouse_sensitivity: float = 3.0
@export_range(0.1, 1.5) var zoom_seconds: float = 0.65
var _blend: float = 0.0
var _pan: Vector2 = Vector2.ZERO
var active: bool = false
var audio: AudioStreamPlayer
var open_sound: AudioStreamWAV
var close_sound: AudioStreamWAV
var _previous_camera: Camera2D
var _scope_camera: Camera2D
@onready var service: InventoryService = get_parent() as InventoryService

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	audio = AudioStreamPlayer.new()
	audio.bus = "Effects"
	add_child(audio)
	open_sound = ActionAudio.make("scope_open")
	close_sound = ActionAudio.make("scope_close")
	_scope_camera = Camera2D.new()
	_scope_camera.enabled = false
	_scope_camera.position_smoothing_enabled = false
	_scope_camera.ignore_rotation = true
	add_child(_scope_camera)
	get_window().focus_exited.connect(func() -> void: stop(true))

func can_scout() -> bool:
	if service == null or service.hud == null or not service.can_handle_items():
		return false
	if service.hud.storage_open or service.hud.grill_open or get_viewport().gui_is_dragging():
		return false
	var index: int = service.hud.selected
	return index >= 0 and index < service.local_slots.size() and service.local_slots[index].get("id", &"") == &"spyglass"

func _unhandled_input(event: InputEvent) -> void:
	# GUI consumes clicks first, so selecting/dragging a slot cannot start scouting.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_scout():
		start()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Catch release even when the cursor is over a UI control.
	if active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop()

func start() -> void:
	if active or not can_scout():
		return
	if _blend <= 0.0:
		_previous_camera = get_viewport().get_camera_2d()
		if not is_instance_valid(_previous_camera):
			return
		_scope_camera.zoom = _previous_camera.zoom
		_scope_camera.global_position = _previous_camera.get_screen_center_position()
		_pan = Vector2.ZERO
	audio.stream = open_sound
	audio.play()
	active = true
	_scope_camera.enabled = true
	_scope_camera.make_current()
	_scope_camera.force_update_scroll()

func stop(immediate: bool = false) -> void:
	if active and is_instance_valid(audio):
		audio.stream = close_sound
		audio.play()
	active = false
	if immediate or _blend <= 0.0:
		_restore_camera()

func _restore_camera() -> void:
	_blend = 0.0
	_scope_camera.enabled = false
	if is_instance_valid(_previous_camera):
		_previous_camera.reset_smoothing()
		_previous_camera.make_current()
		_previous_camera.force_update_scroll()

func _process(delta: float) -> void:
	if get_tree().paused or MapState.map_open:
		stop(true)
		return
	if active and (not can_scout() or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		stop(get_tree().paused or MapState.map_open)
	if not active and _blend <= 0.0:
		return
	_update_view(delta)

func pan_for_mouse(mouse: Vector2, viewport_size: Vector2) -> Vector2:
	var half := viewport_size * 0.5
	var direction := (mouse - half) / half.max(Vector2.ONE) * mouse_sensitivity
	return direction.limit_length(1.0) * max_pan_distance

func _update_view(delta: float) -> void:
	if not is_instance_valid(_previous_camera):
		stop(true)
		return
	_blend = move_toward(_blend, 1.0 if active else 0.0, delta / zoom_seconds)
	var eased := smoothstep(0.0, 1.0, _blend)
	var desired_pan := pan_for_mouse(get_viewport().get_mouse_position(), get_viewport_rect().size)
	_pan = _pan.lerp(desired_pan, 1.0 - exp(-10.0 * delta))
	_scope_camera.zoom = _previous_camera.zoom.lerp(_previous_camera.zoom * zoom_multiplier, eased)
	_scope_camera.global_position = (_previous_camera.global_position + _previous_camera.offset).lerp(service.player.visual_position() + _pan, eased)
	_scope_camera.force_update_scroll()
	if not active and _blend <= 0.0:
		_restore_camera()

func _exit_tree() -> void:
	stop(true)
