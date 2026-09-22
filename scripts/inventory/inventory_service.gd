extends Node
## Host-owned containers. Clients send intent, never quantities or player identities.
signal updated
signal feedback(message: String)
@export var starting_slots: int = 4
@export var storage_slots: int = 12
@export var storage_position := Vector2(48, 65)
@export var interaction_distance: float = 65.0
var session: Node
var crew: Dictionary = {}
var storage: ShipInventory
var drops: Dictionary = {}
var next_drop_id: int = 1
var revision: int = 0
var last_request: Dictionary = {}
var local_slots: Array = []
var storage_view: Array = []
var drops_view: Dictionary = {}
var view_revision: int = 0

func _ready() -> void:
	session = get_parent()
	session.session_reset.connect(reset)
	reset()

func reset() -> void:
	crew.clear()
	drops.clear()
	last_request.clear()
	next_drop_id = 1
	revision = 0
	storage = ShipInventory.new(storage_slots)
	for entry in [[&"fish_cod", 8], [&"water", 8], [&"shovel", 2], [&"spyglass", 2], [&"rope", 12], [&"fishing_rod", 2]]:
		storage.add(entry[0], entry[1])
	local_slots = []
	storage_view = []
	drops_view = {}
	view_revision = 0
	updated.emit()

func add_crew(id: int) -> void:
	if not multiplayer.is_server():
		return
	crew[id] = ShipInventory.new(starting_slots)
	publish()

func remove_crew(id: int, position: Vector2) -> void:
	if not multiplayer.is_server() or not crew.has(id):
		return
	if session.running:
		for entry in crew[id].slots:
			if not entry.is_empty():
				_spawn_drop(entry, position)
	crew.erase(id)
	last_request.erase(id)
	publish()

func near_storage(id: int) -> bool:
	return session.players.has(id) and session.players[id].position.distance_to(storage_position) <= interaction_distance

func nearest_drop(id: int) -> int:
	if not session.players.has(id):
		return -1
	var closest := -1
	var distance := interaction_distance
	for key: int in drops_view:
		var candidate: float = session.players[id].position.distance_to(drops_view[key].position)
		if candidate < distance:
			distance = candidate
			closest = key
	return closest

func request(action: String, index: int = -1) -> void:
	if multiplayer.is_server():
		_execute(1, action, index, view_revision)
	else:
		request_action.rpc_id(1, action, index, view_revision)

@rpc("any_peer", "call_remote", "reliable")
func request_action(action: String, index: int, expected_revision: int) -> void:
	if multiplayer.is_server():
		_execute(multiplayer.get_remote_sender_id(), action, index, expected_revision)

func _execute(id: int, action: String, index: int, expected_revision: int) -> void:
	if not session.running or not crew.has(id) or not session.players.has(id):
		return
	var now := Time.get_ticks_msec()
	if now - int(last_request.get(id, -1000)) < 100:
		return
	last_request[id] = now
	if expected_revision != revision:
		_reply(id, "Supplies changed. Try again.")
		return
	if is_instance_valid(session.players[id].active_station):
		_reply(id, "Leave your station before handling supplies.")
		return
	var inventory: ShipInventory = crew[id]
	match action:
		"take", "store":
			if not near_storage(id):
				_reply(id, "Move closer to the supply chest.")
				return
			var source: ShipInventory = storage if action == "take" else inventory
			var target: ShipInventory = inventory if action == "take" else storage
			if source.transfer_to(index, target) == 0:
				_reply(id, "No room for that stack.")
				return
		"drop":
			if index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty():
				return
			_spawn_drop(inventory.slots[index], session.players[id].position)
			inventory.remove(index, inventory.slots[index].quantity)
		"pickup":
			if not drops.has(index) or session.players[id].position.distance_to(drops[index].position) > interaction_distance:
				return
			var entry: Dictionary = drops[index]
			var remainder := inventory.add(entry.id, entry.quantity)
			if remainder == int(entry.quantity):
				_reply(id, "Your pockets are full. Store or drop a stack.")
				return
			if remainder == 0:
				drops.erase(index)
			else:
				entry.quantity = remainder
		_:
			return
	publish()

func _spawn_drop(entry: Dictionary, position: Vector2) -> void:
	# Ship-local coordinates keep loose supplies aboard through translation/rotation.
	drops[next_drop_id] = {"id": entry.id, "quantity": entry.quantity, "position": position}
	next_drop_id += 1

func publish() -> void:
	if not multiplayer.is_server():
		return
	revision += 1
	for id: int in crew:
		var state := {"revision": revision, "slots": crew[id].capture(), "storage": storage.capture(), "drops": drops.duplicate(true)}
		if id == 1:
			_apply(state)
		elif id in multiplayer.get_peers():
			receive_state.rpc_id(id, state)

@rpc("authority", "call_remote", "reliable")
func receive_state(state: Dictionary) -> void:
	if not multiplayer.is_server():
		_apply(state)

func _apply(state: Dictionary) -> void:
	view_revision = state.revision
	local_slots = state.slots
	storage_view = state.storage
	drops_view = state.drops
	updated.emit()

func _reply(id: int, message: String) -> void:
	if id == 1:
		feedback.emit(message)
	else:
		receive_feedback.rpc_id(id, message)

@rpc("authority", "call_remote", "reliable")
func receive_feedback(message: String) -> void:
	feedback.emit(message)
