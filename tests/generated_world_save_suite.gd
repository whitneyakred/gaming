extends Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures+=1; push_error(message)
func _ready() -> void: run.call_deferred()
func ready_world() -> void:
	for i in 180:
		await get_tree().process_frame
		if NetworkSession.world_ready and NetworkSession.players.has(1): return
func run() -> void:
	if "--settings-test" not in OS.get_cmdline_user_args():
		push_error("Use -- --settings-test; this suite writes isolated test slot 3 only")
		get_tree().quit(1)
		return
	GameWindow.set_preference("pause_unfocused",false)
	VoyageSaves.selected = 2
	VoyageSaves.clear_slot(2)
	var old := {"version":"holy-ship-coop-20","seed":34729,"title":"Legacy fixture","position":Vector2(100,150),"rotation":0.0,"paradise_quest":{},"drops":{1:{"id":&"bronze_key","quantity":1,"position":Vector2(123,456),"world":false,"age":0.0}}}
	check(VoyageSaves.store(old),"Legacy save fixture stored")
	check(NetworkSession.host_session("Legacy",24682,"",true)==OK,"Legacy host starts")
	await ready_world()
	check(NetworkSession.world_ready,"Legacy world becomes ready")
	check(NetworkSession.ship.layout_version==1 and not NetworkSession.ship.get_island("Island_00") is GeneratedIsland,"Missing terrain version resumes exact legacy generator")
	check(NetworkSession.ship.global_position==Vector2(100,150),"Legacy boat position preserved")
	check(NetworkSession.services[1].drops[1].position==Vector2(123,456),"Legacy dropped key stays at its saved deck coordinates")
	NetworkSession.save_world()
	check(VoyageSaves.world(2).layout_version==1,"Saving old voyage retains layout version 1")
	NetworkSession.leave()
	await get_tree().process_frame
	await get_tree().process_frame
	NetworkSession.host_session("New islands",24682,"",false)
	await ready_world()
	check(NetworkSession.ship.layout_version==2 and NetworkSession.ship.get_island("Island_00") is GeneratedIsland,"Fresh voyage uses new terrain")
	var coast: PackedVector2Array = NetworkSession.ship.get_island("Island_00").get_coast()
	var tree_id: String = NetworkSession.ship.foliage.trees.keys()[0]
	NetworkSession.ship.foliage.changes[tree_id] = {"hits":3,"until":NetworkSession.ship.foliage.time_now()+300.0}
	var rock_id: String = NetworkSession.ship.foliage.trees.keys().filter(func(id: String)->bool: return NetworkSession.ship.foliage.trees[id].kind>=8)[0]
	NetworkSession.ship.foliage.changes[rock_id] = {"hits":3,"until":NetworkSession.ship.foliage.time_now()+300.0}
	NetworkSession.save_world()
	check(VoyageSaves.world(2).layout_version==2,"New terrain version saved")
	NetworkSession.leave()
	await get_tree().process_frame
	await get_tree().process_frame
	NetworkSession.host_session("Resume generated",24682,"",true)
	await ready_world()
	check(NetworkSession.ship.layout_version==2 and NetworkSession.ship.get_island("Island_00").get_coast()==coast,"Generated save resumes identical coastline")
	check(NetworkSession.ship.foliage.changes.get(tree_id,{}).get("hits",0)==3,"Saved chopped tree remains a stump after real session reload")
	check(NetworkSession.ship.foliage.changes.get(rock_id,{}).get("hits",0)==3,"Saved mined rock remains rubble after real session reload")
	NetworkSession.leave()
	await get_tree().process_frame
	VoyageSaves.clear_slot(2)
	GameWindow.shutdown_audio()
	await get_tree().create_timer(0.3).timeout
	print("GENERATED WORLD SAVE: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
