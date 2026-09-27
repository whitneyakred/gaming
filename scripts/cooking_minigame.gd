extends Control

@export var marker_speed: float = 280.0
@onready var result_label: Label = $GamePanel/ResultLabel
@onready var timing_bar: ColorRect = $GamePanel/TimingBar
@onready var marker: ColorRect = $GamePanel/TimingBar/Marker
@onready var target_zone: ColorRect = $GamePanel/TimingBar/TargetZone


var direction: float = 1.0
var stopped: bool = false
var attempts: int = 0
var hits: int = 0


func _process(delta: float) -> void:
	# Skip movement after the player presses Space.
	if stopped:
		return

	marker.position.x += marker_speed * direction * delta

	var right_edge: float = timing_bar.size.x - marker.size.x

	if marker.position.x >= right_edge:
		marker.position.x = right_edge
		direction = -1.0
	elif marker.position.x <= 0.0:
		marker.position.x = 0.0
		direction = 1.0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_SPACE:
			if stopped:
				return

			get_viewport().set_input_as_handled()
			stopped = true
			attempts += 1

			var marker_center: float = marker.position.x + marker.size.x / 2.0
			var target_start: float = target_zone.position.x
			var target_end: float = target_start + target_zone.size.x

			if marker_center >= target_start and marker_center <= target_end:
				hits += 1
				result_label.text = "Perfect timing! (%d/3)" % attempts
			else:
				result_label.text = "Missed! (%d/3)" % attempts

			await get_tree().create_timer(1.0).timeout

			if attempts >= 3:
				show_final_result()
			else:
				marker.position.x = 0.0
				direction = 1.0
				result_label.text = "Attempt %d/3 — Press Space!" % (attempts + 1)
				stopped = false


func show_final_result() -> void:
	if hits == 3:
		result_label.text = "Perfect fish! 3/3 hits"
	elif hits >= 1:
		result_label.text = "Okay fish! %d/3 hits" % hits
	else:
		result_label.text = "Burnt fish! 0/3 hits"		
