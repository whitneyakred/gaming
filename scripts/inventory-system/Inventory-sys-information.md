# Player inventory system

This folder holds a small, per-player inventory model. It is deliberately
data-only: it supports adding, counting, removing, reordering, and clearing
items, but has no UI, saving, networking, or world-drop behavior yet. Gameplay
features should use this API instead of editing the exported arrays and
dictionary directly.

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

This section describes current code. The planned contract in
[BR-inventory-slots](../../docs/requirements/business-rules.md#27-inventory-map-and-island-travel)
has six quick slots plus TBD expanded slots and 30-item stacks. This prototype
intentionally retains its four distinct-item spaces and per-item stack limits;
see `OI-11` in the open-issues register.

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
var added_many: bool = player_inventory.try_add(&"fish_cod", 2)
var cod_count: int = player_inventory.get_quantity(&"fish_cod")
var removed: bool = player_inventory.remove_item(&"fish_cod", 2)
var removed_many: bool = player_inventory.try_remove(&"fish_cod", 2)
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

`try_add(item_id, amount = 1)` and `try_remove(item_id, amount = 1)` are the
explicit multi-item APIs. They return `false` without changing either exported
collection when the amount is invalid, the catalog item is missing, the stack
would exceed that item's configured limit, or the quantity is unavailable.
`add_item()` and `remove_item()` remain compatibility helpers for existing
gameplay callers.

`move_item(item_id, target_index)` reorders an owned distinct item type within
the occupied `inventory` entries. `clear()` empties the inventory for a reset
flow. `inventory_changed` emits once after each successful add, remove, reorder, or
clear operation, so a future inventory view can refresh without owning a
second copy of the data.

## Running the inventory tests

From the repository root, run the Bash test runner:

```bash
bash ./test-inv-system.sh
```

The runner starts Godot in headless mode and runs
`tests/inventory_test.gd`. It prints a `PASS:` or `FAIL:` line for every named
test, prints a final total, and exits with a nonzero status when any test
fails. The default executable name is `Godot`. If Godot is installed elsewhere,
provide its path with `GODOT_BIN`:

```bash
GODOT_BIN="/path/to/Godot" bash ./test-inv-system.sh
```

The suite covers:

- `PlayerInventory`'s four-space prototype capacity, `add_item`, `try_add`,
  `get_quantity`, `remove_item`, `try_remove`, `move_item`, and `clear`.
- Accepted and rejected changes, including unknown IDs, zero amounts, full
  stacks, full inventory, invalid moves, and checks that rejected add/remove
  operations do not partially change stored quantities.
- `inventory_changed`, including one emission for each successful mutation and
  no emission for no-op or refused operations.
- Every `InventoryUsage` forwarding method, both with an assigned inventory
  and with no assigned inventory.

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
correct if deferred co-op is later approved.

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
Connect it to `PlayerInventory.inventory_changed` to refresh after each successful
mutation.

Before adding transactional consumption, transfers, saves, or multiplayer syncing,
extend `PlayerInventory` with explicit methods and tests. Do not mutate
`inventory` or `quantities` from outside this folder.
