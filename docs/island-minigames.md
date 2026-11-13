# Island minigames

Nineteen islands sit on the sailing map. Sail into an island's yellow docking circle, walk to the stern, and press **E** to row over. Every island uses the shared `IslandGame` flow ([`island_game.gd`](../scripts/islands/island_game.gd)): a countdown with the pirate-ship track, a task, and the rowboat home. Finish the task, then walk back into the rowboat before time runs out. If time runs out, the island restarts.

There is no nearest-island text or arrow while sailing. You find islands by exploring. The yellow docking circle still appears when you are close to one.

Islands are solid. The ship can't sail over land. If the hull touches a shore, the ship scrapes along it, "Ran aground! Steer away from the shore." shows, and you steer (and trim the sail) to get clear. Running aground on the dock side of an island, within **Aground Docking Distance** (330 px) of its dock point, anchors you just like the yellow circle. The anchoring move is planned so the hull never crosses land.

- **Coastlines:** each island on the map (`scenes/ship.tscn`, under `Islands`) has a `Land/Coast` CollisionPolygon2D, traced from the island art and shown as a blue outline in the 2D view. If you move or rescale an island's `Sprite2D`, select `Coast` and drag its points to match. `Land` takes no part in physics (collision layer and mask are 0); only the ship reads it.
- **Hull:** the ship's outline is **Hull Outline** on the `Ship` node (Collision group). An empty outline turns land collision off.

## What you collect goes into your bag

Everything you pick up or win goes into the crew member's inventory (`PlayerInventory`). The bag is shown along the bottom of the island HUD, with a short "+N Item" note each time something is added. The inventory lives in the `VoyageState` autoload ([`voyage_state.gd`](../scripts/voyage_state.gd)), so it is the same bag on the ship and on every island. It is no longer reset by each scene change.

