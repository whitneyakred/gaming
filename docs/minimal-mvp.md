# Current Single-Player Prototype

**Project:** Holy Ship
**Status checked:** 2026-10-20 against the local source tree; this document describes implementation, not completion of the planned use cases.

The earlier stationary deck prototype now includes manual sailing, ship stations, docking, rowboat trips, and two timed island games. The current milestone remains single-player; co-op is deferred.

## Run and play

1. In Godot's Project Manager, click **Import**, select this repository's `project.godot`, and open the project. The file declares Godot 4.7 features and the Compatibility renderer; no exact patch version is mandated here.
2. Click **Run Project** or press **F5**. Walk with **WASD** or arrow keys; press **E** near a station to interact.
3. Follow the [sailing and island guide](sailing-integration.md) for sail, helm, docking, and rowboat controls. Islands are hand-placed world locations, not generated after a travel timer.
4. On Coconut Island, collect the coconuts and reach the rowboat before time expires. Treasure Island uses a digging challenge. Failure restarts the island challenge; success returns to the ship.
5. Raise the sail manually after returning. Press **F8** to stop.

## Scenes and scripts

| File | Current responsibility |
|---|---|
| [project.godot](../project.godot) | Main scene, controls, renderer, and ItemDatabase/Items autoloads |
| [main.tscn](../scenes/main.tscn) | Entry scene with ship and camera |
| [ship.tscn](../scenes/ship.tscn), [ship.gd](../scripts/ship.gd) | Moving ship, deck, stations, placed islands, docking, rowing, and island-return handoff |
| [ship_motion.gd](../scripts/sailing/ship_motion.gd) | Sail/wind propulsion and helm turning |
| [ship_station.gd](../scripts/sailing/ship_station.gd) | Sailing-station control and release |
| [player.tscn](../scenes/player.tscn), [player.gd](../scripts/player.gd) | Character movement, station lock, and per-player inventory |
| [ocean.gd](../scripts/ocean.gd) | Repeating decorative ocean visual; not a procedural world generator |
| [world_island.gd](../scripts/islands/world_island.gd) | World island positions and docking information |
| [island.tscn](../scenes/island.tscn), [treasure_island.tscn](../scenes/islands/treasure_island.tscn) | Coconut and treasure challenge scenes |
| [island_game.gd](../scripts/islands/island_game.gd) | Shared timed island-game flow and return behavior |
| [collect_island.gd](../scripts/islands/collect_island.gd), [treasure_island.gd](../scripts/islands/treasure_island.gd) | Challenge-specific objectives |
| [coconut.gd](../scripts/coconut.gd), [rowboat.gd](../scripts/rowboat.gd) | Collection notification and island exit interaction |
| [Item system](../scripts/item-system/Item-sys-information.md) | Registered item metadata |
| [Inventory system](../scripts/inventory-system/Inventory-sys-information.md) | Small item-type inventory, quantities, and removal API |
| [sailing_integration.gd](../tests/sailing_integration.gd) | Existing automated checks for the integrated sailing/island loop |

## Inspect and tune in Godot

1. In the **FileSystem** dock, double-click `scenes/ship.tscn`. Select **Ship** in the **Scene** dock to inspect exported sailing, docking, and rowing properties in the **Inspector**.
2. Open `scenes/player.tscn`, select **Player**, and change **Walk Speed** to tune movement.
3. Choose **Project > Project Settings > Input Map** to inspect key bindings.
4. In the ship scene, select **DeckBoundary/CollisionPolygon2D** and edit vertices in the **2D** viewport. Keep **Build Mode** set to **Segments** for the perimeter.
5. Open an island scene and press **F6 (Run Current Scene)** to test it directly. Select its root node to adjust exported challenge settings.

## Known limits and planned behavior

- Survival stats, fatigue/rest, leaks/repair, rough-weather capsize, map discovery, merchants, and full Paradise Island voyage management remain planned. Cooking currently uses separate fish/meal counters; fishing inventory and island challenge collection are not yet connected to meal hunger/healing effects. See [planned cooking/survival use cases](requirements/use-cases.md#area-cooking-cook); this documentation does not claim the loop is implemented.
- Two placed islands and a repeating ocean visual do not fulfill indefinite deterministic/recycled world-chunk travel.
- Ship/island transitions use limited static handoff state in `Ship`; general inventory/resource retention across scenes is not implemented. The proposed Voyage State component is in memory, not a save system.
- The prototype inventory defaults to four distinct item types with per-item stack limits. The planned six quick slots and 30-item stacks in `BR-inventory-slots` are not implemented.
- Current sail-angle tuning differs from the provisional arc in `BR-sail-rotation-limit`. See `OI-10`.
- The island countdown/pirate icon is challenge feedback, not a simulated pursuing pirate ship or a full-voyage loss condition.
- No networking, permanent saves, or published browser build is claimed. Preserve Web compatibility; configure a future export through **Project > Export**.

See [vision and scope](requirements/vision-and-scope.md#43-mvp-scope) for milestone boundaries and [open issues](requirements/OPEN-ISSUES.md) for outstanding decisions. Generated `.godot` caches are ignored and can be regenerated; keep source resources and their Godot identity/import files under version control.
