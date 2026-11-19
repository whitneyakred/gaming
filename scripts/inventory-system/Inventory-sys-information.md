# Player inventory API

`PlayerInventory` extends the fixed-slot `ShipInventory` resource. The running
voyage owns the resource; player scenes, fishing, island rewards and UI share it.
See `docs/inventory-system.md` for controls, architecture and test commands.

The standalone resource defaults to four slots. `VoyageState` gives the active
player exactly four hotbar slots, with no additional bag slots. The ship chest has
eighteen. `max_inv_space` counts **stacks**, not distinct item types. A full stack
can overflow into another free slot. Removing a stack leaves an empty slot;
it does not shift the remaining slots.

- `add_item(item)` stores one item, returning whether it fit.
- `try_add(id, amount)` adds the entire amount or changes nothing.
- `add_items(item, amount)` adds as much as fits and returns the amount stored.
- `get_quantity(id)` totals the item across all stacks.
- `try_remove(id, amount)` / `remove_item(id, amount)` removes the full amount
  across matching stacks or changes nothing.
- `move_to(index, target, destination)` moves, merges or swaps exact slots.
- `transfer_to(index, target)` quick-transfers as much of a stack as fits.
- `remove(index, amount)` removes from a specific stack.
- `move_item(id, destination)` moves the first matching stack, for older callers.
- `capture()` / `restore(snapshot)` preserves exact slot positions for rollback.
- `clear()` empties the container.

Successful mutations emit `inventory_changed` and the Resource `changed` signal.
Snapshots are deep copies. `inventory` (unique definitions in slot order) and
`quantities` (totals by ID) remain derived summaries for existing callers; do not
assign to them or mutate `slots` directly. Use the mutation methods so the UI and
revision checks stay synchronized. `ItemData` is shared metadata, never per-player
quantity storage.
