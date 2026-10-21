# Project Glossary

**Project:** Holy Ship
**Team:** Team 13 (Gaming)
**Client:** None — student-led project; product decisions belong to the development team.
**Version:** 0.3

## Purpose and Project Context

This glossary defines the vocabulary of Holy Ship, a top-down 2D sailing/survival game. The current milestone is single-player; co-op remains deferred design. Definitions describe domain concepts, not automatic implementation commitments. [Vision and scope](vision-and-scope.md#43-mvp-scope) owns milestone status; [business rules](business-rules.md) owns formulas and constraints; [use cases](use-cases.md) owns behavior.

## Conventions

- Use **player** for the human, **crew member** for the character, and **development team** for the students.
- Use **Holy Ship** as the project name and **Paradise Island** as the destination name.
- Use preferred terms below; synonyms and historical ideas are explicitly marked.
- Keep numerical rules in the business rules and tuning TBDs in their source use cases.
- Current code is a prototype and may not yet satisfy the planned contract.

## Revision History

| Date | Version | Description | Author |
|---|---|---|---|
| 2026-09-11 | 0.1 | Initial project-specific glossary based on the earlier prototype | Leiton Peterson (with AI assistance) |
| 2026-09-13 | 0.2 | Align vocabulary with the Miro main game loop and feature board | Leiton Peterson (with AI assistance) |
| 2026-10-20 | 0.3 | Align with repository use cases and rules; define missing referenced terms; distinguish current prototype, planned mechanics, and deferred co-op | AI-assisted consistency review |

## Definitions

### Challenge

An island activity with an objective and outcome. The prototype has timed coconut-collection and treasure-digging games; the general planned contract is `UC-ISLE-complete-challenge`.

### Chest

An item container. The planned deck chest is shared ship storage; wreck loot chests and treasure chests have different sources. Storage behavior belongs to `UC-SYS-shared-inventory`.

### Chunk

A bounded ocean/world section generated or recycled independently to support indefinite travel. A chunk is an implementation unit; it need not equal an event Tile.

### Cooperative Play

Deferred play in which multiple players operate one ship. The retained design targets one Host and up to three additional players under `BR-session-cap-4`; the current milestone is single-player. **Synonym:** Co-op.

### Crew

The characters responsible for the ship. The current milestone has one player-controlled crew member; the term does not imply implemented NPCs or multiplayer.

### Crew Member

An individual character controlled by a Player. Use this term for the character’s position, inventory, and survival stats, not for a development-team member.

### Deck

The walkable area aboard the ship. The prototype bounds movement with collision. Planned plank/ladder behavior is specified by `UC-DECK-move-on-deck` and `BR-deck-bounds`.

### Development Team

The Team 13 students who design, implement, test, and document Holy Ship. There is no external client; product decisions belong to this team.

### Docked Ship

A ship stopped at an island docking point. The prototype docks when sailed into range. The older docked-start concept is not a claim about the current launch scene.

### Event

A planned encounter selected when entering a Tile. `UC-EVT-generate-event` and `BR-event-roll-once-per-tile` govern selection; tables and probabilities remain TBD. **Synonym:** Random Event.

### Extraction Point

An earlier open idea for securing loot. It is not a separate approved extraction or persistence system; Paradise Island is the planned voyage destination.

### Fatigue

The planned remaining energy stat: higher values mean more energy, normal activity depletes it, and rest restores it. FTG owns this stat; zero invokes SURV pass-out recovery. Do not substitute the older term Stamina or add sprint costs without a requirement.

### Floating Chest

An earlier proposed ocean loot encounter. Collection and loot behavior lack an active dedicated use case; retained as an open idea, not implemented scope.

### Food and Water

Supplies used to restore Hunger and Thirst. Planned consumption is specified by `UC-SURV-consume-food` and `UC-SURV-consume-water`; exact amounts remain TBD.

### Game Loop

The planned cycle of sailing toward Paradise Island, operating stations, managing survival needs, and making optional island stops. The implemented loop is narrower: sailing, docking, island challenges, and returning to the ship.

### Gold

The planned shared voyage currency used for merchant purchases and sales. Prices remain TBD; see `BR-merchant-pricing`.

### Hammock

The planned resting Station. Deferred co-op capacity is two; rest restores Fatigue while Hunger and Thirst continue depleting. See `UC-FTG-rest`.

### Heading

The direction the ship points, distinct from wind direction, sail angle, and the direction a crew member faces.

### Helm

The steering Station used to change the ship’s heading. **Synonyms:** Wheel, Steering station. Steering is the action, not a separate station type.

### Host

The player who owns a deferred LAN co-op Session. Applicable single-player session-control permissions belong to the local player; this does not require a server or networking.

### Hull Damage

Damage represented in the planned SHIP system by open leaks and Repair Spots. Integrity and Stability are separate values; see `BR-capsize-conditions`.

### Hunger

The planned remaining nourishment stat, restored by food and depleted during conscious, unpaused play. Zero triggers Pass Out; see `BR-stat-depletion-rate` and `BR-pass-out-recovery`.

### Hunger and Thirst

The two planned survival needs maintained by SURV. See the individual Hunger and Thirst entries; Fatigue is owned by FTG.

### Illness

The planned temporary effect of eating raw non-fruit food. It adds fatigue drain subject to a provisional floor and duration; exact tuning and resumption after rest remain TBD (`OI-12`).

### Integrity

The planned hull condition derived from open leaks, distinct from Stability. Its formula and capsize trigger live in `BR-capsize-conditions`.

### Inventory

Items held by a crew member or container. The planned slot/stack contract is `BR-inventory-slots`; the prototype instead stores four distinct item types by default with per-item limits. This difference is an implementation gap, not two competing definitions of the planned rule.

### Island

A land location visited during a voyage. The prototype has Coconut Island and Treasure Island with rowboat access. Broader resources, shipwrecks, and procedural placement are planned.

### Item

A kind of collectible or usable object defined by a stable item ID. Shared item metadata is separate from the quantities held in an Inventory.

### Lookout

A planned Station that expands the view. Its camera behavior belongs to `UC-NAV-use-lookout`; it does not reveal extra map tiles automatically.

### Loot

Items obtained from gathering, challenges, chests, or encounters. Loot does not imply a large crafting, progression, or persistent-storage system.

### Map

The planned voyage chart of visited tiles and discovered islands, with optional Pins. It shows island information, not individual item locations.

### Merchant

A planned trader that exchanges items for Gold. See `UC-EVT-trade-with-merchant`; stock and prices remain TBD.

### Minimal MVP

The narrow playable prototype, currently single-player sailing, station interactions, docking, rowboat travel, and timed island games. The stationary deck-only prototype is an earlier milestone. See [the prototype guide](../minimal-mvp.md) for implementation status.

### Overboard

A crew member in the water outside the ship. Plank entry and ladder return are planned; current island travel uses the Rowboat.

### Overboard Rescue

An earlier open idea for helping someone return aboard. It is not a specified rescue subsystem or NPC requirement.

### Paradise Island

The planned voyage destination in `UC-PROG-reach-paradise`. Arrival behavior has a use case, while some details remain TBD; it is not implemented by merely completing a prototype island challenge. **Earlier name:** Paradise Cay.

### Pass Out

Temporary inability to act when Hunger, Thirst, or Fatigue reaches zero. It releases station claims and recovers under `BR-pass-out-recovery`; it is not permanent death.

### Pin

A planned map marker with a straight-line distance from the ship. The limit and overflow policy remain TBD in `BR-pin-limit`.

### Plank

The planned deck exit into the Overboard state. It differs from the rowboat interaction used for current island access.

### Player

The human controlling a Crew Member. The current milestone supports one local player.

### Random Event

See Event. This is specified planned behavior, not a claim that an event generator is already implemented.

### Repair

The planned action that closes a leak at a Repair Spot, consumes Wood from the deck chest, and restores Integrity under `BR-repair-cost`.

### Repair Spot

The planned interactable location of one open leak. Joint repair and multi-crew capacity are deferred co-op design; they do not change the per-repair material charge.

### Resource

A gatherable gameplay supply, such as fruit or wood, or its island source. This domain term differs from Godot’s `Resource` class used to store data.

### Rowboat

The vessel used to transfer a crew member between the ship and an island dock. The prototype uses a cutscene and scene transition. Deferred passenger capacity remains TBD under `BR-rowboat-capacity`.

### Sail

The Station-controlled sail whose deployment and angle influence propulsion. Sail adjustment differs from steering at the Helm; exact planned rotation limits remain provisional.

### Sail Adjustment

Changing the Sail’s orientation relative to the ship and wind. **Synonym:** Sail trim. Raising/lowering the sail is a separate action.

### Session

One running period of play. The current session is local; a deferred co-op session has a Host. A Voyage is the journey within that session; quitting discards unsaved voyage state.

### Ship

The vessel carrying the crew and its stations. It is the moving home at the center of gameplay. **Synonyms:** Boat, sailboat.

### Shipwreck

A planned island wreck containing a loot Chest. Salvaging belongs to `UC-ISLE-salvage-shipwreck`; it is distinct from a Floating Chest.

### Sprinting

An earlier movement idea, not an approved current sprint mechanic. Normal Fatigue depletion does not by itself imply extra sprint drain.

### Stability

The planned WAVE value representing resistance to capsizing from rough seas. It is separate from hull Integrity; either zero condition can trigger a capsize under `BR-capsize-conditions`.

### Stamina

An earlier movement-resource term. Current survival use cases specify Fatigue instead. A separate sprint/swim stamina system has not been approved; historical references do not authorize one.

### Station

A reusable interaction location for a ship duty. Claims, capacity, and release are defined by DECK; the station delegates gameplay changes to its owning system.

### Steering

Changing ship Heading through the Helm. It is separate from Sail Adjustment.

### Storm

A planned rough-weather event affecting Waves and damage intervals. Exact intensity, duration, and wind behavior remain TBD.

### Swimming

Planned movement while Overboard. DECK/ISLE designs defer swimming to islands in favor of rowboat access for the current milestone; a separate stamina cost is not established.

### Thirst

The planned remaining hydration stat, restored by water and depleted during conscious, unpaused play. Zero triggers Pass Out.

### Tile

A logical map region identified for discovery, ship tracking, and event selection. It is not necessarily a rendered ocean Chunk; size and coordinate mapping remain TBD.

### Treasure Chest

Loot uncovered by digging on an island. The prototype treasure challenge does not implement every planned storage-chest behavior.

### Voyage

The planned journey toward Paradise Island, with sailing, survival, and optional island visits. Capsizing continues that voyage under `BR-capsize-reset`; quitting discards it. Full voyage/session management is not yet implemented.

### Water Barrel

The planned shared Station that accumulates drinkable water and refills a Water Bottle. Rates and capacities remain TBD in `BR-barrel-fill-rate`.

### Water Bottle

The planned personal water container filled from the Water Barrel and used to restore Thirst. Its capacity remains TBD.

### Waves

The rough-weather effects governed by WAVE, distinct from the prototype’s decorative ocean pattern. See `BR-waves-rough-weather-only`.

### Wind

The direction and strength used by the sailing model. Current wind-driven propulsion does not imply the planned random wind-change scheduler is implemented.

### Wind Direction

The direction the wind blows toward in world space, not the direction it comes from. It differs from ship Heading and sail angle.

### Wood

The planned repair material consumed from the deck chest under `BR-repair-cost`. No registered wood item ID or amount has been agreed; Rope is not an approved substitute.
