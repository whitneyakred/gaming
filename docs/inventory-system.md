# Inventory, ship storage and floor pickups

This integrates the fixed-slot containers, chest, drag UI and pickup rules from
`inventory-system` (notably `5abe2b6` and `1df9c2d`) into the current single-player
voyage. The old network/session dependencies were removed. `inventory-basics`
was already included; `inventory-ui` supplied the existing item PNGs.

## Play

In Godot, choose **Debug > Run Project** (F5).

- **1–4**, mouse wheel, or click: select a hotbar slot.
- The original parchment-and-bottle hotbar is the entire inventory: **four slots total**. Store spare supplies in the chest.
- Approach the wooden chest on the starboard deck, forward of the cooking station.
  **E / Space** opens its eighteen slots. **E / Space / Esc** closes it.
- Drag a whole stack between slots to move it. Matching stacks merge up to the
  item's limit; different items swap. Empty slots retain their positions.
- **Shift-click** with the chest open transfers as much as fits to the other
  container. Any remainder stays in the original slot.
- Drag a stack outside the chest and hotbar to drop it **at your feet**.
  Releasing over panel padding cancels. There is no throw-to-cursor behavior.
- Step away from a dropped item and walk back to collect it. Full bags leave it
  on the floor; partially fitting pickups leave the remainder. Leave/re-enter
  to retry after freeing space. Dropped deck items move with the ship.
- Hover for an item's name, description and stack limit. Slots show icons and
  quantities. The selected hotbar slot does not yet equip or consume items.

The four-slot hotbar works on islands too. Handling items is disabled while swimming, rowing,
using a station, paused, or viewing the map. Opening storage stops walking;
closing it restores walking. Islands' challenge timers continue running.

Chest contents and loose items persist between island/ship scene transitions.
Losing an island challenge restores both the bag and that island's floor items
from arrival, so dropping an item cannot duplicate it during rollback. The starter
rod is granted once per voyage, including when it has been stored or dropped.
Restarting the game/new voyage clears everything; this is not disk saving.

## Implementation

- `scripts/inventory/ship_inventory.gd`: reusable fixed slots and stack operations.
- `scripts/inventory-system/player_inventory.gd`: existing gameplay API, now backed
  by those slots. `inventory` and `quantities` are derived read-only summaries.
- `scripts/inventory/inventory_service.gd`: validates proximity, station state,
  drag revisions and pickup entry. Ship-local coordinates follow deck motion.
- `scenes/inventory/inventory_system.tscn`: reusable service, floor renderer and HUD.
  The ship includes it; `IslandGame` attaches it with chest access disabled.
- `VoyageState`: persistent player inventory, chest and floor dictionaries keyed
  by scene. No network architecture was imported.
- `assets/items/`: original PNGs plus editable 24-grid SVG pixel icons. The item
  catalog assigns textures; UI components only display `ItemData.icon`.

Select **Ship > InventorySystem** in the **Scene** dock and use the **Inspector**
for **Storage Slots**, **Storage Position**, **Interaction Distance**, and
**Pickup Distance**. Storage size applies when the voyage first creates its chest.

## Validation

Use your Godot executable in place of `godot`:

```
godot --headless --path . res://tests/inventory_integration.tscn
godot --path . res://tests/inventory_mouse.tscn
godot --headless --path . --script res://tests/inventory_test.gd
godot --headless --path . --script res://tests/item_system_test.gd
godot --headless --path . --script res://tests/voyage_inventory_test.gd
godot --headless --path . --script res://tests/island_minigames.gd
```

The rendered mouse suite uses native Godot GUI drag events, Shift-click and
padding cancellation. Append `-- --capture` to save a populated inventory preview
to `.godot/four-slot-chest-open.png` and `.godot/four-slot-chest-closed.png`; supplies are seeded only in that test.

The ship chest uses generated transparent sprites in `assets/props/`. Its lid
opens while the storage interface is open and closes when the interface closes
or interaction becomes unavailable. Both states share the same base alignment.
See `assets/props/chest-art.md` for the generation prompts.
