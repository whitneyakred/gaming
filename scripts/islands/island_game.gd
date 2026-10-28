class_name IslandGame
extends Node2D

## Shared base for every island minigame.
##
## It owns what all islands have in common: the countdown timer, the
## pirate-ship HUD track, pop-up messages, the rowboat exit, and the
## win/lose flow. Either way you row back to the ship; losing takes away
## everything picked up on the island and leaves it unfinished.
##
## To make a new island game, write a script that `extends IslandGame`
## and override only the hooks you need (see "Hooks" below). Leave the
## rest alone. Example: scripts/islands/collect_island.gd.

signal run_started
signal run_won
signal run_lost(reason: String)

@export_group("Timer")
## Seconds until time runs out. Set to 0 for an island with no time limit
## (the timer and pirate track are hidden).
@export var time_limit_seconds: float = 30.0
## Off: running out of time loses (pirates arrive). On: running out of time
## wins (use this for "survive for X seconds" islands).
@export var time_up_is_win: bool = false
@export var time_up_message: String = "The pirate ship reached the island!"
@export var threat_label: String = "Pirate ship approaching:"

@export_group("Messages")
## Shown for a few seconds when the island starts. Leave empty for none.
@export_multiline var intro_message: String = ""
@export var intro_message_seconds: float = 2.5
@export var win_message: String = "You made it back to the ship!"
## Shown when the player reaches the rowboat before finishing the task.
@export var incomplete_message: String = "Finish the island's task first!"

@export_group("Rewards")
## Treasure rewards give a random number of gold coins in this range.
@export var treasure_coins_min: int = 5
@export var treasure_coins_max: int = 30

@export_group("Ending")
@export var win_delay_seconds: float = 1.5
@export var lose_delay_seconds: float = 2.0
@export_file("*.tscn") var return_scene: String = "res://scenes/ship.tscn"

@export_group("Nodes")
@export var hud_path: NodePath = ^"IslandHUD"
@export var player_path: NodePath = ^"World/Player"

var hud: IslandHUD
var player: CharacterBody2D
var time_remaining: float = 0.0

var _run_ended: bool = false
var _timer_paused: bool = false
var _bag_full_warned_at: int = -100000
# The bag as it was when you landed, so a game over can take back the prize.
var _bag_on_arrival: Array[ItemData] = []
var _quantities_on_arrival: Dictionary[StringName, int] = {}

const COIN_ITEM_ID: StringName = &"gold_coin"


func _ready() -> void:
	hud = get_node_or_null(hud_path) as IslandHUD
	player = get_node_or_null(player_path) as CharacterBody2D
	time_remaining = time_limit_seconds

	if hud:
		hud.hide_message()
		hud.set_timer_visible(has_time_limit())
		hud.set_threat_label(threat_label)
		hud.set_inventory(get_inventory())

	var bag := get_inventory()
	if bag:
		_bag_on_arrival = bag.inventory.duplicate()
		_quantities_on_arrival = bag.quantities.duplicate()

	_setup_game()
	refresh_hud()

	if not intro_message.is_empty():
		show_message(intro_message, intro_message_seconds)
	run_started.emit()


func _process(delta: float) -> void:
	if _run_ended:
		return

	_game_process(delta)
	if _run_ended:
		return

	if has_time_limit() and not _timer_paused:
		time_remaining = maxf(time_remaining - delta, 0.0)
		_update_timer_hud()
		if time_remaining <= 0.0:
			_on_time_up()


# --- Hooks: override these in your island's script -------------------------

## Called once in _ready(), before the HUD is first drawn. Find your pickups,
## enemies, puzzle pieces, etc. and connect their signals here.
func _setup_game() -> void:
	pass

## Called every frame while the run is active (before the timer ticks).
func _game_process(_delta: float) -> void:
	pass

## Text for the top-left objective line, e.g. "Crabs: 3 / 8".
## Return "" to hide it.
func _get_objective_text() -> String:
	return ""

## Whether the player is allowed to leave by rowboat (and win).
func _is_objective_complete() -> bool:
	return true

## What to say when the player reaches the rowboat too early.
func _get_incomplete_message() -> String:
	return incomplete_message

## Called when the timer hits zero. Default: win or lose based on
## time_up_is_win. Override for something custom.
func _on_time_up() -> void:
	if time_up_is_win:
		win()
	else:
		lose(time_up_message)


# --- Helpers your island's script can call ---------------------------------

## Redraws the objective line and the timer. Call after your progress changes.
func refresh_hud() -> void:
	if hud:
		hud.set_objective(_get_objective_text())
	_update_timer_hud()

