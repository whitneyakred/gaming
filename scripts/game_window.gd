extends Node
## Keep world pixels the same size as the window grows. F11 toggles fullscreen.
var _previous_mode: Window.Mode = Window.MODE_MAXIMIZED

func _ready() -> void:
	# Window controls remain available while the new pause menu freezes gameplay.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var window := get_window()
		if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			window.mode = _previous_mode
		else:
			_previous_mode = window.mode
			window.mode = Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()
