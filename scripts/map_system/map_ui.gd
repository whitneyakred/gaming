extends CanvasLayer


func _ready() -> void:
	close_map()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("toggle_map"):
		if MapState.map_open:
			close_map()
		else:
			open_map()

		get_viewport().set_input_as_handled()
		return

	if not MapState.map_open:
		return

	if event.is_action_pressed("ui_cancel"):
		close_map()
		get_viewport().set_input_as_handled()

	elif event is InputEventKey:
		if event.pressed and event.physical_keycode == KEY_C:
			MapState.clear_destination()
			get_viewport().set_input_as_handled()

func open_map() -> void:
	MapState.map_open = true
	show()

func close_map() -> void:
	MapState.map_open = false
	hide()

func _exit_tree() -> void:
	MapState.map_open = false
