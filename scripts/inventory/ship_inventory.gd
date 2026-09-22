class_name ShipInventory
extends RefCounted
## Item definitions are shared; only these value entries belong to a container.
signal changed
var slots: Array[Dictionary] = []

func _init(capacity: int = 4) -> void:
	for index in range(maxi(0, capacity)):
		slots.append({})

func add(item_id: StringName, quantity: int) -> int:
	var definition: ItemData = ItemDatabase.get_item(item_id)
	if definition == null or quantity <= 0:
		return quantity
	var remaining := quantity
	for entry in slots:
		if entry.get("id", &"") == item_id:
			var amount := mini(remaining, definition.max_stack - int(entry.quantity))
			entry.quantity += amount
			remaining -= amount
	for index in range(slots.size()):
		if remaining == 0:
			break
		if slots[index].is_empty():
			var amount := mini(remaining, definition.max_stack)
			slots[index] = {"id": item_id, "quantity": amount}
			remaining -= amount
	if remaining != quantity:
		changed.emit()
	return remaining

func remove(index: int, quantity: int) -> void:
	if index < 0 or index >= slots.size() or quantity <= 0 or slots[index].is_empty():
		return
	slots[index].quantity -= mini(quantity, int(slots[index].quantity))
	if slots[index].quantity == 0:
		slots[index] = {}
	changed.emit()

func transfer_to(index: int, target: ShipInventory) -> int:
	if target == self or index < 0 or index >= slots.size() or slots[index].is_empty():
		return 0
	var entry := slots[index]
	var moved := int(entry.quantity) - target.add(entry.id, entry.quantity)
	remove(index, moved)
	return moved

func capture() -> Array[Dictionary]:
	return slots.duplicate(true)

func move_to(index: int, target: ShipInventory, destination: int) -> bool:
	if index < 0 or index >= slots.size() or destination < 0 or destination >= target.slots.size():
		return false
	if slots[index].is_empty() or (target == self and index == destination):
		return false
	var source := slots[index]
	var other := target.slots[destination]
	if not other.is_empty() and source.id == other.id:
		var limit: int = ItemDatabase.get_item(source.id).max_stack
		var moved := mini(int(source.quantity), limit - int(other.quantity))
		if moved <= 0:
			return false
		other.quantity += moved
		remove(index, moved)
	else:
		# Empty destinations move; unlike items swap atomically, even when full.
		slots[index] = other
		target.slots[destination] = source
		changed.emit()
	if target != self:
		target.changed.emit()
	return true

func add_capacity(extra_slots: int) -> void:
	# Future bags can grant capacity on the host without changing the hotbar UI.
	if extra_slots <= 0:
		return
	for index in range(extra_slots):
		slots.append({})
	changed.emit()
