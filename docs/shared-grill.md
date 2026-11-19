# Shared ship grill

The galley now opens a side panel instead of a timing minigame. Walk next to the
existing galley art and press **E**. Press **E** or **Esc** to close. Several
crewmates can use the same grill together; nobody owns an exclusive cooking lock.

## Using it

- Drag sea bass from the hotbar anywhere on the grate. Each drop places one fish.
  Shift-clicking sea bass places one in a convenient position. Up to eight fish
  can cook together; placement is not restricted to a slot grid.
- Drag or shift-click wood or coal into the single fuel slot. It holds up to 30
  of one fuel type. Click it to withdraw unburned fuel before changing types.
- Fish take eight active cooking seconds. Their bars fill while cooking; steam,
  glowing coals and sizzling indicate active heat. Green bars and READY identify
  finished fish. A short chime plays when a fish finishes while the panel is open.
- Click a finished fish to collect cooked fish. If the bag is full, the meal
  drops beside the sailor. Clicking unfinished fish returns it raw and discards
  that fish's cooking progress.
- Wood provides 12 seconds of shared heat; coal provides 36. All unfinished fish
  cook simultaneously. One unit is consumed when needed, then its remaining heat
  is shown in the meter. No fish cooking means no fuel or remaining heat is used.
  Running out pauses progress; refueling resumes it. Finished meals never burn.
- New voyages start with six wood and four coal in the chest. Older hosted saves
  receive this grant once. If their chest is full, overflow appears at the galley.

## Code and networking

`Cook.gd` (`ShipGrill`) owns fish IDs, normalized placement positions, cooking
progress, fuel stack, remaining heat and the starter-grant flag. Inspector exports
on the Cooking node configure cook time, fuel duration, capacity and reach.
`advance()` spends only actual active cooking time, including the exact part of
an oversized frame needed to finish the final fish.

`scripts/inventory/grill_panel.gd` draws the grate and food at UI resolution.
Steam and sound are local presentation, not network traffic. Reduced Motion
hides rising steam; Effects/Master volume and unfocused mute apply to sounds.
`scripts/inventory/inventory_hud.gd` routes drag, shift-click and collection.
The main HUD excludes the grill rectangle from its generic drop-on-deck target.

Solo and multiplayer use the same model and item-transfer logic. Online, only
the captain advances it. Reliable `grill` commands request fish placement, fuel
insertion, collection or withdrawal. The captain verifies the panel is open,
the sailor can handle items and is in reach. Inventory-consuming commands also
check the current inventory view revision. Fish are removed by unique ID before
items are granted, so racing or repeated collection commands cannot duplicate a
meal. Fuel and meal overflow use the existing shared floor-item service.

The ordinary 20 Hz world snapshot includes the shared grill and each sailor's
panel-open state. Late joins see current progress immediately. This adds no
HTTP polling, Cloudflare database writes, or separate per-fish network timers.
Protocol is `holy-ship-coop-6`; refresh older browser tabs. Local hosted saves
include grill state and accept previous protocol 1–4 saves, granting starter fuel
only when their grill grant flag is absent. Browser voyages now persist in three local save slots; see [save slots](save-slots.md).

## Validation

- `tests/grill.gd`: fuel conservation, pause/resume, free placement, save/snapshot
  roundtrip, full-bag drops, stale commands, duplicate collection, capacity, reach.
- `tests/network_smoke.gd`: host + two guests opening one grill, placing fuel and
  fish remotely, observing completed progress and racing to collect one meal.
- `tests/menu_flow.gd`: menu/gameplay transitions and surrounding inventory UI.

Run Godot with `--headless --path . --script tests/grill.gd -- --settings-test`.
Omit `--headless` and add `--capture` for `.godot/grill-preview.png`.

Latest validation: 21 grill checks, 55 menu checks, and 32 host/two-guest checks
passed. The three-player checks also passed through the local WebSocket relay;
all 11 relay admission/departure tests passed. The rendered panel was inspected
at 1280×720. The legacy `tests/sailing_integration.gd` is not a release gate: its
startup harness and removed island-cutscene expectations are obsolete; the
current network suite covers shared sailing, fishing, swimming and reconnection.

Published-browser verification also passed: hosting, joining, no runtime errors,
navigation releasing a guest within one second, rejoining with the same identity,
and host-disconnect delivery.


## November 15 update: protocol 6

Guest fishing runs locally at 60 Hz. Reliable batches of six hold/release inputs
are sent at 10 Hz; the host replays the seeded fight and alone awards catches.
Snapshots do not overwrite the local tension bar. Stale, duplicate and excessively
fast input is rejected. Bite timing includes 750 ms transport grace.

Host departure marks the room ended before closing guest sockets. The directory
keeps a three-minute hidden tombstone so late guest disconnects cannot republish
the listing. Normal departure is immediate; crashes still rely on timeout cleanup.

Hosts now select one of three dated local saves. Browser storage is synchronous
localStorage; desktop saves use atomic files. Autosave runs every 20 seconds and
on normal exit/page navigation. Old native single saves migrate once. Protocols
1–6 load. See [save slots](save-slots.md) for persistence and capacity details.
