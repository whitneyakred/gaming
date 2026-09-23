# Use Cases
 
**Project:** Pirate Ship Co-op Sailing/Survival Game
**Team:** Whitney Akred, Leiton Peterson, Ivan Lopez, Liliana Matte, Gustavo Castillo, Shana Billiot
**Version:** 0.1
 
---
 
## Revision History
 
| Date | Version | Description | Author |
|---|---|---|---|
| 2026-09-13 | 0.1 | Initial use case list and first fully-specified use case (steering) | Whitney |
 
---
 
## 1. Introduction
 
### 1.1 Purpose
 
This document specifies the goals a player can accomplish within the pirate ship co-op sailing/survival game, in enough detail that a developer knows what to build and a tester knows what to check.
 
### 1.2 Scope
 
This document covers the following feature areas, derived from the team's brainstorm boards (Starting MVP, Main Gameloop, Features, Stations, Islands):
 
- `NAV` — Navigation & Sailing
- `SHIP` — Ship Systems & Maintenance
- `SURV` — Crew Survival
- `ISLE` — Island Exploration
- `TRADE` — Trading & NPC Encounters
- `LOBBY` — Session Setup
Use cases beyond `UC-NAV-steer-ship` are listed by name only in Section 3 and have not yet been fully specified (see Section 4 note).
 
---
 
## 2. Use Case Template
 
**UC ID and Name.** The identifier plus a concise name stating the value this use case provides to a user. Begins with an action verb.
 
**Created By** and **Date Created.**
 
**Primary and Secondary Actors.** This project has two actors: **Crew Member** (any player; appearance is customizable) and **Host** (a Crew Member who additionally manages the session — invites others, starts the game; session cap is 4 players).
 
**Trigger.**
 
**Description.**
 
**Preconditions.** Labeled `PRE-1`, `PRE-2`, ... Must be system-testable.
 
**Postconditions.** Labeled `POST-1`, `POST-2`, ...
 
**Main Success Scenario.** Numbered, alternating actor/system, present tense.
 
**Extensions.** Alternative flows and exceptions, numbered relative to the branching step (e.g. `4a`, `4a1`).
 
**Priority.**
 
**Frequency of Use.**
 
**Business Rules.** `BR-*` identifiers only — text lives in business-rules.md (not yet created for this project).
 
**Associated Information.** Data fields table, quality attributes, display/sort strategy, failure behavior for durable changes.
 
**Related Use Cases.**
 
**Assumptions.**
 
**Open Issues.** Mirror into OPEN-ISSUES.md (not yet created for this project).
 
---
 
## 3. Use Case List
 
| Area code | Feature area | Use cases |
|---|---|---|
| `NAV` | Navigation & Sailing | `UC-NAV-steer-ship` (specified below); adjust mast/sail direction; take small boat to nearby island; place flag on visited island |
| `SHIP` | Ship Systems & Maintenance | Repair hull damage/leak spots; rescue crew member overboard; manage floating chests |
| `SURV` | Crew Survival | Manage hunger/thirst; cook food / boil water (kitchen station); replenish stamina; recover from passing out (med kit / life preserver) |
| `ISLE` | Island Exploration | Land on beach; use treasure map to find chests; dig for buried treasure; find coconuts; complete island puzzle/challenge |
| `TRADE` | Trading & NPC Encounters | Trade with friendly pirates; evade/resolve encounter with enemy pirates; trade with NPC traders; earn/spend currency |
| `LOBBY` | Session Setup | Host starts session; crew member joins session; crew member customizes appearance; all players ready up |
 
*Only `UC-NAV-steer-ship` is fully specified so far. The rest of this list is a placeholder scaffold — each entry above should get its own `###` write-up in Section 4 before the team builds against it.*
 
---
 
## 4. Use Cases
 
## Area: Navigation & Sailing (`NAV`)
 
### UC-NAV-steer-ship: Steer the ship
 
**UC ID and Name:** `UC-NAV-steer-ship`: Steer the ship
**Created By:** Whitney
**Date Created:** 2026-09-13
**Primary Actor:** Crew Member
**Secondary Actors:** none
**Trigger:** A crew member approaches the steering wheel and indicates intent to take control (interact input).
**Description:** A crew member takes control of the ship's wheel in order to set the ship's heading and speed, which the crew must do continuously to survive and make progress toward islands and, ultimately, the paradise island.
 
**Preconditions:**
 
