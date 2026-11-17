# Team work preservation review

Reviewed November 16, 2026 on `merge-everything-fest`, based on `systems-revamp`
at `01c0573`. Remote references were refreshed with `git fetch origin --prune`.
This records the inspected Git work; it cannot account for teammates' unpushed files.
No contributor branches were deleted, no wholesale merge was performed, and no
website deployment was made. An unmerged commit does not automatically mean its
functionality is missing: several systems were ported rather than merged verbatim.

## Reused now

| Area | Evidence and current use |
| --- | --- |
| Islands | `origin/final-island-creation` is already in this branch's ancestry. All 19 original scenes/scripts are retained and now launched from the 30 world islands' totems. Original challenge logic and artwork remain in use. |
| Item catalog and inventory UI | `origin/item-sys-update`, `origin/item-system-backend`, and `origin/inventory-ui` are already ancestors. `3639ae6` explicitly merged the inventory UI and reconciled voyage inventory. Existing item IDs and `PlayerInventory` API are used for minigame rewards. |
| Slot storage and dragging | `24f8881` explicitly ported chest storage and draggable inventory into solo voyages. Current `ShipInventory`, `InventoryService`, bottle hotbar, shared chest, and world drops implement that route. `origin/inventory-system` is not fully merged, but its work is not simply absent. |
| Fishing | The original station scene/script remain under `scenes/stations/` and `scripts/stations/`. Active gameplay uses `scripts/fishing/rod_fishing.gd` and the tension fight. These are different interactions; restoring the station would require intentionally choosing where it fits. |
| Cooking | The chopping/preparation activity remains in `scripts/galley_cooking.gd` and its scene. Current gameplay uses the shared fish grill in `Cook.gd`; presence of the old activity does not mean it is accessible from the current boat. |

## Work still worth integrating deliberately

| Priority | Existing contribution | What to preserve and how to connect it |
| --- | --- | --- |
| High | Gustavo Castillo: `origin/cooking-visuals-survival`, `3e0668d` (also in `origin/Survival-mechanic-Cooking-rehaul-documentation-update`) | Expanded cooking visuals, ingredient choices, recipe definitions, preparation feedback, and tests. `food_recipes.gd` and the later preparation changes are not in this branch. Reconnect preparation as its own boat activity, routing ingredients/meals through current inventory and survival. Do not replace the newer shared grill or add a second survival authority wholesale. |
| High | Ivan Lopez: `origin/storage-chest-creation`, `80da640`, added November 16 | Reusable `SharedChest`, `ChestInventory`, per-chest voyage storage, and tests. This is new work not yet merged. Current gameplay already has a working shared chest; adapt reusable container identity/UI behavior into that storage service, preserving this contribution without creating competing stores for one chest. |
| High | `origin/wreckage-and-ship-repair`, `70c0b3f` | `floating_wreckage.gd`, `ship_repairs.gd`, their tests, and design notes are absent from the working tree. Reuse them for floating wood and repairable hull holes, connecting pickups to current inventory and validating repairs on the host. This also gives Timber Isle's wood a second useful purpose beyond grill fuel. |
| Medium | Ivan Lopez: `origin/fishing-station-update`, `98f04d4` | Better result feedback, missing-item/full-bag handling, station release behavior, and the station test. Not merged. Keep the original station as a reusable alternative if desired; adapt its feedback and tests to the current rod flow where relevant. Simply merging the old station will not make it the active fishing system. |
| Medium | `origin/item-drop-and-pickup-sys`: `e9e4f78`, `9357ee8`, `4ef7c81`; also carried by `origin/dev-testing` | World pickups, UI integration, and persistent player inventory across scenes. Current code has equivalent drop/pickup/persistence behavior via `InventoryService` and `VoyageState`, but these commits are not ancestors. Compare item pickup presentation and tests before declaring the contribution fully reconciled. Preserve the existing per-peer inventory ownership when adapting it. |
| Review | `origin/inventory-system`: `5abe2b6`, `1df9c2d` | Four-slot inventory, chest transfers, item movement and rotation. A port exists (`24f8881`); compare remaining UI/rotation details and tests, rather than replacing the working resource model with the older version. |

## Other branch differences

- `origin/press-esc-to-pause` includes the Esc binding and the pickup branch. Current
  pause already supports Esc, so the unique behavior should be compared separately
  from its merge history.
- `origin/multiplayer-prototype` has the earlier LAN implementation (`ded29bf`).
  The current session system already provides more developed co-op behavior; do not
  replace it merely to make that branch an ancestor.
- `origin/initial-island-game` has a merge and node-UID changes beyond the current
  ancestry. The actual original island games are retained through later island work.
- `origin/ship-anchor` is not fully merged; the current boat already has an anchor
  station. Preserve station behavior/tests where useful instead of duplicating it.

Recommended next feature: restore the cooking preparation activity using Gustavo's
later art, recipe definitions, and tests, while keeping the current inventory and
shared grill. Handle the new chest contribution and hull repair feature in separate
focused changes. Keep contributor commits/branches available until each entry has
been reviewed with its author; a fresh implementation of similar behavior is not
proof that every part of their contribution has been integrated.

## Release follow-up

The preserved island integration was cherry-picked onto systems-revamp as 8794889
and deployed November 16 with the generated title artwork. The remaining branch
review recommendations above are unchanged; those systems were not merged by
this visual/release update.
