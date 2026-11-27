class_name ShipInventory
extends Resource
## Fixed slots adapted from inventory-system; definitions stay shared.
signal inventory_changed
@export_range(1, 99) var max_inv_space: int = 4
var slots: Array[Dictionary] = []
var revision: int = 0
var _definitions: Dictionary[StringName, ItemData] = {}

func _ensure_slots() -> void:
	while slots.size() < max_inv_space:
		slots.append({})

func definition(id: StringName) -> ItemData:
	if _definitions.has(id):
		return _definitions[id]
	var tree := Engine.get_main_loop() as SceneTree
	var catalog := tree.root.get_node_or_null("ItemDatabase") if tree != null else null
	return catalog.call("get_item", id) as ItemData if catalog != null else null

func capture() -> Array[Dictionary]:
	_ensure_slots()
	return slots.duplicate(true)

func restore(snapshot: Array[Dictionary]) -> void:
	if slots == snapshot: return
	slots = snapshot.duplicate(true)
	# Retired puzzle supplies are not real voyage items anymore. Private bags
	# still retain their own definitions, so failure rollback keeps counters.
	for index in slots.size():
		if not slots[index].is_empty() and definition(slots[index].get("id", &"")) == null:
			slots[index] = {}
	_ensure_slots()
	_notify()

func capacity_for(item: ItemData) -> int:
	if item == null or item.id.is_empty() or item.max_stack < 1:
		return 0
	_ensure_slots()
	var room := 0
	for entry in slots:
		if entry.is_empty():
			room += item.max_stack
		elif entry.id == item.id:
			room += maxi(0, item.max_stack - int(entry.quantity))
	return room

func add_items(item: ItemData, amount: int) -> int:
	if amount <= 0 or capacity_for(item) == 0:
		return 0
	_definitions[item.id] = item
	var remaining := amount
	for entry in slots:
		if entry.get("id", &"") == item.id:
			var moved := mini(remaining, maxi(0, item.max_stack - int(entry.quantity)))
			entry.quantity += moved
			remaining -= moved
	for index in slots.size():
		if remaining == 0:
			break
		if slots[index].is_empty():
			var moved := mini(remaining, item.max_stack)
			slots[index] = {"id": item.id, "quantity": moved}
			remaining -= moved
	if remaining != amount:
		_notify()
	return amount - remaining

func remove(index: int, amount: int) -> void:
	if index < 0 or index >= slots.size() or amount <= 0 or slots[index].is_empty():
		return
	slots[index].quantity -= mini(amount, int(slots[index].quantity))
	if slots[index].quantity == 0:
		slots[index] = {}
	_notify()

func transfer_to(index: int, target: ShipInventory) -> int:
	if target == self or index < 0 or index >= slots.size() or slots[index].is_empty():
		return 0
	var entry := slots[index].duplicate()
	var moved := target.add_items(definition(entry.id), entry.quantity)
	remove(index, moved)
	return moved

func move_to(index: int, target: ShipInventory, destination: int, amount: int = -1) -> bool:
	_ensure_slots()
	target._ensure_slots()
	if index < 0 or index >= slots.size() or destination < 0 or destination >= target.slots.size():
		return false
	if slots[index].is_empty() or (target == self and index == destination):
		return false
	var source := slots[index]
	var other := target.slots[destination]
	var item := definition(source.id)
	if item == null:
		return false
	if amount != -1:
		if amount <= 0 or amount > int(source.quantity): return false
		if not other.is_empty() and other.id != source.id: return false
		var room: int = item.max_stack - int(other.get("quantity", 0))
		var moved := mini(amount, room)
		if moved <= 0: return false
		target._definitions[source.id] = item
		if other.is_empty(): target.slots[destination] = {"id": source.id, "quantity": moved}
		else: other.quantity += moved
		source.quantity -= moved
		if source.quantity == 0: slots[index] = {}
		_notify()
		if target != self: target._notify()
		return true
	target._definitions[source.id] = item
	if not other.is_empty() and source.id == other.id:
		var moved := mini(int(source.quantity), maxi(0, item.max_stack - int(other.quantity)))
		if moved == 0:
			return false
		other.quantity += moved
		source.quantity -= moved
		if source.quantity == 0:
			slots[index] = {}
	else:
		if not other.is_empty():
			_definitions[other.id] = target.definition(other.id)
		slots[index] = other
		target.slots[destination] = source
	_notify()
	if target != self:
		target._notify()
	return true

func clear() -> void:
	if slots.all(func(entry: Dictionary) -> bool: return entry.is_empty()):
		return
	slots.clear()
	_ensure_slots()
	_notify()

func _notify() -> void:
	revision += 1
	inventory_changed.emit()
	emit_changed()
