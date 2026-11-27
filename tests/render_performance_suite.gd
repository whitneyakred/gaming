extends Node
var samples: Array[float] = []
var collecting := false
var phase_clock := 0.0
var previous_usec := 0
var results: Dictionary = {}
func _ready() -> void:
	process_priority = 200
	run.call_deferred()
func _process(delta: float) -> void:
	if not collecting: return
	var now := Time.get_ticks_usec()
	if previous_usec > 0: samples.append((now - previous_usec) / 1000.0)
	previous_usec = now
	phase_clock += delta
	var right := fmod(phase_clock, 0.8) < 0.4
	Input.action_press("move_right" if right else "move_left")
	Input.action_release("move_left" if right else "move_right")
func measure(label: String) -> void:
	await get_tree().create_timer(1.0).timeout
	samples.clear()
	previous_usec = 0
	phase_clock = 0
	collecting = true
	await get_tree().create_timer(5.0).timeout
	collecting = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	samples.sort()
	var total := 0.0
	for value in samples: total += value
	results[label] = {"frames":samples.size(), "average_ms":total / samples.size(), "p95_ms":samples[int(samples.size() * 0.95)], "max_ms":samples.back()}
	print("RENDER ", label, ": ", results[label])
func run() -> void:
	GameWindow.set_preference("pause_unfocused", false)
	GameWindow.set_preference("fullscreen", false)
	get_tree().change_scene_to_file("res://scenes/ship.tscn")
	await get_tree().scene_changed
	get_window().size = Vector2i(1280, 720)
	var ship: Ship = get_tree().current_scene
	ship.anchor_deployed = true
	ship.player.position = Vector2(-25, 90)
	await measure("deck")
	var manager: IslandChallenges = ship.get_node("IslandChallenges")
	var island: WorldIsland
	for candidate in ship.get_islands():
		if not candidate is QuestIsland:
			island = candidate
			break
	ship.player.set_overboard(true)
	ship.player.global_position = island.get_node("MinigameTotem").global_position
	ship.player.update_land(true)
	await measure("shore")
	ship.player.global_position = island.get_node("MinigameTotem").global_position
	assert(manager.try_start(1, str(island.name)))
	await measure("minigame")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://output/movement-minigame.png")
	var report := FileAccess.open("res://output/render-performance.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(results, "\t"))
	manager._finished_local(false)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