- **Treasure rewards** (Treasure Island, Tiki Totems, Skull Rock Ruins, Smuggler's Den, Turtle Beach, Quicksand Flats, Slippery Rocks) give a random **5–30 gold coins** the moment you get the treasure, with a "N coins collected!" pop-up. Change the range under **Rewards** on the island's root node in the Inspector.
- Islands give items through `IslandGame.give_item(item_id, amount)`. If the bag is full, it says so and the item stays behind. A full bag does not block an island's objective.
- The voyage bag holds **12** different item types (`VoyageState.INVENTORY_SLOTS`). The prototype's 4 filled up after a couple of islands. `BR-inventory-slots` is still open (OI-11).
- The islands now give out 18 kinds of item, more than the bag holds, so a long voyage can fill it. The new rewards are Gunpowder, Dried Fish, Glow Jar, Cannonball, Torch and Honey (`scripts/item-system/items.gd`).

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
| Powder Keg Point | `powder_keg_point.tscn` / `powder_keg_point.gd` | Fuses catch on the kegs, faster as time goes on. **E** next to a burning keg stamps it out. 3 blasts loses. Last until the timer ends, then row home. | 1 Gunpowder per keg saved |
| Seagull Roost | `seagull_roost.tscn` / `seagull_roost.gd` | Gulls fly at the drying rack. **E** next to a gull shoos it. Each gull that reaches the rack takes a fish; lose them all and it's over. Last until the timer ends. | Dried Fish left on the rack |
| Turtle Beach | `turtle_beach.tscn` / `turtle_beach.gd` | Hatchlings crawl from the nests to the sea. Walk into crabs to chase them off. Get 8 of 12 to the water. | 5–30 coins |
| Quicksand Flats | `quicksand_flats.tscn` / `quicksand_flats.gd` | A grid of sand with one hidden safe path, new every visit. Start at the marked stepping stone. Quicksand sends you back (−3 s) and stays marked. Reach the chest, then walk back. | 5–30 coins |
| Firefly Hollow | `firefly_hollow.tscn` / `firefly_hollow.gd` | Dark, with a small circle of light. Fireflies blink on and off; **E** next to a glowing one nets it. Catch 6. | Glow Jar |
| Cannon Cove | `cannon_cove.tscn` / `cannon_cove.gd` | **E** at the cannon, **E** to lock the swinging aim, **E** to fire from the power bar. Sink 4 drifting rafts. Any move key steps away. | 2 Cannonballs per raft |
| Mosquito Marsh | `mosquito_marsh.tscn` / `mosquito_marsh.gd` | Stand still and hold **E** to light each of 5 torches while a swarm chases you. Lit torches' smoke keeps the swarm out. Bites cost 3 s; 4 bites loses. | Torch |
| Slippery Rocks | `slippery_rocks.tscn` / `slippery_rocks.gd` | Ice-slide puzzle: **E** at the mat steps on, and each move slides until a boulder or the edge. Land on the chest. **E** on the rocks starts over (−2 s). Best is 7 moves. | 5–30 coins |
| Bee Hive Hill | `bee_hive_hill.tscn` / `bee_hive_hill.gd` | **E** at a hive takes its honey and wakes bees that are faster than you. Stand at the foot of one of the painted trees to hide and lose them. Stings cost 4 s; 3 stings loses. Rob all 4 hives. | 1 Honey per hive |

The new islands' scripts and scenes are in `scripts/islands/` and `scenes/islands/`. Small helpers are in `scripts/islands/props/` (`IslandCrab`, `FruitBush`).

## Changing an island in the editor

- **Ground and dock:** the `Terrain` node is an instance of [`island_art.tscn`](../scenes/islands/island_art.tscn), which draws `assets/island_large.png` with [`island_terrain.gd`](../scripts/islands/island_terrain.gd) and, when the game runs, builds the wall that keeps the player on land (the sand and the dock, traced in **Walkable Outline**). Scale the `Terrain` instance if a minigame needs more room (Overgrown Isle uses 1.25 so the maze fits), and scale the player start, rowboat and camera limits with it. The dock is at the bottom centre: player start (1, 320), rowboat (30, 392) at scale 1. The painted cliffs are solid: `island_art.tscn` has a `Cliffs` body (the same three polygons as Treasure Island) covering the cliff faces, so you can't walk off the top of a cliff or climb one; the stairs by the dock are the way up. Coconut Island has its own `Cliffs` traced on its smaller art. Points on a cliff don't count as land for `IslandTerrain.contains_point()` and `random_point()`, so falling coconuts never land on one. The painted trees don't block movement; their trunks are the `Trees` markers in `island_art.tscn`, which Bee Hive Hill uses as hiding spots. Keep props off the cliff faces. Clearing **Art** brings back the old drawn placeholder.
- **Layout:** the marker nodes under `World` are positions, so drag them in the 2D view. Examples are crab spawns, trees, tiles, crates, guard stops (each child of `Guards` is one guard's loop), bushes, the pen, and the maze centre. On the newer islands: kegs, the fish rack, nests, shore spots and crab dens, the flats and shelf centres, the meadow, the cannon and raft lanes, torches, hives and hiding bushes. Slippery Rocks' boulders and chest are grid cells in the Inspector (**Shelf → Boulders**, **Chest Cell**); if you change them, update **Par Moves** too.
- **Difficulty:** time limits are on each root node (**Timer → Time Limit Seconds**). Each game's own knobs are in its Inspector group: crab speed, coconut spawn rate, round lengths, meter speed, guard speed and view distance, maze size, and number of parrot orders.
- **Map position:** in `scenes/ship.tscn`, select a node under `Islands` and move it. Its Sprite2D is a tinted reuse of the existing island art until real art exists.

## Testing

```text
godot --headless --path . --script res://tests/island_minigames.gd
godot --headless --path . --script res://tests/island_collision.gd
```

`island_collision.gd` sails into every island from both sides and checks that the hull never overlaps land on any frame (including the anchoring move). It also checks that the far side blocks without docking, that the dock side anchors, that a glancing course scrapes along the shore, and that you can turn and sail off after running aground.

The test loads every island, walks to the rowboat, and plays each game: it herds, dodges, steps tiles, chops, pushes boulders, gets spotted, finds the compass, and fills parrot orders. It checks that rewards land in the inventory, that treasure gives 5–30 coins, and that the bag is still full back on the ship. It also plays the nine newer islands: it stamps fuses, shoos gulls, saves hatchlings, sinks in quicksand and follows the safe path, nets fireflies, fires the cannon, lights torches under attack, solves the slippery rocks in 7 moves, and hides from bees. It does not replace playing them for feel.
