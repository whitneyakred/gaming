# Inventory milestone

Run the project with **F5**, then choose **Join Offline**, **Host ship**, or **Join ship**.
Each player starts with four empty pockets. The small wooden supply chest is on the
right side of the deck, just forward of the helm. Approach it to collect test supplies.

- **1–4**, **mouse wheel**, or click a pocket: select a slot.
- **F** near the chest: open/close shared storage; **Esc** also closes it.
- While storage is open, click a chest slot to take a stack or a pocket to store it.
- **Q**: drop the selected stack at your feet, aboard the ship.
- **G**: pick up the nearest loose stack within reach.
- Hover over slots for item descriptions and stack limits.

Transfers move as much as fits and leave the remainder in the source. Tools occupy
one slot each. Cod stacks to 10, water to 5, and rope to 25. Items dropped on deck
follow the ship through movement and rotation. Leaving a station is required before
handling supplies. Walking away closes storage. Disconnected crew leave carried
items aboard; reconnecting creates empty pockets, so joining cannot generate supplies.
Starting a new session resets the chest and clears inventories and dropped items.

This milestone covers carrying, selecting, storing, dropping and picking up. Food,
water and tools do not yet have use effects. There is no save system or bag pickup yet.

## Architecture

- `ShipInventory`: reusable fixed-slot container, stack limits, lossless partial
  transfers and snapshots. `add_capacity(2)` is the future bag extension point.
- `InventorySystem`: host-owned containers, nearby storage checks, per-sender rate
  limit, revision checks, drop identities and reliable updates only on changes.
  Clients send action/slot/revision; the sender ID comes from the connection.
  Late joiners receive current state; personal contents are sent only to their owner.
- `InventoryHUD`: local selection and presentation. It adapts to capacity, including
  six slots. `DeckItems` draws the chest and replaceable item icons in ship coordinates.
- `ItemData` remains shared definition data. Never put per-player quantities into it.

In the Godot **Scene** dock, select **InventorySystem** under **Main**. The **Inspector**
exposes **Starting Slots**, **Storage Slots**, **Storage Position** and
**Interaction Distance**. Keep Starting Slots at 4 for this milestone. Inventory state
is managed independently of the sailing station scripts. The network protocol is 5;
all peers must run this version with the same item catalog.

## Verification

Run `godot --headless --path . res://tests/inventory_smoke.tscn` for stack overflow,
partial transfer, snapshot isolation, pickup/drop, duplicate pickup, distance/stale
request rejection, disconnect/reset, hotbar keys and bag capacity checks.

For the real WebSocket test, run these in separate terminals, in order. The host
waits for both clients; run the late client after the first client exits:

```
godot --headless --path . res://tests/inventory_network.tscn -- --inventory-host
godot --headless --path . res://tests/inventory_network.tscn
godot --headless --path . res://tests/inventory_network.tscn -- --late
```

The test uses port 19081 and exits after checking authoritative transfers, late joins,
pickup and disconnect conservation. Substitute your Godot executable for `godot`.
For a rendered UI capture, run the smoke scene without `--headless` and append
`-- --capture`; output is `.godot/inventory-preview.png`. Tests are excluded from the
Windows export. Manual checks: two players race for the last stack, walk out of chest
range, drop supplies while sailing/turning, and pick them up from another player.
