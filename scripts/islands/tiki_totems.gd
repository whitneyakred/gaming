class_name TikiTotems
extends IslandGame

## Tiki Totems: a memory game.
## The stone tiles light up in a pattern. When the tiki's eyes go dark,
## step on the tiles in the same order. Each round adds a step. Get every
## round right and the tiki spits out treasure (5-30 gold coins into your
## bag). A wrong step costs time and replays the pattern.
## The timer pauses while the pattern plays.
##
## Scene setup: Marker2D children of Tiles are the tiles (any number, 4
## works well), and the Tiki marker is where the big head stands.

@export_group("Tiles")
@export var tiles_path: NodePath = ^"World/Tiles"
@export var tiki_path: NodePath = ^"World/Tiki"
@export var tile_size: float = 64.0
## Pattern length for each round.
@export var round_lengths: Array[int] = [3, 4, 5]
@export var flash_seconds: float = 0.55
@export var gap_seconds: float = 0.2
@export var wrong_penalty_seconds: float = 5.0
@export var tile_colors: Array[Color] = [
	Color8(220, 70, 60), Color8(70, 140, 220), Color8(240, 200, 60), Color8(90, 190, 90),
	Color8(190, 90, 200), Color8(240, 140, 50),
]

enum Phase { SHOWING, INPUT, DONE }

var phase: Phase = Phase.SHOWING
var round_index: int = 0
var sequence: Array[int] = []
var input_index: int = 0

var _tiles: Array[Node2D] = []
var _lit: Dictionary[int, Color] = {}
var _standing_on: int = -1
var _tiki: Node2D
var _show_token: int = 0


func _setup_game() -> void:
	var tiles_node := get_node_or_null(tiles_path)
	assert(tiles_node != null, "TikiTotems needs Marker2D children under Tiles.")
	for marker in tiles_node.get_children():
		if marker is Node2D:
			var index := _tiles.size()
			_tiles.append(marker)
			marker.z_index = -5
			marker.draw.connect(_draw_tile.bind(index))
			marker.queue_redraw()
	_tiki = get_node_or_null(tiki_path) as Node2D
	if _tiki:
		_tiki.draw.connect(_draw_tiki)
	_start_round()


func _game_process(_delta: float) -> void:
	var tile := _tile_under_player()
	if tile != _standing_on:
		_standing_on = tile
		if tile >= 0 and phase == Phase.INPUT:
			_on_step(tile)
	if _tiki:
		_tiki.queue_redraw()


func _start_round() -> void:
	sequence.clear()
	for i in round_lengths[round_index]:
		sequence.append(randi() % _tiles.size())
	_play_sequence()


func _play_sequence() -> void:
	phase = Phase.SHOWING
	input_index = 0
	pause_timer(true)
	refresh_hud()
	_show_token += 1
	var token := _show_token
	await get_tree().create_timer(0.9, false).timeout
	for tile in sequence:
		if token != _show_token or not is_running():
			return
		_light(tile, tile_colors[tile % tile_colors.size()].lightened(0.45), flash_seconds)
		await get_tree().create_timer(flash_seconds + gap_seconds, false).timeout
	if token != _show_token or not is_running():
		return
	phase = Phase.INPUT
	pause_timer(false)
	# Standing on a tile when input starts doesn't count as a step.
	_standing_on = _tile_under_player()
	refresh_hud()


func _on_step(tile: int) -> void:
	if tile == sequence[input_index]:
		_light(tile, Color(0.6, 1.0, 0.6), 0.3)
		input_index += 1
		if input_index >= sequence.size():
			_round_won()
		else:
			refresh_hud()
		return
	_light(tile, Color(1.0, 0.25, 0.2), 0.5)
	add_time(-wrong_penalty_seconds)
	show_message("Wrong tile! (-%ds) Watch again..." % int(wrong_penalty_seconds), 1.4)
	_play_sequence()


func _round_won() -> void:
	round_index += 1
	if round_index >= round_lengths.size():
		phase = Phase.DONE
		pause_timer(true)
		refresh_hud()
		give_treasure("The tiki spits out its treasure!")
		return
	show_message("Round %d done!" % round_index, 1.0)
	_start_round()


func _light(tile: int, color: Color, seconds: float) -> void:
	_lit[tile] = color
	_tiles[tile].queue_redraw()
	await get_tree().create_timer(seconds, false).timeout
	if _lit.get(tile) == color:
		_lit.erase(tile)
		if is_instance_valid(_tiles[tile]):
			_tiles[tile].queue_redraw()


func _tile_under_player() -> int:
	if player == null:
		return -1
	var half := tile_size / 2.0
	for i in _tiles.size():
		var d := player.global_position - _tiles[i].global_position
		if absf(d.x) <= half and absf(d.y) <= half:
			return i
	return -1


func _get_objective_text() -> String:
	match phase:
		Phase.SHOWING:
			return "Round %d / %d: watch the tiles..." % [round_index + 1, round_lengths.size()]
		Phase.INPUT:
			return "Round %d / %d: step on the tiles in order (%d / %d)" % [
				round_index + 1, round_lengths.size(), input_index, sequence.size()]
	return "Treasure won! Head to the rowboat."


func _is_objective_complete() -> bool:
	return phase == Phase.DONE


func _get_incomplete_message() -> String:
	return "The tiki still guards its treasure!"


func _draw_tile(index: int) -> void:
	var tile := _tiles[index]
	var half := tile_size / 2.0
	var rect := Rect2(-half, -half, tile_size, tile_size)
	tile.draw_rect(rect.grow(4.0), Color8(90, 86, 80))
	var base := tile_colors[index % tile_colors.size()].darkened(0.45)
	tile.draw_rect(rect, _lit.get(index, base))
	tile.draw_rect(rect, Color(0, 0, 0, 0.35), false, 2.0)


func _draw_tiki() -> void:
	var wood := Color8(130, 88, 50)
	_tiki.draw_rect(Rect2(-30, -90, 60, 90), wood)
	_tiki.draw_rect(Rect2(-36, -96, 72, 14), wood.darkened(0.3))
	var watching := phase == Phase.SHOWING
	var eye := Color(1.0, 0.85, 0.3) if watching else Color8(40, 25, 15)
	_tiki.draw_rect(Rect2(-20, -72, 14, 10), eye)
	_tiki.draw_rect(Rect2(6, -72, 14, 10), eye)
	_tiki.draw_rect(Rect2(-16, -40, 32, 12), Color8(60, 35, 20))
	if phase == Phase.DONE:
		_tiki.draw_circle(Vector2(0, 14), 10.0, Color(1.0, 0.85, 0.2))
