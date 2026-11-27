# Prop collision and simplified UI — protocol 24

Pushed on `systems-revamp` and deployed from `5a5b1d6`; see [release and rollback](networking-release-rollback.md).

## Player-facing changes

- Removed proximity interaction popups entirely. Space and E still interact.
- Inventory hover names appear immediately above the slot. No description, stack limit or mouse-control instructions. Empty slots show nothing.
- The medpack atlas crop excludes stray transparent pixels and its slot artwork is slightly larger.
- Healing shows a green progress ring; eating shows a blue ring. Both render above the character and scenery, using the character's displayed position.
- Totems share the foliage/player foot-depth order: players behind are covered, players in front cover the totem. Cooldown text stays readable and a yellow ring drains from full to empty over the existing five minutes, based on the shared clock.
- Embedded challenges retain the normal sailing-camera zoom and character scale. The camera follows the challenge avatar. Completing the objective automatically ends the challenge after a short success beat; the obsolete exit area is removed. Pickup `+item` toasts are suppressed.

## Collision and multiplayer

`PropCollision` indexes deterministic scenery in 160-pixel spatial cells. Player movement sweeps an eight-pixel foot radius against nearby circles and slides along contact, using the same code for host simulation and client prediction/replay. Trunks use radius 9 × art scale; rocks 23 × art scale; totems 18. Stumps and rubble reduce to 6 and 10 × art scale. Bushes remain soft, pass-through scenery. Existing buildings, ship walls, sanctuary gates and puzzle obstacles retain their collisions. Coconut and bee-puzzle trees also receive small physical trunk shapes in their isolated physics world.

Fast motion cannot tunnel through a prop. Players already overlapping a regrown prop or a teleport destination can move out without being trapped. Only nearby spatial cells are queried; there is no full-world collider scan or physics body per generated plant. The shared harvest-state revision already tells guests when to shrink or restore a collider. No extra per-frame network fields are added. Corrected movement velocity prevents extrapolating a player through a prop while pushing against it.

Protocol 24 prevents older clients with pass-through movement from joining and fighting the new collision rules. Protocol-23 saves remain loadable and do not receive another set of pickaxes. Upgrade both clients and the Harbor together. Other players still see totem occupancy and rewards; puzzle actors remain participant-local.

## Validation

- 21 focused checks cover swept collision, sliding, overlap escape, reduced rubble collision, spatial-query bounds, totem depth, name-only hover data, medpack crop, ring draw order, normal zoom and automatic completion.
- 370 totem checks exercise all 19 challenge types, including automatic completion for each, cancellation, rewards, cooldowns and private inventories.
- All standalone puzzle regressions pass. Existing 3,320 harvesting/catalog checks, 86 responsiveness checks, movement smoothing, 12 save checks and 84 survival checks pass.
- Native visual captures check front/behind totem ordering, yellow cooldown, green healing, blue eating, the larger medpack, name-only hover labels and normal challenge framing.
- Three-process mining/regrowth replication passes 26 checks, including equal resource collision radii on host and both guests. World interaction (32 checks), TypeScript validation and the HTML5 release export also pass.
- The full native three-player gameplay scenario passes 76 checks. Live game hashes match the export; Harbor reports protocol 24.

Playtest on phone and desktop after refreshing both. Walk diagonally around trunks, rocks and totems; harvest and revisit regrown resources; hold food/medpack and release partway; complete a challenge without returning to its start. Real cellular latency and phone GPU performance still require device testing.
