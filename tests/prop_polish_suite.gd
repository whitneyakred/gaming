extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	var sweep := PropCollision.new()
	sweep.insert("rock",Vector2.ZERO,23,10)
	check(sweep.move(Vector2(-100,0),Vector2(200,0),{}).x < -30.9,"Fast movement cannot tunnel through a rock")
	check(sweep.move(Vector2(-100,60),Vector2(200,0),{}) == Vector2(100,60),"Clear paths preserve exact motion")
	check(sweep.move(Vector2(-20,0),Vector2(-20,0),{}).x == -40,"Overlapped players can escape after regrowth")
	check(sweep.move(Vector2(-20,0),Vector2(10,0),{}).x <= -20,"Overlap cannot move deeper")
	var diagonal := sweep.move(Vector2(-40,-15),Vector2(60,35),{})
	check(diagonal.length() >= 30.99 and diagonal.y > -15,"Diagonal contact slides without penetration")
	var rubble := sweep.move(Vector2(-100,0),Vector2(200,0),{"rock":{"hits":3}})
	check(rubble.x < -17.9 and rubble.x > -18.1,"Broken rocks use reduced collision")
	for i in 2000: sweep.insert(str(i),Vector2(10000+i*170,10000),10)
	check(sweep.nearby(Vector2(-40,0),Vector2(40,0)).size() == 1,"Movement queries only nearby spatial cells")
	GameWindow.set_preference("pause_unfocused",false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship: Ship = get_tree().current_scene.get_node("Ship")
	ship.survival.set_physics_process(false)
	ship.set_physics_process(false)
	var player := ship.player
	var service: InventoryService = ship.get_node("InventorySystem")
	check(not ship.has_node("InteractionPrompt"),"Interaction popups removed")
	var button: InventorySlotButton = service.hud.buttons[0]
	button.set_entry({"id":&"medpack","quantity":1},"1",false)
	check(button.tooltip_text.is_empty() and button.hover_name.text == "Medpack","Hover contains only the name")
	check(TotemArt.texture(1).region.size.x < 410,"Medpack excludes transparent atlas padding")
	var eating := service.get_node("Eating")
	check(not eating.z_as_relative and eating.z_index > 4004,"Use rings render above sorted characters")
	var island: WorldIsland = ship.get_islands().filter(func(i):return i is GeneratedIsland)[0]
	var totem: MinigameTotem = island.get_node("MinigameTotem")
	ship._view.set_process(false)
	var camera: Camera2D = ship._view.camera
	camera.global_position = totem.global_position
	camera.reset_smoothing()
	camera.force_update_scroll()
	player.set_overboard(true)
	player.update_land(true)
	player.global_position = totem.global_position+Vector2(40,-30)
	ship.foliage._process(0)
	check(player.z_index < totem.z_index,"Totem covers a player standing behind it")
	player.global_position = totem.global_position+Vector2(40,30)
	ship.foliage._process(0)
	check(player.z_index > totem.z_index,"Player in front covers the totem")
	var blocked := ship.foliage.collision.move(totem.global_position-Vector2(60,0),Vector2(120,0),ship.foliage.changes)
	check(blocked.x < totem.global_position.x-25.9,"Totem has solid foot collision")
	totem.set_cooldown(150)
	check(totem.cooldown == 150 and totem.cooldown_remaining == 150,"Cooldown ring retains half of its five-minute duration")
	var manager: IslandChallenges = ship.get_node("IslandChallenges")
	player.global_position = totem.global_position+Vector2(40,0)
	ship._view.challenge_center = Vector2.INF
	ship._view._update_camera(0.016)
	var normal_zoom := camera.zoom
	check(manager.try_start(1,str(island.name)),"Challenge starts beside solid totem")
	for i in 4: await get_tree().process_frame
	ship._view._update_camera(0.016)
	check(camera.zoom.is_equal_approx(normal_zoom),"Challenge keeps normal camera zoom")
	check(manager.game.get_node_or_null("Rowboat") == null,"No exit trip required")
	manager.game.give_item(&"coconut",1)
	check(not manager.game.hud.toast_label.visible,"Challenge pickups do not show plus-item toasts")
	var game := manager.game as CollectIsland
	check(game != null,"First island is the collection challenge")
	if game != null:
		game.collected_count = game.total_count
		game.win_delay_seconds = 0.01
		await get_tree().create_timer(0.1).timeout
		check(not is_instance_valid(manager.game) and manager.locks[str(island.name)].player == 0,"Completing objective auto-finishes and starts cooldown")
	print("PROP POLISH: ",checks," checks, ",failures," failures")
	GameWindow.shutdown_audio()
	get_tree().quit(0 if failures == 0 else 1)
