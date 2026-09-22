extends Node
## Host-owned containers. Clients send intent, never quantities or player identities.
signal updated
signal feedback(message: String)
@export var starting_slots: int = 4
@export var storage_slots: int = 12
@export var storage_position := Vector2(48, 65)
@export var interaction_distance: float = 65.0
@export_range(8.0, 64.0) var pickup_distance: float = 24.0
var pickup_inside: Dictionary = {} # drop ID -> crew already inside its trigger.
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
	pickup_inside.clear()
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
	for occupants: Dictionary in pickup_inside.values():
		occupants.erase(id)
	last_request.erase(id)
	publish()

func near_storage(id: int) -> bool:
	return session.players.has(id) and session.players[id].position.distance_to(storage_position) <= interaction_distance

func request(action: String, index: int = -1) -> void:
	if multiplayer.is_server():
		_execute(1, action, index, view_revision)
	else:
		request_action.rpc_id(1, action, index, view_revision)

@rpc("any_peer", "call_remote", "reliable")
func request_action(action: String, index: int, expected_revision: int, destination: int = -1, from_storage: bool = false, to_storage: bool = false) -> void:
	if multiplayer.is_server():
		_execute(multiplayer.get_remote_sender_id(), action, index, expected_revision, destination, from_storage, to_storage)

func request_drag(data: Dictionary, destination: int = -1, to_storage: bool = false) -> void:
	var action := "move" if destination >= 0 else ("drop_storage" if data.storage else "drop")
	if multiplayer.is_server():
		_execute(1, action, data.index, data.revision, destination, data.storage, to_storage)
	else:
		request_action.rpc_id(1, action, data.index, data.revision, destination, data.storage, to_storage)

func _execute(id: int, action: String, index: int, expected_revision: int, destination: int = -1, from_storage: bool = false, to_storage: bool = false) -> void:
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
		"move":
			if (from_storage or to_storage) and not near_storage(id):
				return
			var source: ShipInventory = storage if from_storage else inventory
			var target: ShipInventory = storage if to_storage else inventory
			if not source.move_to(index, target, destination):
				return
		"take", "store":
			if not near_storage(id):
				_reply(id, "Move closer to the supply chest.")
				return
			var source: ShipInventory = storage if action == "take" else inventory
			var target: ShipInventory = inventory if action == "take" else storage
			if source.transfer_to(index, target) == 0:
				_reply(id, "No room for that stack.")
				return
		"drop", "drop_storage":
			if action == "drop_storage" and not near_storage(id):
				return
			var source: ShipInventory = storage if action == "drop_storage" else inventory
			if index < 0 or index >= source.slots.size() or source.slots[index].is_empty():
				return
			_spawn_drop(source.slots[index], session.players[id].position)
			source.remove(index, source.slots[index].quantity)
		_:
			return
	publish()

func _spawn_drop(entry: Dictionary, position: Vector2) -> void:
	# Ship-local coordinates keep loose supplies aboard through translation/rotation.
	drops[next_drop_id] = {"id": entry.id, "quantity": entry.quantity, "position": position}
	# Spawning underneath somebody is not a new entry. They must leave and return.
	var occupants: Dictionary = {}
	for id: int in crew:
		if session.players.has(id) and session.players[id].position.distance_to(position) <= pickup_distance:
			occupants[id] = true
	pickup_inside[next_drop_id] = occupants
	next_drop_id += 1

func collect_nearby(_delta: float) -> void:
	if not multiplayer.is_server() or not session.running:
		return
	var changed := false
	for key: int in drops.keys():
		var occupants: Dictionary = pickup_inside[key]
		var entry: Dictionary = drops[key]
		for id: int in crew:
			if not session.players.has(id) or session.players[id].position.distance_to(entry.position) > pickup_distance:
				occupants.erase(id)
				continue
			if occupants.has(id):
				continue
			occupants[id] = true
			var remainder: int = crew[id].add(entry.id, entry.quantity)
			if remainder == int(entry.quantity):
				continue # Full pockets stay silent; another player may have room.
			changed = true
			if remainder == 0:
				drops.erase(key)
				pickup_inside.erase(key)
				break
			entry.quantity = remainder
	if changed:
		publish()

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
