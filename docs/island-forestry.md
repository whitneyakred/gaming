# Island forestry — protocol 22

This feature lives on `codex/procedural-islands`; `systems-revamp` remains at `3a26492`. The website playtest deployment uses the feature branch's exported files and matching relay, without merging the Git branches.

## Playing

Start a new voyage in an empty save slot to get generated islands and a starter axe. Old voyages intentionally retain their original terrain. Select the axe in the hotbar, approach a tree and click or tap toward its trunk. Three successful chops create a stump and drop three wood. Walk over the wood to collect it. Stumps regrow after five minutes of active host simulation; remaining regrowth time survives a save/reload. Bushes are decorative and sway in the wind. Ores and pickaxes are not included.

The beach-to-clearing paths have been removed. Minigame clearings and their approaches remain free of foliage. Four tree silhouettes and two bush silhouettes vary in scale, position and sway phase. Tree hits shake the crown, throw wood chips and play a wooden impact; the final hit fades/tilts the crown into a stump. Swing, impact and felling audio are synthesized locally without a new dependency. The character turns, leans and swings an attached axe/hand; this is procedural animation using the existing character art, not a new character sprite sheet.

## Authority, smoothness and cost

`IslandFoliage` generates up to 110 plants per ordinary island from its terrain seed. Plants share one texture atlas; only nearby visible plants are drawn, with no node or physics body for every plant. Trunks are currently pass-through scenery, with range/direction-validated harvesting. Trees fade around the local character to preserve visibility. Quest islands keep their open landmark layout.

Wind is presentation-only and sends no network traffic. The local axe animates immediately. The host validates land/access/UI state, axe ownership, finite aim, reach, facing and a 0.6-second cooldown. Only the host applies damage, creates loot or regrows trees. Other players receive swing serial/direction and reliably replicated tree changes. Unchanged foliage is omitted from motion packets, and unchanged received tree state is not recopied. A full floor inventory prevents further tree damage rather than losing its loot. Each stump produces loot only once.

Saves contain only modified trees, using remaining regrowth duration rather than a wall-clock timestamp. Protocol 22 accepts previous saves; older protocol-20 builds may not accept a save rewritten by 22. Use a new slot for this playtest to retain rollback saves.

## Validation

- Foliage: 2,718 checks, including deterministic placement, clearing exclusion, three hits, cooldowns, one loot award, regrowth, touch input, UI blocking, malformed state and compressed packet budget.
- Real saved-world restore: 11 checks, including a felled tree across session reload.
- Generated terrain: 4,218 checks; responsiveness: 86; survival: 84; smoothing: zero failures.
- Three-client forestry relay test: 23 checks. Full three-client gameplay relay: 84 checks. Service tests: 19 passing.
- Exported browser host/join, WebRTC traffic and forced relay fallback passed. Intel UHD browser frame sample: approximately 12.1 ms median beside an island, 12.3 ms p95; no runtime errors. Native foliage generation approximately 26–27 ms, in addition to terrain generation. Physical-phone and real cross-network latency still require playtesting.

## Generated artwork

Saved asset: `assets/terrain/foliage.png`. Generated using the **built-in image-generation tool**, with `assets/island_large.png` as a style reference. The alpha channel is preserved. The atlas has four columns and two rows: four trees above, two bushes/stump/axe below. Animation uses transforms and local effects rather than separate generated frames. No paid runtime service or dependency was added.

Exact prompt:

> Create one production sprite ATLAS for Holy Ship top-down pixel game. Reference image is STYLE REFERENCE ONLY. Transparent background, no ground or landscape, no text. Precisely 4 columns by 2 rows of equal cells, eight separate isolated assets centered in their own cells with generous transparent margins. Top row: four varied mature small island trees: round sage green broadleaf tree, taller olive broadleaf tree, irregular teal green broadleaf tree, curved palm tree. Bottom row: compact sage bush, wider olive bush, cut brown tree stump with visible rings and roots, small wooden-handled iron chopping axe angled diagonally. Trees have clearly visible short brown trunks underneath leafy crowns. Match original reference's muted sage greens, restrained dark outlines, crisp chunky pixel clusters, dithered leaf shading, orthographic slightly elevated top-down 2D RPG view. Pixel art logical 64x80 tree sprites enlarged with nearest-neighbor, no blur, no smooth gradients or photographic detail. All trees approximately same height and full silhouette visible. Bushes shorter; stump low. No baked ground shadows. Cohesive polished readable game sprites. Equal grid cells, no borders, no labels, NO grid lines. True transparent alpha outside all eight silhouettes.
