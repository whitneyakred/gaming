# Mining, item art and named markers — protocol 23

Feature branch: `codex/procedural-islands`. `systems-revamp` is not merged or changed.

## Playtest behavior

- Every registered item uses the matching pixel-art atlas, including previously vector-drawn fishing rods, spyglasses and wood. Atlas regions are trimmed once to their visible alpha bounds and cached, so the axe fills its inventory slot consistently. The original assets remain available for rollback.
- Four unstacked pickaxes are supplied in the second (port/left) ship chest on a new voyage. This keeps the fourth carrying slot available for loot. Older saves receive the kit once when upgraded, subject to available chest capacity; a full chest cannot receive the kit. Protocol-23 saves do not replenish tools on reconnect.
- Equip a pickaxe, stand near a rock and click/tap toward it. Three hits create rubble and drop three stone. Rocks replenish after five minutes on the host clock; remaining time survives save/reload. Axes cannot mine rocks, and pickaxes cannot harvest trees. No ores are included.
- Palms drop one wood and two coconuts. Broadleaf trees still drop three wood. Hold the use button with a coconut selected to eat one and restore two hunger points, capped at full hunger.
- Stumps, rocks, bushes and trees sort against each land player's displayed ground position. Standing in front of a stump draws the character over it; standing behind reverses the order. World drops retain their existing ground rendering.
- Map destination dots show their owner's current crew name. Colors, shared placement and click-again clearing remain unchanged. Clue circles have a minimum radius of 8,500 world units and expand far enough to contain at least three ordinary islands, including their footprint bounds. Circle rendering clips at the map frame. Coastlines and saved island positions are unchanged.

## Networking and rendering

Rock placement uses an independent seeded random stream after tree generation, preserving existing tree IDs and stump saves. Harvesting reuses host-owned validation, cooldowns, reliable modified-resource state and shared floor drops. Local swings remain immediate; swaying, chips and drawing are not streamed. Palms reserve room for both loot stacks before applying damage. New network semantics use protocol 23 with a matching relay; saves from protocol 22 remain supported.

Foliage uses a reusable pool of draw nodes only for the peak number of visible props, rather than a permanent node for every plant in the world. Visible props and the crew receive ordered draw depths after movement presentation. Distant islands are rejected before inspecting their props. The item atlas is read once for alpha bounds; cropped atlas textures and source pixels are shared and cached.

Trunks and rocks remain pass-through scenery. Collision, ores and crafting are outside this change. A physical-phone/cross-network playtest remains necessary; local tests cannot establish cellular latency.

## Validation

- 3,328 foliage/resource checks: tool restrictions, one loot grant, palm quantities, coconut consumption, depth order in both directions, all catalog icons, deterministic rocks, marker-region coverage and existing harvesting tests.
- 12 saved-world checks, including persistent mined rubble and felled trees.
- 27 checks across three real relay clients for mining, shared drops, regrowth, shared marker positions and owner names.
- Existing responsiveness (86), world interactions (32), survival (84) and movement smoothing checks passed. Relay service tests: 19 passing.
- The final frozen-export full three-client relay scenario passed all 84 checks; browser host/join, direct WebRTC and forced relay fallback passed without runtime errors.
- Browser rendering inspected for hotbar size, rocks, stump ordering, enlarged key circles and owner labels. Intel UHD at 1280×720: isolated island frame sample approximately 12.1 ms median, 18.2 ms p95, no runtime errors. Native foliage/rock build measured about 39 ms.
- One run concurrent with asset compression, service load tests and browser benchmarking hit a stale inventory fixture/drop failure and downstream checks. The isolated gameplay rerun passed. The fixture now waits for the actual host inventory revision and guest drop snapshot, and reserves the receiving player's pickup space instead of depending on the earlier chest race winner. A later export rebuilt assets watched by the local development relay and interrupted that test session; final verification uses frozen assets and no concurrent exports.

## Artwork provenance and prompt

Saved asset: `assets/items/pixel_items.png`. Created with the **built-in image-generation tool**, using `assets/terrain/foliage.png` as a style reference. Transparent source preserved; Godot atlas regions crop padding without rewriting the image. Row-major atlas mapping is in `scripts/item-system/pixel_item_icons.gd`; cells 29–31 hold two world rocks and rubble. No new dependency or paid runtime service.

Exact prompt:

> Generate a cohesive production pixel-art inventory and resource SPRITE ATLAS for Holy Ship. Reference is style only: match its muted colors, dark pixel outlines, chunky hand-placed pixel clusters and modest dithering. Transparent background. Exactly EIGHT equal columns and FOUR equal rows, 32 assets, one centered isolated object per cell, no grid lines, no labels. Precise row-major order: ROW 1: iron axe with wood handle; iron pickaxe with wood handle; fishing rod with line and float; brass spyglass; three wooden logs; three gray stone pieces; black coal chunks; coiled rope. ROW 2: spool of string; folded leather hide; cream medical pouch with red cross; bronze key; silver key; gold key; whole coconut with one white opened half; blue-green raw fish. ROW 3: cooked golden fish on simple wooden skewer; gold coins; crab meat; orange-red mango; bananas; sliced papaya; corked water flask; brass compass. ROW 4: gunpowder pouch; jar of glowing fireflies; iron cannonball; lit wooden torch; honeycomb; rounded large gray-green boulder; angular large gray-green boulder; low broken rock rubble. Every asset fills about 75 percent of its square cell, equal perceived inventory size, with generous clean transparent margins and no overlap into neighbors. Boulders are top-down slightly elevated RPG world props, no ore veins or gems. All other objects are readable inventory icons. Consistent logical 32x32 pixel detail enlarged nearest-neighbor. Crisp pixels, no anti-aliasing, no gradients, no 3D rendering, no photo realism, no glossy UI badges, no scenery. Style closely matches the supplied pixel trees and axe. Production-ready genuinely transparent alpha.
