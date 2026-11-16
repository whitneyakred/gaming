extends Node
## UC-PROG-pause-game checks, one function per row of the design's test list
## (docs/design/PROG.md, "Pause-game ... (single-player)"). Started by
## tests/pause_game.gd.

var failures: int = 0


func _ready() -> void:
	# The suite must keep running while it pauses the game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame


func _screen_visible() -> bool:
	return (PauseMenu.get_node("Screen") as Control).visible


func _resume_button() -> Button:
	return PauseMenu.get_node("Screen/Center/Box/ResumeButton") as Button


# Presses and releases the P key, as the player would.
func _press_p(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_P
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	await _frames(2)
	if echo:
		return
	event = InputEventKey.new()
	event.physical_keycode = KEY_P
	Input.parse_input_event(event)
	await _frames(2)


# Real time passes while the game may be paused. A SceneTree timer created
# with the default process_always = true keeps counting during pause.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _open(path: String) -> Node:
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await _frames(2)
	return get_tree().current_scene


func _run() -> void:
	get_tree().create_timer(120.0).timeout.connect(func() -> void:
		push_error("Pause test timed out")
		get_tree().quit(1))

	await _test_repeated_calls()
	await _test_pause_freezes_ship()
	await _test_island_timer_frozen()
	await _test_island_exit_waits_for_resume()

	if PauseMenu.is_paused():
		PauseMenu.resume()
	print("Pause game: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


# Row "Pause-game: repeated calls" (unit): pause() while paused and resume()
# while running change nothing and emit nothing.
func _test_repeated_calls() -> void:
	var emitted: Array[bool] = []
	var record := func(is_paused: bool) -> void: emitted.append(is_paused)
	PauseMenu.pause_changed.connect(record)

	_check(not PauseMenu.is_paused() and not get_tree().paused, "The game must start unpaused")
	_check(not _screen_visible(), "The pause screen must start hidden")

	PauseMenu.resume()
	_check(not get_tree().paused and emitted.is_empty(), "resume() while running must change nothing and emit nothing")

	PauseMenu.pause()
	_check(get_tree().paused and PauseMenu.is_paused(), "pause() must pause the tree")
	_check(_screen_visible(), "pause() must show the pause screen")
	_check(emitted == [true], "pause() must emit pause_changed(true) once")

	PauseMenu.pause()
	_check(get_tree().paused and _screen_visible(), "pause() while paused must leave the game paused")
	_check(emitted == [true], "pause() while paused must emit nothing")

	PauseMenu.resume()
	_check(not get_tree().paused and not _screen_visible(), "resume() must unpause the tree and hide the screen")
	_check(emitted == [true, false], "resume() must emit pause_changed(false) once")

	PauseMenu.resume()
	_check(emitted == [true, false], "resume() while running must emit nothing")

	PauseMenu.pause_changed.disconnect(record)


# Rows "UC-PROG-pause-game main: pause", "resume by button" and
# "resume by key" (integration), on the sailing ship.
func _test_pause_freezes_ship() -> void:
	var main := await _open("res://scenes/main.tscn")
	var ship := main.get_node("Ship") as Ship
	var player := ship.player
	# Fast wind shifts and full sail, so a running game visibly changes both.
	ship.changing_wind_enabled = true
	ship.wind_change_interval = 0.1
	ship.wind_response = 5.0
	ship._wind_change_left = 0.0
	ship.set_sail_level(3)
	await _wait(1.0)
	_check(ship.speed > 0.0, "Setup: the ship must be under way before pausing")

	# Steps 1-3: P pauses the tree and shows the pause screen.
	await _press_p()
	_check(get_tree().paused and PauseMenu.is_paused(), "P must pause the game")
	_check(_screen_visible(), "Pausing must show the pause screen")

	var frozen_position := ship.global_position
	var frozen_rotation := ship.global_rotation
	var frozen_speed := ship.speed
	var frozen_wind := ship.wind_velocity
	var frozen_player := player.global_position
	# Movement input while paused must not move the player now or later.
	Input.action_press("move_right")
	for frame in range(90):
		await get_tree().physics_frame
	Input.action_release("move_right")
	await _press_p(true)
	_check(get_tree().paused, "Holding P (an echo) must not resume")
	_check(ship.global_position == frozen_position and ship.global_rotation == frozen_rotation,
		"The ship must not move while paused")
	_check(ship.speed == frozen_speed, "The ship's speed must not change while paused")
	_check(ship.wind_velocity == frozen_wind, "The wind must not change while paused")
	_check(player.global_position == frozen_player, "The player must not move while paused")

	# Steps 4-5 by button: Resume unpauses and the ship carries on from the
	# same values (POST-1).
	_resume_button().pressed.emit()
	_check(not get_tree().paused and not _screen_visible(), "Resume must unpause the game and hide the pause screen")
	_check(ship.speed == frozen_speed and ship.wind_velocity == frozen_wind,
		"Resuming must keep the frozen speed and wind")
	await _frames(10)
	_check(ship.global_position != frozen_position, "The ship must sail on after Resume")
	_check(ship.wind_velocity != frozen_wind, "The wind must change again after Resume")

	# Step 4 by key: P while paused resumes.
	PauseMenu.pause()
	await _frames(2)
	await _press_p()
	_check(not get_tree().paused and not _screen_visible(), "P while paused must resume")


# Row "Pause-game: island timer frozen" (integration).
func _test_island_timer_frozen() -> void:
	var island := (await _open("res://scenes/islands/crab_cove.tscn")) as IslandGame
	await _wait(0.5)
	_check(island.time_remaining < island.time_limit_seconds, "Setup: the island timer must be counting down")

	PauseMenu.pause()
	var frozen_time := island.time_remaining
	await _wait(1.5)
	_check(island.time_remaining == frozen_time, "The island's time left must not change while paused")

	PauseMenu.resume()
	await _wait(0.5)
	_check(island.time_remaining < frozen_time, "The island timer must count down again after resume")


# Not a design test-list row: checks the timer fix (create_timer(..., false))
# on the island's win delay, so a pause just after winning does not leave the
# island behind the pause screen.
func _test_island_exit_waits_for_resume() -> void:
	var island := (await _open("res://scenes/islands/crab_cove.tscn")) as IslandGame
	island.win()
	PauseMenu.pause()
	await _wait(island.win_delay_seconds + 1.0)
	_check(get_tree().current_scene == island, "Winning must not row back to the ship while paused")

	PauseMenu.resume()
	await _wait(island.win_delay_seconds + 1.0)
	_check(get_tree().current_scene is Ship, "After resume, winning must row back to the ship")
