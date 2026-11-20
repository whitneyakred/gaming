class_name CrewInputBuffer
extends RefCounted
## Bounded, exact input playback. No fabricated client acknowledgements.
const LIMIT := 120
const BATCH_LIMIT := 12
var frames: Array[Dictionary] = []
var received := -1
var acknowledged := -1
var credit := 0.1
var rejected := 0
var last_rejection := ""

func append(batch: Array) -> bool:
	if batch.is_empty() or batch.size() > BATCH_LIMIT:
		last_rejection = "batch size"
		rejected += 1
		return false
	var previous := received
	for value: Variant in batch:
		if not value is Dictionary or not value.get("sequence") is int or not value.get("move") is Vector2 or not value.get("held") is bool or not value.get("blocked") is bool:
			last_rejection = "field types"
			rejected += 1
			return false
		if value.sequence <= previous or not value.move.is_finite() or value.move.length_squared() > 1.001:
			last_rejection = "sequence" if value.sequence <= previous else "direction"
			rejected += 1
			return false
		previous = value.sequence
	if frames.size() + batch.size() > LIMIT:
		last_rejection = "queue capacity"
		rejected += 1
		return false
	for value: Dictionary in batch: frames.append(value.duplicate())
	received = previous
	return true

func take(delta: float) -> Array[Dictionary]:
	# Bank bounded real elapsed time across a stall. Consume at most six frames
	# per tick, rather than leaving a permanent backlog after a packet burst.
	credit = minf(credit + delta, 0.5)
	var result: Array[Dictionary] = []
	var step := 1.0 / Engine.physics_ticks_per_second
	while not frames.is_empty() and credit + 0.000001 >= step and result.size() < 6:
		credit -= step
		var frame: Dictionary = frames.pop_front()
		acknowledged = frame.sequence
		result.append(frame)
	return result
