# Paradise voyage milestone

Paradise is always marked at (0, -9900). Bronze lies in the western search
region, silver in the south, and gold in the east. Each region has a radius
of 3800 world units; the key island's precise position varies deterministically
with the voyage seed. The existing 30 ordinary islands remain alongside four
dedicated quest islands. Ocean rendering and red-water boundaries are unchanged.

## Playing

- Press **M** to open the voyage map. Large colored circles mark the search regions without labels.
  Question marks conceal undiscovered islands.
- Sail into a search region and explore. Approaching a key island reveals it.
- On each key sanctuary, walk to seals **I**, **II**, and **III**, pressing **E**
  at each in order. Out-of-order unlit seals reset the sequence; already lit
  seals are safe to revisit. Then press **E** at the central key pedestal.
- Keys can be earned in any order. They are non-stacking inventory items you can hold,
  drop, pick up, or store in a chest. Only one of each key may exist outside its
  pedestal. A lost key returns to the pedestal; completed seals stay completed.
- Sail north and land on Paradise. Approach the gate from the south and press
  **E** to insert your carried keys (one trip at a time is fine). All three
  inserted keys open the gate and leave your inventory. Enter through the gate and press **E** at the beacon
  to complete the voyage. You can continue exploring afterward.

The three-seal encounter and drawn islands are deliberately lightweight
placeholders, not finished boss fights. No crafting, combat, or PvP is added.

## Persistence

`VoyageState.paradise_quest` tracks issued/inserted keys, seals, gate state, and completion.
Physical keys live in ordinary inventories, chests, or drops. Older issued-key
flags without physical items return keys to their pedestals; already-open gates
remain open.
Existing hosted voyage saves include this dictionary and default old saves to
an unstarted quest. Solo voyages retain the project's existing session-only
behavior: returning to the title ends and resets the solo voyage.

## Extending the encounters

`scenes/islands/quest_island.tscn` is the reusable island scene. Select its root
in the **Scene** dock and use the **Inspector** to configure **Key Id**,
**Paradise**, **Radius**, and **Interaction Distance**. World generation assigns
the role and position when instantiating it. Replace the seal encounter with a
boss or puzzle and call `VoyageState.grant_key(key_id, player.player_inventory)` on success. World movement
checks `QuestIsland.blocks_path()` because swimmers and island walkers use
explicit world-space movement instead of deck physics.

Run the integration suite with:

```text
godot --headless --path . --script res://tests/paradise_journey.gd -- --settings-test
```

Use `--capture` without `--headless` to capture the map and Paradise under `.godot`.

## Developer teleport menu

The small **Dev tools** menu at the top left is enabled for testing. Click
its header to collapse or expand the six buttons: nearest island, Paradise,
bronze, silver, gold, and random island. Teleports bring the sailor aboard,
preserve inventory and quest progress, stop the ship, lower sails, and anchor
in collision-checked water near the destination. Teleports are unavailable
while dead, rowing, paused, viewing the map, or running an island challenge.
In an existing hosted session only the host can use the menu; crew come aboard too.

To turn it off for editor play and exported builds:

1. In the **FileSystem** dock, double-click `scenes/ship.tscn`.
2. Select the root **Ship** node in the **Scene** dock.
3. In the **Inspector**, find **Developer Tools Enabled** (use the property
   filter if necessary) and uncheck it.
4. Press **Ctrl+S**, then export normally with **Project > Export…**.

Recheck the same property and save to turn it back on. This is an explicit
scene setting, not a debug/release automatic switch: leaving it checked also
includes the menu in exported builds. Turning it off hides the UI and rejects
teleport actions. No code edit is needed.

Search circles disappear as soon as their key island is discovered (including
dev teleports). Discovered key islands keep their colored marker
without a text label. **Super walk** and **Super swim** independently toggle 8x
player movement speed. Click again to restore normal speed; disabling Developer
Tools Enabled also restores both speeds. Boosts are not saved between voyages.

## Ground item cleanup

Dropped stacks on deck and islands expire after 300 seconds of unpaused game
time, regardless of proximity. The drop age is saved with existing hosted
voyage snapshots and continues on resume; offline wall-clock time is not counted.
Picking up and dropping an item starts a new timer. Chest items do not expire.
A key that expires or is removed by death becomes available at its original
pedestal again. Inserted keys stay in the gate and are never reissued.
The voyage-complete and all-keys-secured screen banners have been removed.
