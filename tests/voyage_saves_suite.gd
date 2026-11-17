extends Node
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	for slot in 3:
		VoyageSaves.clear_slot(slot)
		VoyageSaves.selected = slot
		var world := {"version": NetworkSession.PROTOCOL, "title": "Test voyage " + str(slot), "position": Vector2(100 * slot, -22), "storage": [{"id": &"coal", "quantity": 5}], "grill": {"remaining": 12.5}, "accounts": {"captain": {"inventory": [{"id": &"fish_cod", "quantity": 3}]}}}
		check(VoyageSaves.store(world), "Write slot " + str(slot))
		check(VoyageSaves.world(slot) == world, "Complete typed world survives disk roundtrip")
		check(not VoyageSaves.timestamp(VoyageSaves.read_slot(slot)).is_empty(), "Save has displayable date/time")
	check(VoyageSaves.read_slot(3).is_empty(), "Only three slots")
	check(VoyageSaves.clear_slot(1), "Clear chosen slot")
	check(VoyageSaves.world(1).is_empty() and not VoyageSaves.world(0).is_empty() and not VoyageSaves.world(2).is_empty(), "Reset leaves other worlds intact")
	NetworkSession.online = true
	check(not VoyageSaves.clear_slot(0), "Cannot erase an active session")
	NetworkSession.online = false
	VoyageSaves.selected = 0
	var previous_build := {"version": "holy-ship-coop-11", "title": "Before classroom update", "accounts": {"captain": {"inventory": [{"id": &"rope", "quantity": 3}]}}}
	check(VoyageSaves.store(previous_build), "Write previous-build fixture")
	NetworkSession.load_world()
	check(NetworkSession._restored == previous_build, "Classroom protocol upgrade preserves previous voyages")
	NetworkSession._restored.clear()
	NetworkSession.accounts.clear()
	for slot in 3: VoyageSaves.clear_slot(slot)
	VoyageSaves.selected = 0
	print("SAVES: %d checks, %d failures" % [checks, failures])
	get_tree().quit(failures)
