# Island minigames

Ten islands sit on the sailing map. Sail into an island's yellow docking circle, walk to the stern, and press **E** to row over. Every island uses the shared `IslandGame` flow ([`island_game.gd`](../scripts/islands/island_game.gd)): a countdown with the pirate-ship track, a task, and the rowboat home. Finish the task, then walk back into the rowboat before time runs out. If time runs out, the island restarts.

There is no nearest-island text or arrow while sailing. You find islands by exploring. The yellow docking circle still appears when you are close to one.

Islands are solid. The ship can't sail over land. If the hull touches a shore, the ship scrapes along it, "Ran aground! Steer away from the shore." shows, and you steer (and trim the sail) to get clear. Running aground on the dock side of an island, within **Aground Docking Distance** (330 px) of its dock point, anchors you just like the yellow circle. The anchoring move is planned so the hull never crosses land.

- **Coastlines:** each island on the map (`scenes/ship.tscn`, under `Islands`) has a `Land/Coast` CollisionPolygon2D, traced from the island art and shown as a blue outline in the 2D view. If you move or rescale an island's `Sprite2D`, select `Coast` and drag its points to match. `Land` takes no part in physics (collision layer and mask are 0); only the ship reads it.
- **Hull:** the ship's outline is **Hull Outline** on the `Ship` node (Collision group). An empty outline turns land collision off.

## What you collect goes into your bag

Everything you pick up or win goes into the crew member's inventory (`PlayerInventory`). The bag is shown along the bottom of the island HUD, with a short "+N Item" note each time something is added. The inventory lives in the `VoyageState` autoload ([`voyage_state.gd`](../scripts/voyage_state.gd)), so it is the same bag on the ship and on every island. It is no longer reset by each scene change.

- **Treasure rewards** (Treasure Island, Tiki Totems, Skull Rock Ruins, Smuggler's Den) give a random **5–30 gold coins** the moment you get the treasure, with a "N coins collected!" pop-up. Change the range under **Rewards** on the island's root node in the Inspector.
- Islands give items through `IslandGame.give_item(item_id, amount)`. If the bag is full, it says so and the item stays behind. A full bag does not block an island's objective.
- The voyage bag holds **12** different item types (`VoyageState.INVENTORY_SLOTS`). The prototype's 4 filled up after a couple of islands. `BR-inventory-slots` is still open (OI-11).

## The islands

| Island | Scene / script | How to play | Reward |
|---|---|---|---|
| Coconut Island | `scenes/island.tscn` / `collect_island.gd` | Walk over every coconut. | Coconuts |
| Treasure Island | `scenes/islands/treasure_island.tscn` / `treasure_island.gd` | Follow hot/cold and press **E** to dig. | 5–30 coins |
| Crab Cove | `crab_cove.tscn` / `crab_cove.gd` | Crabs run from you. Walk around behind them to herd them into the roped pen. | 1 Crab Meat per crab |
| Coconut Squall | `coconut_squall.tscn` / `coconut_squall.gd` | Shadows show where coconuts will land, so step out of them. 3 bonks knocks you out. When the timer ends, the storm stops and you row home. | Whole coconuts you pick up |
| Tiki Totems | `tiki_totems.tscn` / `tiki_totems.gd` | Watch the tiles light up, then step on them in order. 3 rounds. A wrong step costs time and replays the pattern. | 5–30 coins |
| Timber Isle | `timber_isle.tscn` / `timber_isle.gd` | **E** at a tree starts chopping. Press **E** when the marker is in the green zone. 3 chops fell a tree, and you need 3 trees. Any move key stops chopping. | 2 Wood per tree |
| Skull Rock Ruins | `skull_rock.tscn` / `skull_rock.gd` | Walk into a boulder to push it one square. Cover all 3 plates to open the shrine, then take the idol. **E** at the skull stone resets the boulders (−5 s). | 5–30 coins |
| Smuggler's Den | `smugglers_den.tscn` / `smugglers_den.gd` | Stay out of the guards' yellow vision cones; crates block their view. If you are spotted, you go back to the dock (−5 s). | 5–30 coins |
| Overgrown Isle | `overgrown_isle.tscn` / `overgrown_isle.gd` | A dark jungle maze with a small circle of light around you, new every visit. Find the compass, then find your way out. | Lost Compass |
| Parrot Point | `parrot_point.tscn` / `parrot_point.gd` | **E** at a bush picks one fruit. **E** at the parrot hands over its order. 5 orders. Handing over nothing it wants costs time. | Fruit you pick; 2 Fresh Water at the end |

The new islands' scripts and scenes are in `scripts/islands/` and `scenes/islands/`. Small helpers are in `scripts/islands/props/` (`IslandCrab`, `FruitBush`).

## Changing an island in the editor

- **Ground and dock:** the `Terrain` node ([`island_terrain.gd`](../scripts/islands/island_terrain.gd)) draws a placeholder island and, when the game runs, builds the wall that keeps the player on land. Change **Radius**, **Wobble**, **Shape Seed**, and the colors in the Inspector, and the 2D view updates. The dock is always at the bottom centre.
- **Layout:** the marker nodes under `World` are positions, so drag them in the 2D view. Examples are crab spawns, trees, tiles, crates, guard stops (each child of `Guards` is one guard's loop), bushes, the pen, and the maze centre.
- **Difficulty:** time limits are on each root node (**Timer → Time Limit Seconds**). Each game's own knobs are in its Inspector group: crab speed, coconut spawn rate, round lengths, meter speed, guard speed and view distance, maze size, and number of parrot orders.
- **Map position:** in `scenes/ship.tscn`, select a node under `Islands` and move it. Its Sprite2D is a tinted reuse of the existing island art until real art exists.

## Testing

```text
godot --headless --path . --script res://tests/island_minigames.gd
godot --headless --path . --script res://tests/island_collision.gd
```

`island_collision.gd` sails into every island from both sides and checks that the hull never overlaps land on any frame (including the anchoring move). It also checks that the far side blocks without docking, that the dock side anchors, that a glancing course scrapes along the shore, and that you can turn and sail off after running aground.

The test loads every island, walks to the rowboat, and plays each game: it herds, dodges, steps tiles, chops, pushes boulders, gets spotted, finds the compass, and fills parrot orders. It checks that rewards land in the inventory, that treasure gives 5–30 coins, and that the bag is still full back on the ship. It does not replace playing them for feel.
