# Player inventory system

This folder holds a small, per-player inventory model. It is deliberately
data-only: it has no UI, saving, networking, item removal, or world-drop
behavior yet. Gameplay features should use this API instead of editing the
exported arrays and dictionary directly.

## Runtime pieces

| File | Responsibility |
| --- | --- |
| `player_inventory.gd` | `PlayerInventory`, a Resource holding one player's item types and quantities. |
| `inventory_usage.gd` | Optional Node component that forwards calls to an assigned `PlayerInventory`. |

Each `Player` owns a `player_inventory` property. In `scenes/player.tscn` it
is a scene-local Resource, so each future Player scene instance receives a
separate inventory. `player.gd` also creates one if the property is missing,
which keeps programmatically created players safe.

The current prototype gives each player one `fishing_rod` during `_ready()`.
This is starter equipment, not a general-purpose item grant pattern.

## Data model and capacity

`max_inv_space` is the maximum number of *distinct item types*, not the total
number of individual items. Its default is `4`.

For example, an inventory containing one Fishing Rod, 10 Cod, and 3 Rope uses
three spaces. More Cod cannot be added because Cod has a stack limit of 10,
but a fourth distinct item could still be added. Item stack limits come from
the matching `ItemData.max_stack` definition.

`inventory` lists the owned `ItemData` types and `quantities` maps each item
ID to its count. These are exported for debugging and inspection, but team
gameplay code must use the functions below to preserve the two structures in
sync.

## API

```gdscript
var added: bool = player_inventory.add_item(item)
var cod_count: int = player_inventory.get_quantity(&"fish_cod")
var removed: bool = player_inventory.remove_item(&"fish_cod", 2)
```

`add_item(item)` returns `true` only when it stored one item. It returns
`false` when:

- `item` is `null`;
- that item type is already at its stack limit; or
- no distinct-item space remains for a new item type.

Treat `false` as a gameplay result. Until a world-drop system exists, callers
should leave the item ungranted and provide an appropriate message/log.

`get_quantity(item_id)` returns `0` for an item that is not held.

`remove_item(item_id, amount = 1)` removes the requested positive amount and
returns `true` only when that many items were held. When the quantity reaches
zero, it removes both the item type from `inventory` and its ID from
`quantities`, which frees one distinct-item slot. It returns `false` without
changing the inventory if `amount` is zero/negative, the item is absent, or
the requested amount is larger than the held quantity.

Use `remove_item()` for consumption, repairs, and future transfers. Never
edit `inventory` or `quantities` directly to remove an item.

## Adding rewards from a station or interaction

Resolve the shared item definition through `ItemDatabase`, then add it to the
specific player who completed the interaction:

```gdscript
var item: ItemData = ItemDatabase.get_item(&"fish_cod")
var player_inventory := player.get("player_inventory") as PlayerInventory

if item == null or player_inventory == null:
	push_warning("Cannot grant fishing reward.")
	return

if not player_inventory.add_item(item):
	print("Inventory or item stack is full.")
	return
```

`FishingStation` follows this pattern. Its catch only emits `item_caught` and
plays the catch animation after `add_item` succeeds, so listeners can treat
that signal as a successfully stored reward.

For a reusable scene component, add a child **Node** in the Scene dock,
attach `inventory_usage.gd`, and assign the intended `PlayerInventory` in the
Inspector. Call its `add_item()` and `get_quantity()` methods. This is useful
only when that component has a stable, known owner; interaction stations
should normally use the player who initiated the interaction so it remains
correct for future local multiplayer.

## Checking required equipment

Use an item ID and quantity check before permitting an action:

```gdscript
var has_rod := player_inventory.get_quantity(&"fishing_rod") > 0
if not has_rod:
	# Show a prompt and do not start the action.
	return
```

`FishingStation` implements this check for its interacting player. Do not
hard-code a global player or share an inventory across players; future crew
members need their own tools and rewards.

## UI and future extensions

An inventory UI should render the `inventory` item types and obtain each count
with `get_quantity(item.id)`. It should not maintain a second quantity list.
When implementing UI refreshes, add a `changed` signal to `PlayerInventory`
and emit it after every successful mutation; connect the UI to that signal.

Before adding removal, consumption, transfers, saves, or multiplayer syncing,
extend `PlayerInventory` with explicit methods and tests. Do not mutate
`inventory` or `quantities` from outside this folder.