- PRE-1. The crew member is within interaction range of the steering wheel.
- PRE-2. No other crew member currently controls the wheel.
**Postconditions:**
 
- POST-1. The ship's heading and speed reflect the controlling crew member's input, adjusted for wind and nearby hazards.
**Main Success Scenario:**
 
1. The crew member interacts with the steering wheel.
2. The system assigns the crew member as the active helmsman and locks the wheel to them.
3. The crew member presses a directional input (WASD) to indicate the desired heading.
4. The system angles the ship gradually toward the desired heading rather than snapping instantly, simulating a boat's turning inertia.
5. The system adjusts ship speed based on wind direction and strength relative to the current heading.
6. The crew member releases the wheel.
7. The system returns the wheel to an unclaimed state.
8. Use case ends.
**Extensions:**
 
- **3a. No wind is present (becalmed):**
    - 3a1. The system caps ship speed at a significantly reduced maximum regardless of input.
    - 3a2. Flow rejoins the main scenario at step 4, with the reduced cap in effect.
- **5a. Ship is within a proximity threshold of an island or other hazard:**
    - 5a1. The system reduces ship speed to avoid collision, independent of wind conditions.
    - 5a2. Flow rejoins the main scenario at step 6.
- **5b. Crew member holds a consistent heading for longer than [TBD duration]:**
    - 5b1. The system applies a speed bonus modifier for as long as the heading is held.
    - 5b2. Flow rejoins the main scenario at step 6.
- **2a. Another crew member already controls the wheel when a second crew member attempts to interact:**
    - 2a1. The system denies the second crew member's control request.
    - 2a2. The system notifies the second crew member that the wheel is occupied.
    - 2a3. Use case ends for the second crew member; the first crew member's control is unaffected.
- **6a. Active helmsman moves beyond an auto-release distance from the wheel, or disconnects, without formally releasing:**
    - 6a1. The system detects the distance/disconnection condition.
    - 6a2. The system auto-releases the wheel on the crew member's behalf.
    - 6a3. Flow rejoins the main scenario at step 7.
**Exceptions:**
 
- **5c. Ship collides with an island, rock, or another ship despite speed reduction:**
    - 5c1. The system applies collision consequences to the ship (see Open Issues — exact effect and whether this invokes `UC-SHIP-repair-hull` is undecided).
    - 5c2. Flow rejoins the main scenario at step 6.
**Priority:** High
**Frequency of Use:** Continuous — used throughout nearly every play session; this is a core mechanic.
**Business Rules:** `BR-single-helmsman` (needs to be added to business-rules.md — not yet created for this project)
 
**Associated Information:**
 
| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| heading | Float (degrees) | 0–359 | N/A, local session state | Ship |
| speed multiplier | Float | Bounded by wind/hazard/bonus rules above | N/A | Ship |
| wind vector | Direction + magnitude | System-generated | N/A | Wind |
| hazard proximity threshold | Float (distance) | TBD — needs tuning/playtesting | N/A | — |
| sustained-heading bonus duration | Duration | TBD — needs tuning/playtesting | N/A | — |
| auto-release distance/timeout | Distance or duration | TBD | N/A | — |
 
Failure behavior: This use case does not make a durable/persisted change — if the session ends or a network issue occurs mid-control, no data is at risk of a partial write; the wheel simply reverts to unclaimed on next session state sync.
 
**Related Use Cases:** Possibly `UC-SHIP-repair-hull` (if collision triggers ship damage — undecided, see Open Issues).
**Assumptions:** Only one crew member can be an active helmsman at a time, project-wide (`BR-single-helmsman`). Steering is real-time, not turn-based.
**Open Issues:**
 
- What is the actual consequence of a collision (damage amount, temporary loss of control, does it invoke a repair use case)?
- What is the exact duration threshold for the sustained-heading speed bonus?
- What is the auto-release distance/timeout when a helmsman walks away or disconnects without releasing?
---
 
_(Remaining use cases from Section 3 — mast/sail direction, small boat to islands, flag placement, ship repair, overboard rescue, hunger/thirst/stamina management, island exploration, trading with pirates/traders, and session setup — are listed but not yet specified. Continue this document one use case at a time using the template in Section 2.)_a missing step or a missing extension._

_**Checklist for each use case:** Does the name start with a verb? Can the system test every precondition? Does every step alternate actor and system? Is there at least one extension per step that can fail? Does every business rule appear as an identifier only? Could a tester write test cases from this without asking you anything?_