func show_message(text: String, seconds: float = 1.5) -> void:
	if hud:
		hud.show_message(text, seconds)

func has_time_limit() -> bool:
	return time_limit_seconds > 0.0

func is_running() -> bool:
	return not _run_ended

## Freeze or resume the countdown (e.g. while a puzzle animation plays).
func pause_timer(paused: bool) -> void:
	_timer_paused = paused

## Adds (or with a negative number, removes) seconds, e.g. as a penalty.
func add_time(seconds: float) -> void:
	time_remaining = clampf(time_remaining + seconds, 0.0, time_limit_seconds)
	_update_timer_hud()

## Shows a small "Press E to ..." hint at the bottom of the screen ("" hides it).
func set_prompt(text: String) -> void:
	if hud:
		hud.set_prompt(text)

## The voyage inventory of `receiver` (default: this island's player).
func get_inventory(receiver: Node = null) -> PlayerInventory:
	var who: Node = receiver if receiver != null else player
	if who == null:
		return null
	return who.get("player_inventory") as PlayerInventory

## Puts `amount` of a catalog item into the crew member's inventory and shows
## a "+N Item" note. Returns how many fit; if not all fit, says the bag is full.
## Every island reward and pickup goes through here so nothing is lost.
func give_item(item_id: StringName, amount: int = 1, receiver: Node = null) -> int:
	var item: ItemData = ItemDatabase.get_item(item_id)
	var inventory := get_inventory(receiver)
	if item == null or inventory == null:
		push_warning("Cannot give item %s: unknown item or no inventory." % item_id)
		return 0
	var added := inventory.add_items(item, amount)
	if added > 0 and hud:
		hud.show_toast("+%d %s" % [added, item.display_name])
	if added < amount:
		_warn_bag_full(item)
	return added

## Treasure reward: a random 5-30 (see Rewards in the Inspector) gold coins
## go into the inventory, with a "N coins collected!" pop-up.
## `prefix` is shown on the line above, e.g. "You found the treasure!".
func give_treasure(prefix: String = "") -> int:
	var coins := randi_range(treasure_coins_min, treasure_coins_max)
	var added := give_item(COIN_ITEM_ID, coins)
	var line := "%d coins collected!" % added
	if added == 0:
		line = "Your bag is full! The coins stay behind."
	show_message(line if prefix.is_empty() else "%s\n%s" % [prefix, line], 2.5)
	return added

## Called by scripts/rowboat.gd when the player reaches the rowboat.
func try_escape() -> void:
	if _run_ended:
		return
	if _is_objective_complete():
		win()
	else:
		show_message(_get_incomplete_message(), 1.5)

func win(message: String = "") -> void:
	if _run_ended:
		return
	_end_run()
	show_message(message if not message.is_empty() else win_message, 0.0)
	run_won.emit()
	await get_tree().create_timer(win_delay_seconds).timeout
	_row_back(true)

func lose(reason: String) -> void:
	if _run_ended:
		return
	_end_run()
	_take_back_prizes()
	show_message(reason + " Game Over!\nRow back to the ship empty-handed.", 0.0)
	run_lost.emit(reason)
	await get_tree().create_timer(lose_delay_seconds).timeout
	_row_back(false)


# --- Internals ----------------------------------------------------------------

func _warn_bag_full(item: ItemData) -> void:
	# Walking along a row of pickups would repeat this every frame; once a
	# few seconds is plenty.
	var now := Time.get_ticks_msec()
	if now - _bag_full_warned_at < 2500:
		return
	_bag_full_warned_at = now
	if hud:
		hud.show_toast("Bag full! No room for %s" % item.display_name)

# Tells the ship scene to play the "row back to the ship" sequence. Only a
# win marks the island as finished.
func _row_back(won: bool) -> void:
	Ship.returning_from_island = true
	Ship.last_visit_won = won
	get_tree().change_scene_to_file(return_scene)

# Puts the bag back the way it was when you landed: no prize for a game over.
func _take_back_prizes() -> void:
	var bag := get_inventory()
	if bag == null:
		return
	bag.inventory = _bag_on_arrival.duplicate()
	bag.quantities = _quantities_on_arrival.duplicate()
	bag.emit_changed()

func _end_run() -> void:
	_run_ended = true
	set_prompt("")
	if player:
		player.set_physics_process(false)

func _update_timer_hud() -> void:
	if hud == null or not has_time_limit():
		return
	hud.set_time_left(time_remaining)
	hud.set_progress(1.0 - time_remaining / time_limit_seconds)
