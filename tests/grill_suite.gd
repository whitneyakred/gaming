extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameWindow.set_preference("fullscreen",false)
	GameWindow.set_preference("pause_unfocused",false)
	VoyageState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().scene_changed
	await get_tree().process_frame
	var ship := get_tree().current_scene.get_node("Ship")
	var grill: ShipGrill = ship.get_node("Cooking")
	var service: InventoryService = ship.get_node("InventorySystem")
	grill.set_process(false)
	service.player.position = grill.position + Vector2(-20,12)
	service.hud.grill_open = true
	service.inventory.restore([{"id": &"fish_cod", "quantity": 4},{},{},{}])
	check(service.grill_is_nearest(),"Galley remains accessible at existing station")
	check(grill.handle(service,{"action":"start","index":0,"revision":service.view_revision}),"Caught fish starts preparation")
	check(service.inventory.get_quantity(&"fish_cod")==3,"Ingredient consumed exactly once")
	var token := grill.token
	check(not grill.handle(service,{"action":"start","index":0,"revision":service.view_revision}),"Occupied station rejects second attempt")
	check(not grill.handle(service,{"action":"finish","token":token,"stars":3}),"Instant fabricated result rejected")
	grill.started -= 8000
	check(not grill.handle(service,{"action":"finish","token":token,"stars":"3"}),"Malformed rating rejected")
	check(not grill.handle(service,{"action":"finish","token":token+1,"stars":3}),"Wrong attempt rejected")
	check(grill.handle(service,{"action":"finish","token":token,"stars":2}),"Completed preparation awards meal")
	check(not grill.handle(service,{"action":"finish","token":token,"stars":2}),"Repeated completion rejected")
	check(service.inventory.get_quantity(&"dried_fish")==1,"Exactly one meal awarded")
	grill.handle(service,{"action":"start","index":0,"revision":service.view_revision})
	grill.release_for(1)
	grill.release_for(1)
	check(service.inventory.get_quantity(&"fish_cod")==3,"Cancellation refunds escrow exactly once")
	grill.handle(service,{"action":"start","index":0,"revision":service.view_revision})
	var saved := grill.capture()
	grill.restore(saved)
	check(not grill.cooking() and grill.fish.size()==1,"Saved unfinished preparation restores recoverable ingredient")
	grill.handle(service,{"action":"recover"})
	grill.handle(service,{"action":"recover"})
	check(service.inventory.get_quantity(&"fish_cod")==3,"Save recovery cannot duplicate ingredient")
	grill.restore({"fish":[{"key":1,"point":Vector2.ZERO,"progress":8.0}],"fuel":{"id":&"wood","quantity":2}})
	grill.handle(service,{"action":"recover"})
	check(service.inventory.get_quantity(&"dried_fish")==2 and service.inventory.get_quantity(&"wood")==2,"Legacy furnace food and fuel remain recoverable")
	service.hud.grill_panel.show()
	service.hud.grill_panel._start()
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_instance_valid(service.hud.grill_panel.activity),"Teammate activity opens locally")
	check(service.hud.grill_panel.activity.has_signal("completed"),"Existing teammate minigame result boundary retained")
	service.hud.close()
	grill._process(0.01)
	check(not grill.cooking(),"Closing activity releases shared station")
	service.player.position=Vector2(-400,-400)
	service.hud.grill_open=true
	check(not grill.handle(service,{"action":"start","index":0,"revision":service.view_revision}),"Distant cooking rejected")
	print("GRILL: %d checks, %d failures" % [checks,failures])
	GameWindow.shutdown_audio()
	get_tree().quit(1 if failures else 0)
