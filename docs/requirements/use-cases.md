# Use Cases

**Project:** Pirate Ship Co-op Sailing/Survival Game

**Team:** Whitney Akred, Leiton Peterson, Ivan Lopez, Liliana Matte, Gustavo Castillo, Shana Billiot

**Version:** 0.2

---

## Revision History

| Date | Version | Description | Author |
|---|---|---|---|
| 2026-09-30 | 0.2 | Rebuilt the use case list from the team's updated 50-item list; fully specified every use case; revised `UC-NAV-steer-ship` to use the shared station use cases | Whitney |
| 2026-09-13 | 0.1 | Initial use case list and first fully-specified use case (steering) | Whitney |

---

## 1. Introduction

### 1.1 Purpose

This document specifies the goals a player can accomplish within the pirate ship co-op sailing/survival game, in enough detail that a developer knows what to build and a tester knows what to check.

### 1.2 Scope

This document covers every item on the team's updated use case list (50 items), grouped into the feature areas below. Section 3 maps each use case back to its number on that list and notes which items were merged, renamed, moved, removed, or added.

| Area code | Feature area |
|---|---|
| `DECK` | Movement & Stations |
| `NAV` | Navigation & Sailing |
| `WAVE` | Waves & Stability |
| `SURV` | Hunger, Thirst & Illness |
| `FTG` | Fatigue |
| `SHIP` | Ship Damage & Repair |
| `EVT` | Events & Encounters |
| `PROG` | Progress & Session |
| `SYS` | System Behaviors |
| `MAP` | Map Interaction & Discovery |
| `ISLE` | Island Interaction |

Values marked [TBD] have not been decided yet and are listed in each use case's Open Issues.

---

## 2. Use Case Template

**UC ID and Name.** The identifier (`UC-<AREA>-<short-name>`) plus a concise name stating the value this use case provides to a user. Begins with an action verb.

**Created By** and **Date Created.** Created By is left blank for the responsible team member to fill in.

**Primary and Secondary Actors.** This project has three actors:

- **Crew Member:** any player. Picks a look from a set of preset characters.
- **Host:** a Crew Member who also manages the session (hosts it over LAN, starts, restarts, and pauses the voyage). The session cap is 4 players.
- **System:** the game itself, for behavior triggered by timers or events rather than by a player.

**Trigger.**

**Description.**

**Preconditions.** Labeled `PRE-1`, `PRE-2`, ... Must be system-testable.

**Postconditions.** Labeled `POST-1`, `POST-2`, ...

**Main Success Scenario.** Numbered, alternating actor/system, present tense.

**Extensions.** Alternative flows and exceptions, numbered relative to the branching step (e.g. `4a`, `4a1`).

**Priority.**

**Frequency of Use.**

**Business Rules.** `BR-*` identifiers only; text lives in business-rules.md.

**Associated Information.** Data fields table, quality attributes, display/sort strategy, failure behavior for durable changes.

**Related Use Cases.**

**Assumptions.**

**Open Issues.** Mirror into OPEN-ISSUES.md.

**Networking convention.** The Host's game instance is the authority for all shared state. "Synced to all clients" means the Host's state is sent to every crew member's game. Voyages are never saved; each one is unique.

---

## 3. Use Case List

All 50 items on the team's list are accounted for: 47 are covered by 45 use cases (a few were merged), 3 were removed, and 1 use case was added.

| Use case | Name | Primary actor | List # | Note |
|---|---|---|---|---|
| `UC-DECK-move-on-deck` | Move around the deck | Crew Member | 1 | |
| `UC-DECK-use-station` | Interact with a station | Crew Member | 2 | |
| `UC-DECK-claim-station` | Take over or release a station | Crew Member | 3 | |
| `UC-NAV-steer-ship` | Steer the ship | Crew Member | 4 | Revised from v0.1 |
| `UC-NAV-rotate-sail` | Rotate the sail | Crew Member | 5 | |
| `UC-NAV-raise-lower-sail` | Raise or lower the sail | Crew Member | 6 | |
| `UC-NAV-check-wind` | Check wind direction | Crew Member | 7 | |
| `UC-NAV-change-wind` | Change wind direction | System | 8 | |
| `UC-NAV-use-lookout` | Use the mast lookout | Crew Member | 9 | |
| `UC-WAVE-generate-waves` | Generate ocean waves | System | 10 | |
| `UC-WAVE-balance-ship` | Balance the ship | Crew Member | 11 | |
| `UC-WAVE-capsize-ship` | Capsize the ship | System | 12 | |
| `UC-SURV-consume-food` | Consume food | Crew Member | 13 | |
| `UC-SURV-consume-water` | Consume water | Crew Member | 14 | |
| `UC-SURV-deplete-hunger-thirst` | Deplete hunger and thirst over time | System | 15 | |
| `UC-SURV-pass-out` | Pass out from starvation, dehydration, or exhaustion | System | 16, 19 | Renamed from "Die of starvation or dehydration"; crew members pass out rather than die. Also covers the exhaustion penalty. |
| `UC-SURV-recover-from-illness` | Recover from illness | System | 28 | Renamed from "Treat a crew illness" (it is waited out); moved from Events |
| `UC-FTG-rest` | Rest to recover fatigue | Crew Member | 17 | |
| `UC-FTG-deplete-fatigue` | Deplete fatigue over time | System | 18 | |
| `UC-FTG-warn-exhaustion` | Warn of exhaustion | System | 19 | Renamed from "Apply exhaustion penalty"; the only effect is a red bar before passing out |
| `UC-SHIP-take-damage` | Spring a leak or take damage | System | 20 | |
| `UC-SHIP-repair-damage` | Repair ship damage | Crew Member | 21, 22 | "Jointly repair major damage" merged in as an extension; there is only one damage type |
| `UC-EVT-generate-event` | Generate a random ocean event | System | 23, 40 | "Event generation / picking per tile" merged in |
| `UC-EVT-trade-with-merchant` | Trade with a traveling merchant | Crew Member | 26 | |
| `UC-EVT-weather-storm` | Weather a storm | Crew Member | 27 | |
| `UC-PROG-track-progress` | Track voyage progress | System | 30 | |
| `UC-PROG-reach-paradise` | Reach Paradise Island | System | 31 | |
| `UC-PROG-quit-voyage` | Quit the voyage | Crew Member | 32 | Replaces "Lose the voyage"; the crew cannot lose |
| `UC-PROG-start-voyage` | Start or restart a voyage | Host | 33 | |
| `UC-PROG-host-join` | Host or join a multiplayer voyage | Host | 34 | |
| `UC-PROG-pause-game` | Pause the game | Host | 35 | |
| `UC-PROG-choose-character` | Choose a character | Crew Member | — | Added; not on the list |
| `UC-SYS-item-pool` | Draw items from the item pool | System | 36 | |
| `UC-SYS-player-inventory` | Manage personal inventory | Crew Member | 37 | |
| `UC-SYS-track-boat` | Track the boat across the map | System | 38 | |
| `UC-SYS-shared-inventory` | Use a storage chest | Crew Member | 39 | |
| `UC-SYS-item-drop` | Drop and pick up items | Crew Member | 41 | |
| `UC-MAP-open-map` | View the map | Crew Member | 42 | |
| `UC-MAP-view-island-info` | View a discovered island's info | Crew Member | 43 | Renamed from "Location of items on discovered islands"; the map shows islands, not items |
| `UC-MAP-discover-map` | Reveal the map as the ship explores | System | 44 | |
| `UC-MAP-place-pin` | Pin a marker to the map | Crew Member | 45 | |
| `UC-MAP-pin-distance` | Show distance to map pins | System | 46 | |
| `UC-ISLE-arrive-at-island` | Travel between the ship and an island | Crew Member | 47 | |
| `UC-ISLE-complete-challenge` | Complete an island challenge | Crew Member | 48 | |
| `UC-ISLE-collect-island-items` | Collect island items | Crew Member | 49 | |
| `UC-ISLE-salvage-shipwreck` | Salvage a shipwreck | Crew Member | 25 | Moved from Events; shipwrecks spawn on islands |

---

## 4. Use Cases

## Area: Movement & Stations (`DECK`)

### UC-DECK-move-on-deck: Move around the deck

**UC ID and Name:** `UC-DECK-move-on-deck`: Move around the deck

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member presses a movement input (WASD) while not controlling a station.

**Description:** A crew member walks around the flat ship deck to reach stations, chests, other crew members, and the plank. Movement is the base action every station interaction depends on.

**Preconditions:**

- PRE-1. The crew member is on the ship deck.
- PRE-2. The crew member is not currently controlling a station.
- PRE-3. The session is active (not paused).

**Postconditions:**

- POST-1. The crew member's position on the deck reflects their input and is synced to all crew members in the session.

**Main Success Scenario:**

1. The crew member presses a directional input (WASD).
2. The system moves the crew member's character in that direction at walking speed, relative to the ship deck.
3. The system syncs the crew member's new position to all other crew members' clients.
4. The crew member releases the directional input.
5. The system stops the crew member's character.
6. Use case ends.

**Extensions:**

- **2a. Movement would carry the crew member past the deck edge (railing):**
    - 2a1. The system blocks movement at the deck boundary.
    - 2a2. Flow rejoins the main scenario at step 4.
- **2b. The crew member walks off the end of the plank:**
    - 2b1. The system moves the crew member off the deck into an overboard state.
    - 2b2. The crew member moves through the water to the ladder beside the plank (or swims to a nearby island; see `UC-ISLE-arrive-at-island`).
    - 2b3. The system returns the crew member to the deck at the top of the ladder and clears the overboard state.
    - 2b4. Flow rejoins the main scenario at step 4.
- **3a. The crew member's connection lags or drops mid-movement:**
    - 3a1. The system corrects the crew member's position on the next session state sync.
    - 3a2. Flow rejoins the main scenario at step 4.

**Priority:** High

**Frequency of Use:** Continuous. Used throughout every play session.

**Business Rules:** `BR-deck-bounds`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| crew position | Vector2 (relative to ship) | Must stay within deck bounds unless overboard | N/A, local session state | Crew Member |
| movement speed | Float | Base value TBD | N/A | Crew Member |
| overboard state | Boolean | True while in the water after leaving via the plank | N/A | Plank |

Failure behavior: This use case makes no durable change. On desync, position is corrected at the next state sync.

**Related Use Cases:** `UC-DECK-use-station`, `UC-ISLE-arrive-at-island`

**Assumptions:** Crew member positions are stored relative to the ship, so crew members move with the ship as it sails. The plank is the only way off the deck and the ladder beside it is the only way back on. Crew members pass through each other (no player-to-player collision).

**Open Issues:** none

---

### UC-DECK-use-station: Interact with a station

**UC ID and Name:** `UC-DECK-use-station`: Interact with a station

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member presses the interact input while within range of a station.

**Description:** A crew member enters a station, and their controls switch to that station's function until they leave it. Fixed stations are Steering, Sail (at the base of the center mast), Lookout, Cooking, Fishing, Hammock, and Map. Repair Spots are temporary stations that appear at random locations on the deck when the ship takes damage. Cooking is played as a minigame, and Fishing likely is too; Steering, Sail, and Lookout use continuous controls. This is the shared entry and exit flow for all station-specific use cases.

**Preconditions:**

- PRE-1. The crew member is within interaction range of a station.
- PRE-2. The crew member is not currently controlling another station.
- PRE-3. The session is active (not paused).

**Postconditions:**

- POST-1. The crew member has used the station's function and has returned to normal deck movement.
- POST-2. The crew member's claim on the station has been released.

**Main Success Scenario:**

1. The crew member moves within interaction range of a station.
2. The system displays an interaction prompt for that station.
3. The crew member presses the interact input.
4. The system claims the station for the crew member (includes `UC-DECK-claim-station`).
5. The system switches the crew member's controls from deck movement to the station's controls.
6. The crew member uses the station (see the station-specific use case, e.g. `UC-NAV-steer-ship`).
7. The crew member presses the interact input again to leave the station.
8. The system releases the station (includes `UC-DECK-claim-station`) and returns deck movement controls to the crew member.
9. Use case ends.

**Extensions:**

- **2a. More than one station is within interaction range:**
    - 2a1. The system displays the prompt for the nearest station only.
    - 2a2. Flow rejoins the main scenario at step 3.
- **4a. The station is already claimed and has no free slot:**
    - 4a1. The system denies the request and notifies the crew member that the station is in use.
    - 4a2. Use case ends.
- **5a. The station has nothing to do (e.g. Cooking with no ingredients, Fishing with [TBD] condition):**
    - 5a1. The system notifies the crew member why the station can't be used right now.
    - 5a2. The system releases the station.
    - 5a3. Use case ends.
- **6a. The crew member is forced off the station (auto-release condition in `UC-DECK-claim-station`):**
    - 6a1. Flow rejoins the main scenario at step 8.

**Priority:** High

**Frequency of Use:** Continuous. Stations are the core way the crew interacts with the ship.

**Business Rules:** `BR-single-station-occupant`, `BR-station-slots`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| station type | Enum | Steering, Sail, Lookout, Cooking, Fishing, Hammock, Map, Repair Spot | N/A | Station |
| station placement | Fixed or spawned | Repair Spots spawn at random deck locations via `UC-SHIP-take-damage` and are removed once repaired; all others are fixed | N/A | Station |
| interaction range | Float (distance) | TBD, needs playtesting | N/A | Station |
| control mode | Enum | Deck movement or station controls | N/A, local session state | — |

Failure behavior: This use case makes no durable change. If the session drops mid-use, the station reverts to unclaimed on the next state sync.

**Related Use Cases:** `UC-DECK-claim-station`, `UC-NAV-steer-ship`, `UC-NAV-rotate-sail`, `UC-NAV-raise-lower-sail`, `UC-NAV-use-lookout`, `UC-FTG-rest`, `UC-MAP-open-map`, `UC-SHIP-repair-damage`

**Assumptions:** While at a station, WASD belongs to the station, so the crew member leaves by pressing interact again, not by walking away. Repair Spots are the one exception and use press-and-hold (see `UC-SHIP-repair-damage`).

**Open Issues:**

- Is Fishing a minigame?
- Cooking and Fishing have no use cases yet (they are not on the team's list).
- The Map station is assumed (see `UC-MAP-open-map`).

---

### UC-DECK-claim-station: Take over or release a station

**UC ID and Name:** `UC-DECK-claim-station`: Take over or release a station

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** Host (resolves simultaneous claims)

**Trigger:** A crew member requests control of a station or chest (through `UC-DECK-use-station` or `UC-SYS-shared-inventory`).

**Description:** The system locks a station to one crew member while they use it and unlocks it when they leave, so two crew members never give conflicting commands to the same station. Repair Spots and the Hammock are the exceptions and can hold more than one crew member.

**Preconditions:**

- PRE-1. The crew member is within interaction range of the station.

**Postconditions:**

- POST-1. At any moment, a station is either unclaimed or claimed by exactly one crew member, and all clients agree on which. The exceptions are Repair Spots, which may be claimed by several crew members at once, and the Hammock, which holds up to 2.

**Main Success Scenario:**

1. The crew member requests control of the station.
2. The system verifies that the station is unclaimed.
3. The system marks the station as claimed by the crew member and syncs this to all clients.
4. The crew member requests to release the station.
5. The system marks the station as unclaimed and syncs this to all clients.
6. Use case ends.

**Extensions:**

- **2a. The station is already claimed and has no free slot:**
    - 2a1. The system denies the request.
    - 2a2. The system notifies the requesting crew member that the station is occupied.
    - 2a3. Use case ends for the requesting crew member; the current occupant's control is unaffected.
- **2b. Two crew members request the same unclaimed station at the same moment:**
    - 2b1. The system grants the station to whichever request the Host's game instance received first.
    - 2b2. The system denies the other request (see 2a2).
    - 2b3. Flow rejoins the main scenario at step 3 for the winning crew member.
- **2c. The station is a Repair Spot, or the Hammock with a free slot, already claimed by another crew member:**
    - 2c1. The system adds the requesting crew member as an additional occupant (see `UC-SHIP-repair-damage` extension 4a and `UC-FTG-rest`).
    - 2c2. Flow rejoins the main scenario at step 3.
- **4a. The claiming crew member moves beyond the auto-release distance, disconnects, goes overboard, or passes out without releasing:**
    - 4a1. The system detects the condition.
    - 4a2. The system auto-releases the station on the crew member's behalf.
    - 4a3. Flow rejoins the main scenario at step 5.

**Priority:** High

**Frequency of Use:** Continuous. Runs every time any station is used.

**Business Rules:** `BR-single-station-occupant` (replaces `BR-single-helmsman`; must state the Repair Spot and Hammock exceptions), `BR-station-slots`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| station occupants | List of crew member IDs | 0–1 for most stations; 0–2 for the Hammock; 0–4 for a Repair Spot | Only the Host's instance may assign it | Station |
| auto-release distance/timeout | Distance or duration | TBD | N/A | — |

Failure behavior: This use case makes no durable change. If the Host disconnects, the session ends (see `UC-PROG-quit-voyage`).

**Related Use Cases:** `UC-DECK-use-station`, `UC-SYS-shared-inventory`, `UC-SHIP-repair-damage`, `UC-FTG-rest`, `UC-SURV-pass-out`

**Assumptions:** The Host's instance is the authority on who holds a station. "Take over" means claiming a free station only; a crew member cannot kick someone else off.

**Open Issues:**

- Is kicking someone off a station ever allowed?
- What is the auto-release distance/timeout?

---

## Area: Navigation & Sailing (`NAV`)

### UC-NAV-steer-ship: Steer the ship

**UC ID and Name:** `UC-NAV-steer-ship`: Steer the ship

**Created By:** Whitney

**Date Created:** 2026-09-13 (revised 2026-09-30)

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member presses a directional input while controlling the Steering station.

**Description:** The active helmsman sets the ship's heading, which the crew must do continuously to survive and make progress toward Paradise Island.

**Preconditions:**

- PRE-1. The crew member has claimed the Steering station (`UC-DECK-claim-station`).

**Postconditions:**

- POST-1. The ship's heading and speed reflect the helmsman's input, adjusted for wind, sail state, and nearby hazards.

**Main Success Scenario:**

1. The crew member presses a directional input (WASD) to indicate the desired heading.
2. The system angles the ship gradually toward the desired heading rather than snapping instantly, simulating a boat's turning inertia.
3. The system adjusts ship speed based on wind direction and strength relative to the current heading and the sail's rotation and raised/lowered state.
4. The crew member keeps adjusting the heading until they leave the station (`UC-DECK-use-station`, step 7).
5. Use case ends.

**Extensions:**

- **3a. No wind is present (becalmed):**
    - 3a1. The system caps ship speed at a significantly reduced maximum regardless of input.
    - 3a2. Flow rejoins the main scenario at step 4.
- **3b. The ship is within a proximity threshold of an island or other hazard:**
    - 3b1. The system reduces ship speed to avoid collision, independent of wind conditions.
    - 3b2. Flow rejoins the main scenario at step 4.
- **3c. The crew member holds a consistent heading for longer than [TBD duration]:**
    - 3c1. The system applies a speed bonus modifier for as long as the heading is held.
    - 3c2. Flow rejoins the main scenario at step 4.

**Exceptions:**

- **3d. The ship collides with an island, rock, or another ship despite the speed reduction:**
    - 3d1. The system applies collision damage to the ship (`UC-SHIP-take-damage`, extension 1b).
    - 3d2. Flow rejoins the main scenario at step 4.

**Priority:** High

**Frequency of Use:** Continuous. Used throughout nearly every play session; this is a core mechanic.

**Business Rules:** `BR-single-station-occupant`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| heading | Float (degrees) | 0–359 | N/A, local session state | Ship |
| speed multiplier | Float | Bounded by wind/sail/hazard/bonus rules above | N/A | Ship |
| wind vector | Direction + magnitude | System-generated (`UC-NAV-change-wind`) | N/A | Wind |
| hazard proximity threshold | Float (distance) | TBD, needs tuning/playtesting | N/A | — |
| sustained-heading bonus duration | Duration | TBD, needs tuning/playtesting | N/A | — |

Failure behavior: This use case makes no durable change. If the session ends or a network issue occurs, no data is at risk of a partial write.

**Related Use Cases:** `UC-DECK-use-station`, `UC-DECK-claim-station`, `UC-NAV-rotate-sail`, `UC-NAV-raise-lower-sail`, `UC-WAVE-balance-ship`, `UC-SHIP-take-damage`

**Assumptions:** Steering is real-time, not turn-based. Sail state affects speed but not turning.

**Open Issues:**

- Does a collision cause damage, and how much?
- What is the exact duration threshold for the sustained-heading speed bonus?

---

### UC-NAV-rotate-sail: Rotate the sail

**UC ID and Name:** `UC-NAV-rotate-sail`: Rotate the sail

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member presses a rotation input while controlling the Sail station.

**Description:** A crew member angles the sail left or right to catch the wind, which changes how fast the ship moves. The sail rotates within a limited arc (about 270°), so the crew has to coordinate sail angle and heading to sail well.

**Preconditions:**

- PRE-1. The crew member has claimed the Sail station (`UC-DECK-claim-station`).

**Postconditions:**

- POST-1. The sail's angle reflects the crew member's input, within the rotation limits, and is synced to all clients.
- POST-2. The ship's speed reflects the new alignment between the sail and the wind.

**Main Success Scenario:**

1. The crew member presses a left or right input (A/D).
2. The system rotates the sail gradually in that direction.
3. The system recalculates the wind push on the ship based on the angle between the sail and the current wind direction.
4. The system syncs the sail angle to all clients.
5. The crew member keeps adjusting until they leave the station (`UC-DECK-use-station`, step 7).
6. Use case ends.

**Extensions:**

- **2a. The sail reaches its rotation limit:**
    - 2a1. The system stops the sail at the limit and ignores further input in that direction.
    - 2a2. Flow rejoins the main scenario at step 3.
- **3a. The sail is lowered (not catching wind):**
    - 3a1. The system updates the sail angle but applies no wind push until the sail is raised (see `UC-NAV-raise-lower-sail`).
    - 3a2. Flow rejoins the main scenario at step 4.
- **3b. No wind is present (becalmed):**
    - 3b1. The system applies no wind push regardless of sail angle.
    - 3b2. Flow rejoins the main scenario at step 4.

**Priority:** High

**Frequency of Use:** Frequent. Used whenever the wind shifts or the ship changes heading.

**Business Rules:** `BR-single-station-occupant`, `BR-sail-rotation-limit`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| sail angle | Float (degrees, relative to ship heading) | About −135 to +135 (≈270° total); exact limit TBD | N/A, local session state | Sail |
| rotation speed | Float (degrees/sec) | TBD, needs playtesting | N/A | Sail |
| wind push | Float | Derived from wind magnitude and sail/wind alignment; formula TBD | N/A | Wind |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-DECK-use-station`, `UC-NAV-raise-lower-sail`, `UC-NAV-steer-ship`, `UC-NAV-change-wind`

**Assumptions:** The sail angle is measured relative to the ship, so turning the ship also changes how the sail meets the wind. The most push comes from angling the sail to fully catch the wind.

**Open Issues:**

- What exactly is the rotation limit?
- What is the formula for how sail/wind alignment turns into speed?

---

### UC-NAV-raise-lower-sail: Raise or lower the sail

**UC ID and Name:** `UC-NAV-raise-lower-sail`: Raise or lower the sail

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member presses the raise/lower input while controlling the Sail station.

**Description:** A crew member switches the sail between its two states: raised, which catches the wind and drives the ship, and lowered, which stops catching wind so the ship slows to a drift. This is how the crew stops the ship, rides out storms, and gets moving again.

**Preconditions:**

- PRE-1. The crew member has claimed the Sail station (`UC-DECK-claim-station`).

**Postconditions:**

- POST-1. The sail is in the state the crew member selected, and it is synced to all clients.
- POST-2. The ship's speed reflects the new sail state.

**Main Success Scenario:**

1. The crew member presses the raise/lower input.
2. The system switches the sail to the opposite state (raised to lowered, or lowered to raised) and plays the transition animation.
3. The system updates the wind push on the ship: full push when the sail is raised, and none when lowered, so the ship slows to a drift.
4. The system syncs the sail state to all clients.
5. Use case ends.

**Extensions:**

- **1a. The sail is still mid-transition from a previous input:**
    - 1a1. The system ignores the input until the transition completes.
    - 1a2. Use case ends.
- **3a. The sail is raised while no wind is present (becalmed):**
    - 3a1. The system sets the sail to raised but applies no wind push until wind returns.
    - 3a2. Flow rejoins the main scenario at step 4.

**Priority:** High

**Frequency of Use:** Occasional. Used when stopping near islands, during storms, and when setting off again.

**Business Rules:** `BR-single-station-occupant`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| sail state | Enum | Raised or Lowered | N/A, local session state | Sail |
| transition duration | Duration | TBD | N/A | Sail |
| drift speed | Float | Minimum ship speed with the sail lowered; TBD | N/A | Ship |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-NAV-rotate-sail`, `UC-NAV-steer-ship`, `UC-WAVE-balance-ship`, `UC-EVT-weather-storm`, `UC-ISLE-arrive-at-island`

**Assumptions:** The sail has only two states, with no partial raise. A lowered sail doesn't stop the ship instantly; it slows to a drift.

**Open Issues:** none

---

### UC-NAV-check-wind: Check wind direction

**UC ID and Name:** `UC-NAV-check-wind`: Check wind direction

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member looks at the wind indicator to decide how to steer or angle the sail.

**Description:** A crew member reads the current wind direction from an arrow in the top-right corner of the screen, so the crew can decide where to point the ship and sail.

**Preconditions:**

- PRE-1. The crew member is in an active session.

**Postconditions:**

- POST-1. The wind indicator on the crew member's screen matches the current wind direction and strength.

**Main Success Scenario:**

1. The system displays the wind arrow in the top-right corner of every crew member's screen, pointing in the current wind direction.
2. The crew member views the arrow.
3. The system updates the arrow whenever the wind changes (`UC-NAV-change-wind`).
4. Use case ends.

**Extensions:**

- **1a. No wind is present (becalmed):**
    - 1a1. The system shows a becalmed state on the indicator instead of an arrow ([TBD] visual).
    - 1a2. Flow rejoins the main scenario at step 2.
- **3a. The crew member's client misses a wind update due to lag:**
    - 3a1. The system corrects the arrow on the next session state sync.
    - 3a2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Continuous. The indicator is always visible.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| wind direction (displayed) | Float (degrees) | 0–359, matches the session wind vector | N/A | Wind |
| wind strength (displayed) | [TBD] visual encoding | Arrow size, color, or none | N/A | Wind |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-NAV-change-wind`, `UC-NAV-rotate-sail`, `UC-NAV-steer-ship`

**Assumptions:** Every crew member sees the same arrow, whether or not they're at a station.

**Open Issues:**

- Does the arrow show wind strength (size or color), or only direction?
- What does the indicator show when the ship is becalmed?

---

### UC-NAV-change-wind: Change wind direction

**UC ID and Name:** `UC-NAV-change-wind`: Change wind direction

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** The wind-change cooldown expires.

**Description:** The system periodically changes the wind to a random new direction and strength, forcing the crew to re-steer and re-angle the sail to keep making progress.

**Preconditions:**

- PRE-1. A session is active and not paused.

**Postconditions:**

- POST-1. The session has a new wind direction and strength, synced to all clients.
- POST-2. A new wind-change cooldown is running.

**Main Success Scenario:**

1. The wind-change cooldown expires.
2. The system picks a random new wind direction and strength.
3. The system shifts the wind from the old values to the new ones.
4. The system syncs the new wind to all clients and updates the wind indicator (`UC-NAV-check-wind`).
5. The system recalculates the wind push on the ship from the current heading and sail state.
6. The system starts the wind-change cooldown.
7. Use case ends.

**Extensions:**

- **2a. The random roll produces no wind (becalmed):**
    - 2a1. The system sets the wind strength to zero.
    - 2a2. Flow rejoins the main scenario at step 4.
- **2b. A storm is in progress (`UC-EVT-weather-storm`):**
    - 2b1. The system uses the storm's wind rules instead of a normal random pick ([TBD]).
    - 2b2. Flow rejoins the main scenario at step 3.

**Priority:** High

**Frequency of Use:** Periodic, limited by a cooldown (duration TBD).

**Business Rules:** `BR-wind-change-cooldown`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| wind vector | Direction + magnitude | Direction 0–359; magnitude 0 to max TBD | Generated only by the Host's instance | Wind |
| wind-change cooldown | Duration | TBD | N/A | Wind |
| becalmed chance | Float (probability) | TBD | N/A | Wind |

Failure behavior: This use case makes no durable change. If a client desyncs, it gets the Host's wind values on the next sync.

**Related Use Cases:** `UC-NAV-check-wind`, `UC-NAV-steer-ship`, `UC-NAV-rotate-sail`, `UC-EVT-weather-storm`

**Assumptions:** The Host's instance generates the wind so every player sees the same wind.

**Open Issues:**

- Does the wind shift gradually or snap to the new direction?
- What is the cooldown duration?
- Is becalmed a random wind outcome, or only caused by events?
- Does the wind behave differently during a storm?

---

### UC-NAV-use-lookout: Use the mast lookout

**UC ID and Name:** `UC-NAV-use-lookout`: Use the mast lookout

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member claims the Lookout station.

**Description:** A crew member climbs to the mast lookout to zoom out their view, which lets them spot islands, hazards, and events sooner and call directions to the helmsman.

**Preconditions:**

- PRE-1. The crew member has claimed the Lookout station (`UC-DECK-claim-station`).

**Postconditions:**

- POST-1. The crew member's camera is back to normal zoom after they leave the lookout.

**Main Success Scenario:**

1. The system zooms out the crew member's camera to the lookout field of view.
2. The crew member views the wider area around the ship.
3. The crew member leaves the station (`UC-DECK-use-station`, step 7).
4. The system returns the crew member's camera to the normal field of view.
5. Use case ends.

**Extensions:**

- **2a. The crew member is forced off the lookout (auto-release in `UC-DECK-claim-station`):**
    - 2a1. The system immediately returns the camera to the normal field of view.
    - 2a2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Frequent. Used when searching for islands or when a hazard is expected.

**Business Rules:** `BR-single-station-occupant`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| lookout zoom level | Float (camera zoom) | TBD, needs playtesting | Local to the crew member only | Lookout |

Failure behavior: This use case makes no durable change. The camera is local to one client.

**Related Use Cases:** `UC-DECK-use-station`, `UC-NAV-steer-ship`

**Assumptions:** Only the lookout crew member's view changes; everyone else's camera is unaffected. The Sail and Lookout stations are separate, so two crew members can use them at once even though both are on the mast. The lookout only widens the camera; it does not reveal map areas.

**Open Issues:**

- Does weather such as a storm reduce the lookout's view?

---

## Area: Waves & Stability (`WAVE`)

### UC-WAVE-generate-waves: Generate ocean waves

**UC ID and Name:** `UC-WAVE-generate-waves`: Generate ocean waves

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** Rough weather begins (e.g. `UC-EVT-weather-storm`).

**Description:** During rough weather, the system generates waves that push the ship off its heading. This makes steering harder and creates the risk of capsizing.

**Preconditions:**

- PRE-1. A session is active and not paused.
- PRE-2. Rough weather is in effect.

**Postconditions:**

- POST-1. While rough weather lasts, waves with a direction and intensity are active and synced to all clients.
- POST-2. When rough weather ends, waves have stopped and no longer affect the ship.

**Main Success Scenario:**

1. The system detects that rough weather has started.
2. The system generates waves with a direction and intensity.
3. The system displays the waves to all crew members and syncs the wave state to all clients.
4. The system pushes the ship's heading off course based on the wave intensity and the angle between the ship and the waves.
5. The system detects that rough weather has ended.
6. The system fades out the waves and stops applying wave effects to the ship.
7. Use case ends.

**Extensions:**

- **2a. The weather intensifies partway through:**
    - 2a1. The system increases the wave intensity.
    - 2a2. Flow rejoins the main scenario at step 3.
- **4a. No crew member is at the Steering station:**
    - 4a1. The system lets the waves turn the ship freely, drifting it toward a side-on angle.
    - 4a2. Flow rejoins the main scenario at step 5.

**Priority:** High

**Frequency of Use:** Occasional. Only during rough weather.

**Business Rules:** `BR-waves-rough-weather-only`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| wave direction | Float (degrees) | 0–359 | Generated only by the Host's instance | Waves |
| wave intensity | Float | 0 to max TBD; scales with weather | Generated only by the Host's instance | Waves |
| heading push | Float (degrees/sec) | Derived from intensity and angle; formula TBD | N/A | Ship |

Failure behavior: This use case makes no durable change. Clients that desync receive the Host's wave state on the next sync.

**Related Use Cases:** `UC-EVT-weather-storm`, `UC-WAVE-balance-ship`, `UC-WAVE-capsize-ship`, `UC-NAV-steer-ship`

**Assumptions:** Waves only occur during rough weather; calm seas have none. Waves travel in roughly the same direction as the wind.

**Open Issues:**

- Is a storm the only rough weather, or are there milder rough-weather states?
- Should waves follow the wind direction, or move independently?

---

### UC-WAVE-balance-ship: Balance the ship

**UC ID and Name:** `UC-WAVE-balance-ship`: Balance the ship

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member (active helmsman)

**Secondary Actors:** Crew Member (at the Sail station)

**Trigger:** Waves are active while a crew member controls the Steering station.

**Description:** The helmsman angles the ship diagonally into the oncoming waves to keep it stable and avoid capsizing. Another crew member can lower the sail to reduce the risk further, at the cost of speed. There is no stability meter; the crew reads the danger from how much the ship shakes.

**Preconditions:**

- PRE-1. The crew member has claimed the Steering station (`UC-DECK-claim-station`).
- PRE-2. Waves are active (`UC-WAVE-generate-waves`).

**Postconditions:**

- POST-1. The ship's stability, and how much it visibly shakes, reflect how well its heading lines up with the waves and the sail's state.

**Main Success Scenario:**

1. The crew member observes the direction of the incoming waves.
2. The crew member steers to angle the ship diagonally into the waves (see `UC-NAV-steer-ship`).
3. The system compares the ship's heading to the wave direction.
4. The system recovers the ship's stability while the heading stays within the safe diagonal range, and reduces the ship's shaking to match.
5. The crew member keeps correcting the heading against the waves' push until the waves subside.
6. Use case ends.

**Extensions:**

- **3a. The ship is not diagonal to the waves (too straight-on or side-on):**
    - 3a1. The system reduces the ship's stability, faster the further off the safe range it is, and increases the shaking.
    - 3a2. Flow rejoins the main scenario at step 5.
- **3b. The sail is raised while the ship is outside the safe range:**
    - 3b1. The system reduces stability faster than it would with the sail lowered.
    - 3b2. Flow rejoins the main scenario at step 5.
- **3c. Stability falls below the danger threshold:**
    - 3c1. The system increases the ship's visible shaking to signal that a capsize is near.
    - 3c2. Flow rejoins the main scenario at step 5.
- **3d. Stability reaches zero:**
    - 3d1. The system triggers `UC-WAVE-capsize-ship`.
    - 3d2. Use case ends.
- **5a. The helmsman leaves the Steering station while waves are active:**
    - 5a1. The system stops heading corrections, and the waves drift the ship toward side-on (see `UC-WAVE-generate-waves`, 4a).
    - 5a2. Use case ends.

**Priority:** High

**Frequency of Use:** Occasional. Only during rough weather, but critical when it happens.

**Business Rules:** `BR-single-station-occupant`, `BR-capsize-conditions`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| ship stability | Float | 0 to max TBD; capsize at 0 | Hidden from players; shown only as shaking intensity. Calculated only by the Host's instance | Ship |
| safe diagonal range | Float (degrees) | Around 45° to the waves, ± tolerance TBD | N/A | Waves |
| stability loss rate | Float | Higher when further off diagonal and with the sail raised; TBD | N/A | Ship |
| danger threshold | Float | TBD | N/A | Ship |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-NAV-steer-ship`, `UC-NAV-raise-lower-sail`, `UC-WAVE-generate-waves`, `UC-WAVE-capsize-ship`, `UC-EVT-weather-storm`

**Assumptions:** Stability is the hidden measure that decides capsizing, and it recovers on its own in calm seas. There is no stability meter on screen; the ship's shaking is the only feedback.

**Open Issues:**

- What is the exact safe diagonal range?

---

### UC-WAVE-capsize-ship: Capsize the ship

**UC ID and Name:** `UC-WAVE-capsize-ship`: Capsize the ship

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** The ship's stability reaches zero, or the ship's integrity reaches 0%.

**Description:** When rough waves overpower the crew, or leaks are left unrepaired until the hull fails, the ship capsizes. The crew is reset to the last island they visited and loses all their food, materials, and inventory. The voyage does not end, because the crew cannot lose.

**Preconditions:**

- PRE-1. A voyage is in progress.

**Postconditions:**

- POST-1. The ship and all crew members are at the last island visited, and all clients agree.
- POST-2. The ship's stability and integrity are restored to full, and all Repair Spots are removed.
- POST-3. Every crew member's inventory and the deck chest have been emptied.

**Main Success Scenario:**

1. The system detects that stability has reached zero or integrity has reached 0%.
2. The system plays the capsize sequence for all crew members.
3. The system releases every claimed station (`UC-DECK-claim-station`).
4. The system moves the ship and all crew members to the last island visited.
5. The system removes all food, materials, and items from every crew member's inventory and from the deck chest (`UC-SYS-player-inventory`, `UC-SYS-shared-inventory`).
6. The system restores stability and integrity to full, removes all Repair Spots, sets the sail to lowered, and syncs the new state to all clients.
7. Use case ends.

**Extensions:**

- **4a. The crew has not visited any island yet this voyage:**
    - 4a1. The system resets the ship and crew to the voyage's starting point.
    - 4a2. Flow rejoins the main scenario at step 5.
- **6a. A crew member disconnects during the reset:**
    - 6a1. The system completes the reset using the Host's state.
    - 6a2. The crew member receives the reset state when they reconnect.
    - 6a3. Use case ends.

**Priority:** High

**Frequency of Use:** Rare. Only when the crew loses control in rough weather or neglects repairs.

**Business Rules:** `BR-capsize-conditions`, `BR-capsize-reset`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| last visited island | Island ID | Must be an island the crew has visited this voyage | Tracked only by the Host's instance | Island |
| stock lost | Items (food, materials, inventory) | All; applies to every crew member's inventory and the deck chest | Applied only by the Host's instance | Inventory |
| ship integrity | Float (%) | 0–100 | Changed only by the Host's instance | Ship |

Failure behavior: This use case makes durable changes to the ship's position, integrity, and the crew's stock. The Host applies them together as one reset. If the Host disconnects mid-reset, the session ends (voyages are not saved), so no partial reset can persist.

**Related Use Cases:** `UC-WAVE-balance-ship`, `UC-WAVE-generate-waves`, `UC-SHIP-take-damage`, `UC-EVT-weather-storm`, `UC-PROG-track-progress`, `UC-ISLE-arrive-at-island`, `UC-SYS-player-inventory`, `UC-SYS-shared-inventory`

**Assumptions:** Capsizing is a setback, not a game over. The crew restarts with the sail lowered so they aren't immediately at risk again.

**Open Issues:**

- Can a crew capsize while the sail is lowered?

---

## Area: Hunger, Thirst & Illness (`SURV`)

### UC-SURV-consume-food: Consume food

**UC ID and Name:** `UC-SURV-consume-food`: Consume food

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member selects a food item in their inventory and uses it.

**Description:** A crew member eats food gathered from islands to refill their hunger, which keeps them from passing out. Fruit is fine raw. Other food, like fish, can be eaten raw but makes the crew member ill. Cooking any food gives better stats.

**Preconditions:**

- PRE-1. The crew member is not passed out.
- PRE-2. The crew member has at least one food item in their inventory.
- PRE-3. The session is active (not paused).

**Postconditions:**

- POST-1. The food item is removed from the crew member's inventory.
- POST-2. The crew member's hunger has increased by the item's restore amount, up to the maximum.

**Main Success Scenario:**

1. The crew member opens their inventory and selects a food item.
2. The crew member uses the item.
3. The system removes one of that food item from the crew member's inventory.
4. The system increases the crew member's hunger by the item's restore amount, capped at the maximum.
5. The system updates the crew member's hunger bar.
6. Use case ends.

**Extensions:**

- **2a. The food item is raw and is not fruit (e.g. raw fish):**
    - 2a1. The system removes the item and restores its raw hunger amount.
    - 2a2. The system makes the crew member ill (`UC-SURV-recover-from-illness`).
    - 2a3. Flow rejoins the main scenario at step 5.
- **4a. The crew member's hunger is already full:**
    - 4a1. [TBD] The system either blocks the action or allows it with no benefit.
    - 4a2. Use case ends.

**Priority:** High

**Frequency of Use:** Frequent. Several times per session per crew member.

**Business Rules:** `BR-stat-max`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| hunger | Float | 0 to max (TBD) | Per crew member; changed only by the Host's instance | Hunger |
| food item | Item ID | Must be a food-type item in the crew member's inventory | N/A | Item |
| restore amount | Float | Set per food type; cooked items restore more than their raw version; values TBD | N/A | Item |

Failure behavior: This use case makes a durable change to the crew member's inventory and hunger. The Host removes the item and adds the hunger together; if either fails, neither is applied.

**Related Use Cases:** `UC-SURV-deplete-hunger-thirst`, `UC-SURV-recover-from-illness`, `UC-SYS-player-inventory`, `UC-ISLE-collect-island-items`

**Assumptions:** Food comes from islands. Crew members eat from their own inventory, not directly from the deck chest. Fruit can be eaten raw or cooked; other food eaten raw causes illness.

**Open Issues:**

- Can a crew member eat when their hunger is full?
- Cooking has no use case yet (see Section 3).

---

### UC-SURV-consume-water: Consume water

**UC ID and Name:** `UC-SURV-consume-water`: Consume water

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member selects their water bottle in their inventory and drinks.

**Description:** A crew member drinks from a bottle they fill at the ship's water barrel, which slowly collects clean water over time. Carrying a bottle lets crew members stay hydrated away from the barrel, for example on islands.

**Preconditions:**

- PRE-1. The crew member is not passed out.
- PRE-2. The crew member has a water bottle in their inventory.
- PRE-3. The session is active (not paused).

**Postconditions:**

- POST-1. The bottle's water level has decreased by one serving.
- POST-2. The crew member's thirst has increased by one serving's restore amount, up to the maximum.

**Main Success Scenario:**

1. The crew member selects their water bottle and drinks.
2. The system checks that the bottle holds at least one serving.
3. The system removes one serving from the bottle.
4. The system increases the crew member's thirst by the serving's restore amount, capped at the maximum.
5. The system updates the crew member's thirst bar and the bottle's water level.
6. Use case ends.

**Extensions:**

- **2a. The bottle is empty:**
    - 2a1. The system tells the crew member the bottle is empty.
    - 2a2. The crew member interacts with the water barrel.
    - 2a3. The system moves servings from the barrel into the bottle, up to the bottle's capacity or whatever the barrel holds.
    - 2a4. Flow rejoins the main scenario at step 1.
- **2a3a. The barrel is also empty:**
    - 2a3a1. The system tells the crew member the barrel is empty.
    - 2a3a2. Use case ends.
- **4a. The crew member's thirst is already full:**
    - 4a1. [TBD] The system either blocks the action or allows it with no benefit.
    - 4a2. Use case ends.

**Priority:** High

**Frequency of Use:** Frequent. Several times per session per crew member.

**Business Rules:** `BR-stat-max`, `BR-barrel-fill-rate`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| thirst | Float | 0 to max (TBD) | Per crew member; changed only by the Host's instance | Thirst |
| bottle water level | Integer (servings) | 0 to bottle capacity (TBD) | Per crew member | Water Bottle |
| barrel water level | Integer (servings) | 0 to barrel capacity (TBD) | Shared by the crew; changed only by the Host's instance | Water Barrel |
| barrel fill rate | Servings per minute | Steady; TBD | N/A | Water Barrel |
| restore amount | Float | Per serving; TBD | N/A | Water Bottle |

Failure behavior: This use case makes durable changes to the bottle's water level, the barrel's water level, and the crew member's thirst. Each transfer (barrel to bottle, bottle to thirst) is applied fully or not at all by the Host.

**Related Use Cases:** `UC-SURV-deplete-hunger-thirst`, `UC-SYS-player-inventory`, `UC-WAVE-capsize-ship`

**Assumptions:** The barrel is the only water source, and its water is always drinkable. Each crew member starts with one bottle. The barrel is an instant-use object, not a claimed station.

**Open Issues:**

- A capsize clears all inventory. How does a crew member get a new bottle afterward?
- Does a capsize empty the barrel?
- Can a crew member drink when their thirst is full?

---

### UC-SURV-deplete-hunger-thirst: Deplete hunger and thirst over time

**UC ID and Name:** `UC-SURV-deplete-hunger-thirst`: Deplete hunger and thirst over time

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** A crew member joins an active voyage and is not passed out.

**Description:** The system steadily drains each crew member's own hunger and thirst over time, so the crew has to keep finding food and water to survive.

**Preconditions:**

- PRE-1. The session is active (not paused).
- PRE-2. The crew member is not passed out.

**Postconditions:**

- POST-1. Each crew member's hunger and thirst reflect the time elapsed and are shown on that crew member's screen.

**Main Success Scenario:**

1. The system decreases the crew member's hunger and thirst at a steady rate.
2. The system updates the crew member's hunger and thirst bars on their screen.
3. The system repeats steps 1–2 for as long as the session is active.
4. Use case ends when the session ends.

**Extensions:**

- **1a. The crew member's hunger or thirst reaches zero:**
    - 1a1. The system triggers `UC-SURV-pass-out`.
    - 1a2. The system stops depleting that crew member's stats until they recover.
    - 1a3. Flow rejoins the main scenario at step 1 once the crew member recovers.
- **1b. The session is paused (`UC-PROG-pause-game`):**
    - 1b1. The system stops depleting until the session resumes.
    - 1b2. Flow rejoins the main scenario at step 1.
- **2a. The crew member's client misses an update due to lag:**
    - 2a1. The system corrects the bars on the next session state sync.
    - 2a2. Flow rejoins the main scenario at step 3.

**Priority:** High

**Frequency of Use:** Continuous. Runs for every crew member for the whole session.

**Business Rules:** `BR-stat-depletion-rate`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| hunger depletion rate | Float (per second) | Constant; TBD | N/A | Hunger |
| thirst depletion rate | Float (per second) | Constant; TBD | N/A | Thirst |

Failure behavior: Hunger and thirst are session state owned by the Host. A client that desyncs receives the Host's values on the next sync.

**Related Use Cases:** `UC-SURV-consume-food`, `UC-SURV-consume-water`, `UC-SURV-pass-out`, `UC-PROG-pause-game`

**Assumptions:** Each crew member has their own hunger and thirst bars. The depletion rate is steady and doesn't change with activity. Hunger and thirst may drain at different rates.

**Open Issues:**

- Should thirst drain faster than hunger?

---

### UC-SURV-pass-out: Pass out from starvation, dehydration, or exhaustion

**UC ID and Name:** `UC-SURV-pass-out`: Pass out from starvation, dehydration, or exhaustion

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** A crew member's hunger, thirst, or fatigue reaches zero.

**Description:** A crew member who runs out of food, water, or energy passes out and can't act for a cooldown. They then get back up with their stats partly restored. This punishes neglect without removing the player from the game.

**Preconditions:**

- PRE-1. The session is active.
- PRE-2. The crew member's hunger, thirst, or fatigue is zero.

**Postconditions:**

- POST-1. The crew member is conscious and can act again.
- POST-2. The crew member's hunger, thirst, and fatigue are each at one quarter of maximum.

**Main Success Scenario:**

1. The system detects that the crew member's hunger, thirst, or fatigue has reached zero.
2. The system puts the crew member into a passed-out state. They can't move, interact, or use items.
3. The system releases any station the crew member was using (`UC-DECK-claim-station`).
4. The system starts the pass-out cooldown and shows the remaining time on the crew member's screen.
5. The cooldown ends.
6. The system restores the crew member's hunger, thirst, and fatigue to one quarter of maximum.
7. The system returns control to the crew member.
8. Use case ends.

**Extensions:**

- **2a. Every crew member in the session is passed out at the same time:**
    - 2a1. The system keeps each crew member's cooldown running as normal; the voyage does not end.
    - 2a2. Flow rejoins the main scenario at step 3.
- **4a. The ship capsizes while the crew member is passed out:**
    - 4a1. The system applies the capsize reset (`UC-WAVE-capsize-ship`) with the crew member still passed out.
    - 4a2. Flow rejoins the main scenario at step 5.
- **4b. The crew member disconnects while passed out:**
    - 4b1. The system keeps the cooldown running on the Host.
    - 4b2. When they reconnect, the crew member rejoins in whatever state the cooldown has reached.
    - 4b3. Flow rejoins the main scenario at step 5.

**Priority:** High

**Frequency of Use:** Occasional. Only when a crew member neglects food, water, or rest.

**Business Rules:** `BR-pass-out-recovery`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| passed-out state | Boolean | True only while the cooldown is running | Set only by the Host's instance | Crew Member |
| pass-out cooldown | Duration | TBD | N/A | Crew Member |
| recovery stat level | Float (fraction) | 0.25 of maximum, for hunger, thirst, and fatigue | N/A | — |

Failure behavior: The crew member's state and stats are session state owned by the Host. The restore to one quarter is applied only when the cooldown completes.

**Related Use Cases:** `UC-SURV-deplete-hunger-thirst`, `UC-FTG-deplete-fatigue`, `UC-FTG-warn-exhaustion`, `UC-DECK-claim-station`, `UC-WAVE-capsize-ship`, `UC-SURV-recover-from-illness`

**Assumptions:** Crew members never permanently die. The quarter restore applies to all three stats, even if only one hit zero. Teammates cannot speed up another crew member's recovery.

**Open Issues:**

- What is the pass-out cooldown duration?

---

### UC-SURV-recover-from-illness: Recover from illness

**UC ID and Name:** `UC-SURV-recover-from-illness`: Recover from illness

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** A crew member eats raw food that isn't fruit (`UC-SURV-consume-food`, extension 2a).

**Description:** Eating raw food like fish makes a crew member sick. While ill, their fatigue drains extra, usually down to about half, until the illness wears off on its own. This makes cooking worth the effort.

**Preconditions:**

- PRE-1. The session is active.
- PRE-2. The crew member has just eaten raw food that isn't fruit.

**Postconditions:**

- POST-1. The crew member is no longer ill.
- POST-2. Any fatigue lost to illness is not refunded; it has to be recovered by resting (`UC-FTG-rest`).

**Main Success Scenario:**

1. The system marks the crew member as ill and shows an illness indicator on their screen.
2. The system starts the illness timer.
3. The system drains the crew member's fatigue at the illness rate, on top of normal depletion (`UC-FTG-deplete-fatigue`).
4. The crew member's fatigue reaches the illness floor (about half of maximum).
5. The system stops the extra illness drain; normal depletion continues.
6. The illness timer ends.
7. The system clears the ill state and removes the indicator.
8. Use case ends.

**Extensions:**

- **1a. The crew member is already ill when they eat raw food again:**
    - 1a1. [TBD] The system restarts the illness timer, or extends it.
    - 1a2. Flow rejoins the main scenario at step 3.
- **3a. The crew member's fatigue is already below the illness floor:**
    - 3a1. The system applies no extra illness drain.
    - 3a2. Flow rejoins the main scenario at step 6.
- **3b. The illness timer ends before fatigue reaches the floor:**
    - 3b1. The system stops the extra drain.
    - 3b2. Flow rejoins the main scenario at step 7.
- **5a. Normal depletion takes fatigue to zero while ill:**
    - 5a1. The system triggers `UC-SURV-pass-out`; the illness timer keeps running.
    - 5a2. Flow rejoins the main scenario at step 6.

**Priority:** Medium

**Frequency of Use:** Occasional. Only when a crew member eats raw food that isn't fruit.

**Business Rules:** `BR-illness-fatigue-floor`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| ill state | Boolean | True from eating raw food until the timer ends | Set only by the Host's instance | Illness |
| illness duration | Duration | TBD | N/A | Illness |
| illness drain rate | Float (fatigue per second) | TBD | N/A | Illness |
| illness fatigue floor | Float (fraction of max) | About 0.5; exact value or variation TBD | N/A | Illness |

Failure behavior: The ill state and fatigue are session state owned by the Host. A client that desyncs receives the Host's values on the next sync.

**Related Use Cases:** `UC-SURV-consume-food`, `UC-FTG-deplete-fatigue`, `UC-FTG-rest`, `UC-SURV-pass-out`

**Assumptions:** There is no cure item; illness only wears off with time. Resting in the hammock still recovers fatigue while ill.

**Open Issues:**

- Does the illness floor vary (e.g. between 40% and 60%), or is it always half?
- What happens if a crew member eats raw food again while already ill?

---

## Area: Fatigue (`FTG`)

### UC-FTG-rest: Rest to recover fatigue

**UC ID and Name:** `UC-FTG-rest`: Rest to recover fatigue

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member claims a slot at the Hammock station.

**Description:** A crew member lies in a hammock to recover fatigue. While resting they can't work any other station, so the crew has to take turns and balance rest against keeping the ship running.

**Preconditions:**

- PRE-1. The crew member has claimed a free hammock slot at the Hammock station (`UC-DECK-claim-station`).
- PRE-2. The crew member is not passed out.

**Postconditions:**

- POST-1. The crew member's fatigue has increased by the time spent resting, up to the maximum.

**Main Success Scenario:**

1. The system places the crew member in the hammock and shows the resting state.
2. The system increases the crew member's fatigue at the rest recovery rate.
3. The system updates the crew member's fatigue bar.
4. The crew member leaves the station (`UC-DECK-use-station`, step 7).
5. The system stops fatigue recovery.
6. Use case ends.

**Extensions:**

- **1a. Every hammock slot is occupied:**
    - 1a1. The system denies the request and tells the crew member the hammocks are full.
    - 1a2. Use case ends.
- **2a. The crew member's fatigue reaches the maximum:**
    - 2a1. [TBD] The system either keeps the crew member in the hammock at full fatigue or releases them automatically.
    - 2a2. Flow rejoins the main scenario at step 4, or at step 5 if released automatically.
- **2b. Hunger or thirst reaches zero while resting:**
    - 2b1. The system releases the hammock slot and triggers `UC-SURV-pass-out`.
    - 2b2. Use case ends.
- **2c. The ship capsizes while the crew member is resting:**
    - 2c1. The system releases the hammock slot as part of the capsize reset (`UC-WAVE-capsize-ship`).
    - 2c2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Frequent. Each crew member rests several times per session.

**Business Rules:** `BR-station-slots`, `BR-stat-max`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| fatigue | Float | 0 to max (TBD) | Per crew member; changed only by the Host's instance | Fatigue |
| hammock slots | Integer | 2 (stacked bunks) | N/A | Hammock |
| rest recovery rate | Float (per second) | TBD | N/A | Hammock |

Failure behavior: Fatigue is session state owned by the Host. A client that desyncs receives the Host's values on the next sync.

**Related Use Cases:** `UC-DECK-use-station`, `UC-DECK-claim-station`, `UC-FTG-deplete-fatigue`, `UC-SURV-pass-out`, `UC-SURV-recover-from-illness`

**Assumptions:** The Hammock station has 2 slots (stacked bunks), so two crew members can rest at once. Hunger and thirst keep draining while resting.

**Open Issues:**

- Does a crew member get kicked out of the hammock at full fatigue?

---

### UC-FTG-deplete-fatigue: Deplete fatigue over time

**UC ID and Name:** `UC-FTG-deplete-fatigue`: Deplete fatigue over time

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** A crew member joins an active voyage and is not passed out or resting.

**Description:** The system steadily drains each crew member's own fatigue over time, so the crew has to take turns resting in the hammock.

**Preconditions:**

- PRE-1. The session is active (not paused).
- PRE-2. The crew member is not passed out.
- PRE-3. The crew member is not resting in the hammock.

**Postconditions:**

- POST-1. Each crew member's fatigue reflects the time elapsed and is shown on that crew member's screen.

**Main Success Scenario:**

1. The system decreases the crew member's fatigue at a steady rate.
2. The system updates the crew member's fatigue bar.
3. The system repeats steps 1–2 for as long as the session is active.
4. Use case ends when the session ends.

**Extensions:**

- **1a. The crew member's fatigue falls below the exhaustion threshold:**
    - 1a1. The system triggers `UC-FTG-warn-exhaustion`.
    - 1a2. Flow rejoins the main scenario at step 2.
- **1b. The crew member's fatigue reaches zero:**
    - 1b1. The system triggers `UC-SURV-pass-out`.
    - 1b2. The system stops depleting fatigue until the crew member recovers.
    - 1b3. Flow rejoins the main scenario at step 1 once the crew member recovers.
- **1c. The crew member starts resting, or the session is paused:**
    - 1c1. The system stops depleting fatigue until the crew member leaves the hammock or the session resumes.
    - 1c2. Flow rejoins the main scenario at step 1.
- **1d. The crew member is ill:**
    - 1d1. The system also applies the extra illness drain (`UC-SURV-recover-from-illness`).
    - 1d2. Flow rejoins the main scenario at step 2.

**Priority:** High

**Frequency of Use:** Continuous. Runs for every crew member for the whole session.

**Business Rules:** `BR-stat-depletion-rate`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| fatigue depletion rate | Float (per second) | Constant; TBD | N/A | Fatigue |

Failure behavior: Fatigue is session state owned by the Host. A client that desyncs receives the Host's values on the next sync.

**Related Use Cases:** `UC-FTG-rest`, `UC-FTG-warn-exhaustion`, `UC-SURV-pass-out`, `UC-SURV-recover-from-illness`, `UC-PROG-pause-game`

**Assumptions:** Fatigue drains at a steady rate, whatever the crew member is doing.

**Open Issues:** none

---

### UC-FTG-warn-exhaustion: Warn of exhaustion

**UC ID and Name:** `UC-FTG-warn-exhaustion`: Warn of exhaustion

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** A crew member's fatigue falls below the exhaustion threshold.

**Description:** When a crew member is close to passing out from fatigue, the system turns their fatigue bar red to warn them to rest. Being exhausted has no other penalty.

**Preconditions:**

- PRE-1. The session is active.
- PRE-2. The crew member's fatigue is below the exhaustion threshold.

**Postconditions:**

- POST-1. The crew member's fatigue bar is shown in red for as long as fatigue stays below the threshold.

**Main Success Scenario:**

1. The system detects that the crew member's fatigue has fallen below the exhaustion threshold.
2. The system turns the crew member's fatigue bar red.
3. The crew member rests (`UC-FTG-rest`) and fatigue rises above the threshold.
4. The system returns the fatigue bar to its normal color.
5. Use case ends.

**Extensions:**

- **3a. Fatigue reaches zero before the crew member rests:**
    - 3a1. The system triggers `UC-SURV-pass-out`.
    - 3a2. When the crew member recovers at one quarter fatigue, the system rechecks the threshold.
    - 3a3. Flow rejoins the main scenario at step 4 if they're above the threshold, or at step 2 if they're below.

**Priority:** Low

**Frequency of Use:** Occasional.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| exhaustion threshold | Float | Below maximum fatigue; TBD | N/A | Fatigue |

Failure behavior: This use case makes no durable change. It's a display state only.

**Related Use Cases:** `UC-FTG-deplete-fatigue`, `UC-FTG-rest`, `UC-SURV-pass-out`

**Assumptions:** Being exhausted has no gameplay effect besides the red bar.

**Open Issues:**

- Should hunger and thirst bars also turn red when low, for consistency? If so, this could become one "warn of low stat" use case.

---

## Area: Ship Damage & Repair (`SHIP`)

### UC-SHIP-take-damage: Spring a leak or take damage

**UC ID and Name:** `UC-SHIP-take-damage`: Spring a leak or take damage

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** The damage timer expires.

**Description:** Over time, the ship springs leaks at random spots on the deck, and each unrepaired leak lowers the ship's integrity by 5%. Storms make leaks happen more often. If integrity reaches 0% (20 open leaks), the ship capsizes.

**Preconditions:**

- PRE-1. The session is active (not paused).

**Postconditions:**

- POST-1. A new Repair Spot exists at a random deck location, visible to all crew members.
- POST-2. Ship integrity has decreased by 5%.

**Main Success Scenario:**

1. The damage timer expires.
2. The system picks a random valid location on the deck.
3. The system spawns a Repair Spot (leak) at that location.
4. The system syncs the new Repair Spot to all clients.
5. The system reduces the ship's integrity by 5%.
6. The system restarts the damage timer.
7. Use case ends.

**Extensions:**

- **1a. A storm is in progress (`UC-EVT-weather-storm`):**
    - 1a1. The system uses a shorter damage interval, and shorter still if the ship is not diagonal to the waves or the sail is raised.
    - 1a2. Flow rejoins the main scenario at step 2.
- **1b. The ship collides with an island, rock, or ship (`UC-NAV-steer-ship`, 3d):**
    - 1b1. [TBD] The system spawns a Repair Spot immediately, outside the timer.
    - 1b2. Flow rejoins the main scenario at step 2.
- **2a. The chosen location overlaps a station or another Repair Spot:**
    - 2a1. The system picks a different location.
    - 2a2. Flow rejoins the main scenario at step 3.
- **5a. Ship integrity reaches 0%:**
    - 5a1. The system triggers `UC-WAVE-capsize-ship`.
    - 5a2. Use case ends.

**Priority:** High

**Frequency of Use:** Periodic, more often during storms.

**Business Rules:** `BR-damage-interval`, `BR-capsize-conditions`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| ship integrity | Float (%) | 100% means no open leaks; decreases 5% per open leak; capsize at 0% | Changed only by the Host's instance | Ship |
| integrity loss per leak | Float (%) | 5 | N/A | Ship |
| damage interval | Duration | Normal and storm values; TBD | N/A | Ship |
| Repair Spot location | Vector2 (relative to ship) | Within deck bounds; not on a station or another spot | Generated only by the Host's instance | Repair Spot |

Failure behavior: This use case makes durable changes to ship integrity and the set of Repair Spots. The Host spawns the spot and lowers integrity together. Clients that desync receive the Host's state on the next sync.

**Related Use Cases:** `UC-SHIP-repair-damage`, `UC-WAVE-capsize-ship`, `UC-EVT-weather-storm`, `UC-NAV-steer-ship`

**Assumptions:** There is only one kind of damage (a leak). Integrity changes only when a leak appears or is repaired; there is no drain over time. 20 open leaks cause a capsize.

**Open Issues:**

- Do collisions cause damage?
- What are the normal and storm damage intervals?

---

### UC-SHIP-repair-damage: Repair ship damage

**UC ID and Name:** `UC-SHIP-repair-damage`: Repair ship damage (also covers list item 22, "Jointly repair major damage")

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** Other Crew Members (joining the repair)

**Trigger:** A crew member presses and holds interact at a Repair Spot.

**Description:** A crew member patches a leak by holding interact for a few seconds and spending wood from the ship's deck chest. Other crew members can join to finish the repair faster.

**Preconditions:**

- PRE-1. The crew member is within interaction range of a Repair Spot.
- PRE-2. The crew member is not passed out.

**Postconditions:**

- POST-1. The Repair Spot is removed from the deck for all clients.
- POST-2. The wood cost has been removed from the deck chest.
- POST-3. Ship integrity has increased by 5%.

**Main Success Scenario:**

1. The crew member moves within range of a Repair Spot.
2. The system displays a repair prompt showing the wood cost.
3. The crew member presses and holds the interact input.
4. The system claims the Repair Spot for the crew member (`UC-DECK-claim-station`) and shows a progress bar.
5. The crew member keeps holding until the progress bar completes.
6. The system removes the wood cost from the deck chest.
7. The system removes the Repair Spot and restores 5% ship integrity.
8. The system syncs the change to all clients and releases the crew member.
9. Use case ends.

**Extensions:**

- **3a. The deck chest does not have enough wood:**
    - 3a1. The system blocks the repair and tells the crew member they need more wood.
    - 3a2. Use case ends.
- **4a. Another crew member joins the same Repair Spot (joint repair):**
    - 4a1. The system adds them as an additional occupant.
    - 4a2. The system increases the repair speed for each additional crew member.
    - 4a3. The wood cost is charged once per repair, not once per crew member.
    - 4a4. Flow rejoins the main scenario at step 5.
- **5a. The crew member releases interact before the repair completes:**
    - 5a1. The system stops the repair and discards all progress.
    - 5a2. The system releases the crew member from the Repair Spot.
    - 5a3. Use case ends.
- **5b. The crew member passes out or the ship capsizes mid-repair:**
    - 5b1. The system cancels the repair as in 5a.
    - 5b2. Use case ends.

**Priority:** High

**Frequency of Use:** Frequent. Several times per session, more during storms.

**Business Rules:** `BR-repair-cost`, `BR-station-slots`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| repair duration | Duration | About 3–5 seconds for one crew member | N/A | Repair Spot |
| joint repair speed bonus | Float | Per extra crew member; TBD | N/A | Repair Spot |
| wood cost | Integer | Per repair; TBD | Deducted from the deck chest only by the Host's instance | Wood |

Failure behavior: This use case makes durable changes to the deck chest, the Repair Spot, and integrity. The Host removes the wood, removes the Repair Spot, and restores integrity together; if any step fails, none is applied.

**Related Use Cases:** `UC-SHIP-take-damage`, `UC-DECK-claim-station`, `UC-ISLE-collect-island-items`, `UC-SYS-shared-inventory`

**Assumptions:** Repairing is the only station action that uses press-and-hold. There is only one damage type, so joint repair just makes any repair faster.

**Open Issues:**

- How much wood does one repair cost?
- How much faster is each extra crew member?

---

## Area: Events & Encounters (`EVT`)

### UC-EVT-generate-event: Generate a random ocean event

**UC ID and Name:** `UC-EVT-generate-event`: Generate a random ocean event (also covers list item 40, "Event generation / picking per tile")

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** The ship enters a map tile it hasn't entered before.

**Description:** When the ship sails into a new area, the system may start a random event picked from that tile's event list, such as a storm or a merchant boat. This keeps each voyage varied.

**Preconditions:**

- PRE-1. The session is active (not paused).
- PRE-2. The tile has an event list defined.

**Postconditions:**

- POST-1. The tile is marked as having had its event roll.
- POST-2. If an event was picked, it is active and synced to all clients.

**Main Success Scenario:**

1. The system detects that the ship has entered a new tile (`UC-SYS-track-boat`).
2. The system rolls whether an event occurs on this tile.
3. The system picks one event from the tile's event list.
4. The system starts the event and syncs it to all clients.
5. The system marks the tile as rolled.
6. Use case ends.

**Extensions:**

- **1a. The ship enters a tile that has already been rolled:**
    - 1a1. The system does not roll again.
    - 1a2. Use case ends.
- **2a. The roll produces no event:**
    - 2a1. The system marks the tile as rolled.
    - 2a2. Use case ends.
- **3a. The picked event is a storm:**
    - 3a1. The system starts `UC-EVT-weather-storm`.
    - 3a2. Flow rejoins the main scenario at step 5.
- **3b. The picked event is a merchant boat:**
    - 3b1. The system spawns a merchant boat near the ship (see `UC-EVT-trade-with-merchant`).
    - 3b2. Flow rejoins the main scenario at step 5.

**Priority:** High

**Frequency of Use:** Frequent. Every time the ship enters a new tile.

**Business Rules:** `BR-event-roll-once-per-tile`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| tile event list | List of event types | Defined per tile; contents TBD (future modification) | N/A | Event |
| event chance | Float (probability) | 0–1; TBD | Rolled only by the Host's instance | Event |
| tile rolled flag | Boolean | Per tile, per voyage | N/A | Tile |

Failure behavior: This use case makes a durable change to the tile's rolled flag for the rest of the voyage. The Host sets the flag and starts the event together, so a tile never gets rolled twice.

**Related Use Cases:** `UC-SYS-track-boat`, `UC-EVT-weather-storm`, `UC-EVT-trade-with-merchant`

**Assumptions:** Each tile rolls for an event only once per voyage. Only one event is picked per tile.

**Open Issues:**

- What events go on each tile's list? (Left for future modification.)
- Can tiles be weighted, e.g. storms more common in some regions?

---

### UC-EVT-trade-with-merchant: Trade with a traveling merchant

**UC ID and Name:** `UC-EVT-trade-with-merchant`: Trade with a traveling merchant

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member interacts with a merchant, either on an island or on a merchant boat.

**Description:** A crew member buys items or ship upgrades with the crew's shared gold, or sells rare finds and supplies for gold. Merchants appear on islands or on randomly generated boats at sea.

**Preconditions:**

- PRE-1. The crew member is within interaction range of a merchant.
- PRE-2. The crew member is not passed out.

**Postconditions:**

- POST-1. The crew's shared gold reflects every purchase and sale.
- POST-2. Each purchased item is in the buyer's inventory, or each purchased upgrade is applied to the ship; each sold item is removed from the seller's inventory.

**Main Success Scenario:**

1. The crew member interacts with the merchant.
2. The system opens the merchant's trade menu, showing items with their gold prices.
3. The crew member selects an item to buy.
4. The system checks that the crew has enough gold.
5. The system deducts the gold and delivers the item.
6. The crew member closes the trade menu.
7. Use case ends.

**Extensions:**

- **3a. The crew member chooses to sell instead of buy:**
    - 3a1. The crew member selects an item from their inventory.
    - 3a2. The system shows the merchant's gold offer.
    - 3a3. The crew member confirms the sale.
    - 3a4. The system removes the item and adds the gold to the crew's shared gold.
    - 3a5. Flow rejoins the main scenario at step 6.
- **4a. The crew doesn't have enough gold:**
    - 4a1. The system blocks the purchase and shows how much gold is needed.
    - 4a2. Flow rejoins the main scenario at step 3.
- **5a. The item is a ship upgrade:**
    - 5a1. The system applies the upgrade to the ship instead of adding an item ([TBD] upgrade system not yet designed).
    - 5a2. Flow rejoins the main scenario at step 6.
- **5b. The buyer's inventory is full:**
    - 5b1. The system blocks the purchase and tells the crew member to make room.
    - 5b2. Flow rejoins the main scenario at step 3.
- **6a. A merchant boat drifts out of interaction range mid-trade:**
    - 6a1. The system closes the trade menu. Completed trades are kept.
    - 6a2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Occasional. When the crew finds a merchant.

**Business Rules:** `BR-merchant-pricing`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| gold | Integer | ≥ 0 | Shared by the whole crew; changed only by the Host's instance | Gold |
| merchant stock | List of item IDs + prices | Drawn from the item pool (`UC-SYS-item-pool`); TBD | N/A | Merchant |
| merchant location | Island or merchant boat | Spawned with islands or by `UC-EVT-generate-event` | N/A | Merchant |

Failure behavior: This use case makes durable changes to gold and inventory. The Host changes the gold and moves the item together, or neither.

**Related Use Cases:** `UC-EVT-generate-event`, `UC-SYS-item-pool`, `UC-SYS-player-inventory`, `UC-SYS-shared-inventory` (chest capacity upgrades), `UC-ISLE-arrive-at-island`

**Assumptions:** Buying and selling are both supported. Ship upgrades, such as more deck chest capacity, are a placeholder until that system is designed. Crew members trade with merchant boats from the ship's deck when the boats are alongside.

**Open Issues:**

- What do upgrades actually do? (Future design.)

---

### UC-EVT-weather-storm: Weather a storm

**UC ID and Name:** `UC-EVT-weather-storm`: Weather a storm

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member (whole crew)

**Secondary Actors:** none

**Trigger:** A storm event starts (`UC-EVT-generate-event`).

**Description:** A storm brings rough waves and more frequent leaks. To come through with the least damage, the crew angles the ship diagonally into the waves, lowers the sail, and keeps up with repairs until the storm passes.

**Preconditions:**

- PRE-1. The session is active (not paused).

**Postconditions:**

- POST-1. The storm has ended, waves have stopped, and leaks spawn at the normal rate again.

**Main Success Scenario:**

1. The system starts the storm: it generates waves (`UC-WAVE-generate-waves`), shortens the damage interval (`UC-SHIP-take-damage`), and starts the storm timer.
2. A crew member at the Steering station angles the ship diagonally into the waves (`UC-WAVE-balance-ship`).
3. A crew member at the Sail station lowers the sail (`UC-NAV-raise-lower-sail`).
4. Crew members repair leaks as they appear (`UC-SHIP-repair-damage`).
5. The storm timer ends.
6. The system ends the storm: the waves fade and the damage interval returns to normal.
7. Use case ends.

**Extensions:**

- **2a. The ship is not diagonal to the waves, or no one is steering:**
    - 2a1. The system reduces stability faster and spawns leaks more often.
    - 2a2. Flow rejoins the main scenario at step 4.
- **3a. The sail stays raised during the storm:**
    - 3a1. The system reduces stability faster and spawns leaks more often.
    - 3a2. Flow rejoins the main scenario at step 4.
- **4a. The ship capsizes (stability or integrity reaches zero):**
    - 4a1. The system ends the storm and triggers `UC-WAVE-capsize-ship`.
    - 4a2. Use case ends.

**Priority:** High

**Frequency of Use:** Occasional. When a tile's event roll picks a storm.

**Business Rules:** `BR-capsize-conditions`, `BR-damage-interval`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| storm duration | Duration | TBD | Run only by the Host's instance | Storm |
| storm damage interval | Duration | Shorter than normal; shorter still if not diagonal or sail raised; TBD | N/A | Ship |

Failure behavior: The storm itself makes no durable change; its effects happen through `UC-SHIP-take-damage` and `UC-WAVE-capsize-ship`, which handle their own durable changes.

**Related Use Cases:** `UC-EVT-generate-event`, `UC-WAVE-generate-waves`, `UC-WAVE-balance-ship`, `UC-NAV-raise-lower-sail`, `UC-SHIP-take-damage`, `UC-SHIP-repair-damage`, `UC-WAVE-capsize-ship`

**Assumptions:** A storm lasts a set time and can't be escaped by sailing away. Being diagonal with the sail lowered reduces both capsize risk and how often leaks appear.

**Open Issues:**

- Does the wind behave differently during a storm (`UC-NAV-change-wind`, extension 2b)?
- Does a storm reduce visibility or the lookout's view?

---

## Area: Progress & Session (`PROG`)

### UC-PROG-track-progress: Track voyage progress

**UC ID and Name:** `UC-PROG-track-progress`: Track voyage progress

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (views progress)

**Trigger:** The ship's position changes.

**Description:** The system keeps track of how far the ship is from Paradise Island and shows that distance on the map, so the crew can see they're making progress.

**Preconditions:**

- PRE-1. A voyage is in progress.
- PRE-2. Paradise Island's location is set for this voyage.

**Postconditions:**

- POST-1. The distance to Paradise Island shown on the map matches the ship's current position.

**Main Success Scenario:**

1. The system detects that the ship's position has changed (`UC-SYS-track-boat`).
2. The system calculates the distance from the ship to Paradise Island.
3. The system updates the distance shown on the map (`UC-MAP-open-map`).
4. Use case ends.

**Extensions:**

- **1a. The ship is reset by a capsize or restart:**
    - 1a1. The system recalculates the distance from the ship's new position.
    - 1a2. Flow rejoins the main scenario at step 3.
- **2a. The ship reaches Paradise Island:**
    - 2a1. The system triggers `UC-PROG-reach-paradise`.
    - 2a2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Continuous while sailing.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| distance to Paradise Island | Float (meters) | ≥ 0 | Calculated only by the Host's instance | Paradise Island |
| Paradise Island location | Vector2 (map) | Set at voyage start | N/A | Paradise Island |

Failure behavior: This use case makes no durable change. The distance is recalculated from the ship's position.

**Related Use Cases:** `UC-SYS-track-boat`, `UC-MAP-open-map`, `UC-PROG-reach-paradise`

**Assumptions:** Progress is shown as a distance on the map, not as a separate progress bar.

**Open Issues:**

- Is the distance straight-line, or does it count along a route?

---

### UC-PROG-reach-paradise: Reach Paradise Island

**UC ID and Name:** `UC-PROG-reach-paradise`: Reach Paradise Island (victory)

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (all)

**Trigger:** The ship arrives at Paradise Island.

**Description:** When the crew reaches Paradise Island, the voyage is complete. What happens on arrival is still being designed.

**Preconditions:**

- PRE-1. A voyage is in progress.
- PRE-2. The ship is within arrival range of Paradise Island.

**Postconditions:**

- POST-1. The voyage is marked complete.

**Main Success Scenario:**

1. The system detects that the ship has reached Paradise Island.
2. The system [TBD] plays the victory sequence for all crew members.
3. The system marks the voyage as complete.
4. Use case ends.

**Extensions:**

- **1a. A crew member is not aboard (e.g. still on another island):**
    - 1a1. [TBD] The system either waits for all crew members, or triggers victory for everyone anyway.
    - 1a2. Flow rejoins the main scenario at step 2.

**Priority:** High

**Frequency of Use:** Once per completed voyage.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| arrival range | Float (distance) | TBD | N/A | Paradise Island |
| voyage complete flag | Boolean | Set once | Set only by the Host's instance | Voyage |

Failure behavior: Voyages are not saved, so completion isn't stored anywhere after the session ends.

**Related Use Cases:** `UC-PROG-track-progress`, `UC-PROG-start-voyage`

**Assumptions:** none yet

**Open Issues:**

- What happens on victory: an end screen, stats, credits, returning to the lobby? (Left open for now.)
- Does the whole crew need to be aboard?

---

### UC-PROG-quit-voyage: Quit the voyage

**UC ID and Name:** `UC-PROG-quit-voyage`: Quit the voyage

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** Host

**Trigger:** A crew member selects Quit from the menu.

**Description:** A crew member leaves the voyage. If the Host quits, the session ends for everyone. The crew cannot lose, so quitting is the only way a voyage ends early.

**Preconditions:**

- PRE-1. The crew member is in an active session.

**Postconditions:**

- POST-1. The crew member has left the session.
- POST-2. If the Host quit, the session has ended for all crew members and the voyage is gone.

**Main Success Scenario:**

1. The crew member opens the menu and selects Quit.
2. The system asks the crew member to confirm.
3. The crew member confirms.
4. The system releases any station the crew member held (`UC-DECK-claim-station`).
5. The system removes the crew member from the session and tells the remaining crew members they left.
6. The system returns the crew member to the main menu.
7. Use case ends.

**Extensions:**

- **3a. The crew member cancels:**
    - 3a1. The system closes the prompt and the crew member stays in the session.
    - 3a2. Use case ends.
- **5a. The crew member quitting is the Host:**
    - 5a1. The system warns the Host that quitting ends the voyage for everyone.
    - 5a2. The system ends the session and returns all crew members to the main menu.
    - 5a3. Use case ends.

**Priority:** Medium

**Frequency of Use:** Once per session.

**Business Rules:** `BR-host-ends-session`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| session membership | List of crew member IDs | 1–4 | Managed only by the Host's instance | Session |

Failure behavior: Voyages are not saved. When the Host quits, the voyage is discarded permanently; every voyage is unique.

**Related Use Cases:** `UC-PROG-host-join`, `UC-PROG-start-voyage`, `UC-DECK-claim-station`

**Assumptions:** There is no host migration; the session can't continue without the Host.

**Open Issues:** none

---

### UC-PROG-start-voyage: Start or restart a voyage

**UC ID and Name:** `UC-PROG-start-voyage`: Start or restart a voyage

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Host

**Secondary Actors:** Crew Member (all)

**Trigger:** The Host selects Start Voyage from the lobby, or Restart Voyage from the menu.

**Description:** The Host begins a new voyage for the crew, or throws out the current one and starts fresh. Each voyage is randomly generated and never saved.

**Preconditions:**

- PRE-1. The Host has a session open (`UC-PROG-host-join`).

**Postconditions:**

- POST-1. A new voyage is running with the ship at the starting point, every crew member's stats full, and starting inventory.

**Main Success Scenario:**

1. The Host selects Start Voyage.
2. The system generates the voyage: the map, islands, shipwrecks, merchants, and Paradise Island's location.
3. The system places the ship at the starting point and the crew members on deck.
4. The system sets each crew member's hunger, thirst, and fatigue to full and gives starting inventory.
5. The system syncs the voyage to all clients.
6. Use case ends.

**Extensions:**

- **1a. The Host selects Restart during an active voyage:**
    - 1a1. The system asks the Host to confirm, warning that all progress will be lost.
    - 1a2. The Host confirms.
    - 1a3. Flow rejoins the main scenario at step 2.
- **1a2a. The Host cancels the restart:**
    - 1a2a1. The voyage continues unchanged.
    - 1a2a2. Use case ends.
- **5a. A crew member's client fails to load the voyage:**
    - 5a1. The system retries the sync; if it still fails, it removes that crew member from the session.
    - 5a2. Use case ends.

**Priority:** High

**Frequency of Use:** Once per voyage.

**Business Rules:** `BR-host-controls-session`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| voyage seed | Integer | Random per voyage | Generated only by the Host's instance | Voyage |
| starting inventory | List of items | TBD | N/A | Inventory |

Failure behavior: This use case replaces all voyage state. On restart, the old voyage is discarded only after the new one has been generated.

**Related Use Cases:** `UC-PROG-host-join`, `UC-PROG-quit-voyage`, `UC-WAVE-capsize-ship` (resets to the start if no island has been visited)

**Assumptions:** Only the Host can start or restart. Each voyage is unique and is never saved (similar to PEAK).

**Open Issues:**

- What is the starting inventory (e.g. a water bottle each, some wood)?

---

### UC-PROG-host-join: Host or join a multiplayer voyage

**UC ID and Name:** `UC-PROG-host-join`: Host or join a multiplayer voyage

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Host

**Secondary Actors:** Crew Member (joining)

**Trigger:** A player selects Host or Join from the main menu.

**Description:** One player hosts a session on the local network (LAN), and up to three others join it, making a crew of up to four. Players can also join a voyage already in progress.

**Preconditions:**

- PRE-1. All players are on the same local network.

**Postconditions:**

- POST-1. A session exists with the Host plus 0–3 joined crew members.

**Main Success Scenario:**

1. The Host selects Host Game.
2. The system creates a session on the local network and shows the lobby.
3. Another player selects Join Game.
4. The system lists the sessions available on the local network.
5. The player selects the Host's session.
6. The system adds the player to the session as a crew member and updates the lobby for everyone.
7. Use case ends.

**Extensions:**

- **4a. No sessions are found on the network:**
    - 4a1. The system tells the player no sessions were found and offers to refresh.
    - 4a2. Flow rejoins the main scenario at step 4, or use case ends.
- **6a. The session already has 4 players:**
    - 6a1. The system denies the join and tells the player the session is full.
    - 6a2. Use case ends.
- **6b. The connection fails:**
    - 6b1. The system tells the player the connection failed.
    - 6b2. Flow rejoins the main scenario at step 4.
- **6c. The voyage has already started:**
    - 6c1. The system adds the player to the voyage as a crew member.
    - 6c2. The system places them on the ship's deck with full stats and starting inventory.
    - 6c3. Use case ends.

**Priority:** High

**Frequency of Use:** Once per session.

**Business Rules:** `BR-session-cap-4`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| session | Host address + player list | 1–4 players | Visible only on the local network | Session |

Failure behavior: This use case makes no durable change. A failed join leaves the session unchanged.

**Related Use Cases:** `UC-PROG-start-voyage`, `UC-PROG-quit-voyage`, `UC-PROG-choose-character`

**Assumptions:** LAN only for now; no online play. The Host is also a crew member.

**Open Issues:** none

---

### UC-PROG-pause-game: Pause the game

**UC ID and Name:** `UC-PROG-pause-game`: Pause the game

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Host

**Secondary Actors:** Crew Member (all)

**Trigger:** The Host presses the pause input.

**Description:** The Host pauses the voyage for the whole crew, freezing all timers and stats until they resume.

**Preconditions:**

- PRE-1. A voyage is in progress and not paused.

**Postconditions:**

- POST-1. The voyage has resumed with all timers and stats exactly as they were when paused.

**Main Success Scenario:**

1. The Host presses the pause input.
2. The system freezes the voyage for everyone: movement, stat depletion, wind, waves, and every timer.
3. The system shows the pause screen to all crew members.
4. The Host selects Resume.
5. The system unfreezes the voyage for everyone.
6. Use case ends.

**Extensions:**

- **1a. A non-Host crew member presses the pause input:**
    - 1a1. [TBD] The system opens their menu without pausing the game.
    - 1a2. Use case ends.
- **4a. The Host selects Quit from the pause screen:**
    - 4a1. Flow continues in `UC-PROG-quit-voyage`, extension 5a.
    - 4a2. Use case ends.
- **4b. A crew member disconnects while the game is paused:**
    - 4b1. The system removes them and updates the pause screen.
    - 4b2. Flow rejoins the main scenario at step 4.

**Priority:** Medium

**Frequency of Use:** Occasional.

**Business Rules:** `BR-host-controls-session`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| paused state | Boolean | — | Only the Host's instance can change it | Session |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-PROG-quit-voyage`, and every timer-based use case (they all stop while paused)

**Assumptions:** Only the Host can pause, and pausing affects everyone.

**Open Issues:**

- What does a non-Host crew member see if they press pause?

---

### UC-PROG-choose-character: Choose a character

**UC ID and Name:** `UC-PROG-choose-character`: Choose a character (added; not on the team's list)

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member opens character selection in the lobby.

**Description:** Each crew member picks how they look by choosing from a set of preset characters. There's no piece-by-piece customization.

**Preconditions:**

- PRE-1. The crew member is in a session lobby (`UC-PROG-host-join`).

**Postconditions:**

- POST-1. The crew member's chosen character is shown to everyone in the lobby and used in the voyage.

**Main Success Scenario:**

1. The crew member opens character selection.
2. The system shows the available preset characters.
3. The crew member selects a character.
4. The system assigns that character to the crew member and updates the lobby for everyone.
5. Use case ends.

**Extensions:**

- **3a. The crew member doesn't choose before the voyage starts, or joins mid-voyage:**
    - 3a1. The system assigns a default or random character.
    - 3a2. Use case ends.

**Priority:** Low

**Frequency of Use:** Once per session per crew member.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| character | Enum (preset characters) | Must be one of the presets; list TBD | N/A | Crew Member |

Failure behavior: This use case makes no durable change. Choices are not saved between sessions.

**Related Use Cases:** `UC-PROG-host-join`

**Assumptions:** Characters are cosmetic only, with no stat differences. Several crew members can pick the same character.

**Open Issues:** none

---

## Area: System Behaviors (`SYS`)

Most of these describe how the game works under the hood rather than a goal a player sets out to accomplish. Each is written around the action it supports so it still reads as a testable flow.

### UC-SYS-item-pool: Draw items from the item pool

**UC ID and Name:** `UC-SYS-item-pool`: Draw items from the item pool

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** none

**Trigger:** Another use case needs random items (shipwreck loot chests, merchant stock, starting inventory).

**Description:** The system keeps one master list of every item in the game and picks random items from it whenever loot or merchant stock is needed, so new items only have to be added in one place.

**Preconditions:**

- PRE-1. The item pool is loaded.

**Postconditions:**

- POST-1. The requesting use case receives a valid list of items from the pool.

**Main Success Scenario:**

1. A use case requests a number of random items, optionally limited to certain categories.
2. The system filters the item pool to the allowed categories.
3. The system picks items at random according to each item's weight.
4. The system returns the picked items to the requesting use case.
5. Use case ends.

**Extensions:**

- **2a. No items match the requested categories:**
    - 2a1. The system returns an empty list and logs an error.
    - 2a2. Use case ends.

**Priority:** High

**Frequency of Use:** Frequent. Whenever loot or stock is generated.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| item ID | String | Unique | N/A | Item |
| category | Enum | Food, Wood, Water Bottle, Rare Find; more may be added | N/A | Item |
| weight | Float | > 0; TBD per item | Drawn only by the Host's instance | Item |
| sell value | Integer (gold) | ≥ 0; TBD | N/A | Gold |

Failure behavior: This use case makes no durable change. It only returns a selection.

**Related Use Cases:** `UC-ISLE-salvage-shipwreck`, `UC-SYS-shared-inventory`, `UC-EVT-trade-with-merchant`, `UC-PROG-start-voyage`

**Assumptions:** The current items are food (fruit and fish, raw and cooked), wood, water bottles, and rare finds. There are no rarity tiers yet.

**Open Issues:** none

---

### UC-SYS-player-inventory: Manage personal inventory

**UC ID and Name:** `UC-SYS-player-inventory`: Manage personal inventory

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member picks up an item or opens their inventory.

**Description:** Each crew member carries items in a personal inventory: 6 quick slots always visible on screen, plus more slots that appear when they open the full inventory. Items stack up to 30 per slot.

**Preconditions:**

- PRE-1. The crew member is in an active voyage and not passed out.

**Postconditions:**

- POST-1. The crew member's inventory reflects every item added, moved, or removed.

**Main Success Scenario:**

1. The crew member picks up an item (e.g. from a chest, a shipwreck, or the ground).
2. The system places the item in the first empty quick slot, or the first empty expanded slot if the quick slots are full, once any matching stack is full.
3. The crew member opens the full inventory.
4. The system shows the quick slots and the expanded slots.
5. The crew member moves items between slots.
6. The crew member closes the inventory.
7. Use case ends.

**Extensions:**

- **2a. The item matches a stack already in the inventory that has fewer than 30:**
    - 2a1. The system adds the item to that stack.
    - 2a2. Flow rejoins the main scenario at step 3.
- **2b. Every slot is full and no matching stack has room:**
    - 2b1. The system tells the crew member their inventory is full, and the item stays where it was.
    - 2b2. Use case ends.

**Priority:** High

**Frequency of Use:** Continuous.

**Business Rules:** `BR-inventory-slots`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| quick slots | List of item stacks | Exactly 6, always visible | Per crew member | Inventory |
| expanded slots | List of item stacks | Count TBD | Per crew member | Inventory |
| stack size | Integer | 1–30 per slot | N/A | Inventory |

Failure behavior: Inventory is session state owned by the Host. It is cleared on capsize (`UC-WAVE-capsize-ship`) and never saved between voyages.

**Related Use Cases:** `UC-SURV-consume-food`, `UC-SURV-consume-water`, `UC-SYS-shared-inventory`, `UC-SYS-item-drop`, `UC-WAVE-capsize-ship`

**Assumptions:** Items can be used straight from the quick slots.

**Open Issues:**

- How many expanded slots are there?

---

### UC-SYS-track-boat: Track the boat across the map

**UC ID and Name:** `UC-SYS-track-boat`: Track the boat across the map

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** none

**Trigger:** The ship moves.

**Description:** The system keeps track of which map tile the ship is in and tells the other systems (events, progress, the map) when it enters a new tile.

**Preconditions:**

- PRE-1. A voyage is in progress.

**Postconditions:**

- POST-1. The ship's current tile is known and synced to all clients.

**Main Success Scenario:**

1. The system updates the ship's position on the map.
2. The system checks which tile the ship is in.
3. The ship crosses into a new tile.
4. The system records the new tile and notifies `UC-EVT-generate-event`, `UC-PROG-track-progress`, and `UC-MAP-discover-map`.
5. Use case ends.

**Extensions:**

- **1a. The ship is reset by a capsize or restart:**
    - 1a1. The system moves the ship to the reset position and records that tile.
    - 1a2. Flow rejoins the main scenario at step 4.
- **3a. The ship stays in the same tile:**
    - 3a1. The system only updates the position shown on the map.
    - 3a2. Use case ends.

**Priority:** High

**Frequency of Use:** Continuous while sailing.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| ship map position | Vector2 | Within map bounds | Owned by the Host's instance | Ship |
| current tile | Tile ID | Valid tile | N/A | Tile |
| tile size | Float | TBD | N/A | Tile |

Failure behavior: This use case makes no durable change. Clients that desync get the Host's position on the next sync.

**Related Use Cases:** `UC-EVT-generate-event`, `UC-PROG-track-progress`, `UC-MAP-discover-map`

**Assumptions:** The map is divided into a grid of tiles.

**Open Issues:**

- What is the tile size?

---

### UC-SYS-shared-inventory: Use a storage chest

**UC ID and Name:** `UC-SYS-shared-inventory`: Use a storage chest

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member interacts with a chest.

**Description:** The crew keeps shared supplies in the ship's storage chest on the deck, which starts at a base capacity and can be upgraded to hold more. Shipwrecks on islands have loot chests that work the same way. Only one crew member can have a chest open at a time.

**Preconditions:**

- PRE-1. The crew member is within interaction range of a chest.
- PRE-2. The crew member is not passed out.

**Postconditions:**

- POST-1. Every item moved between the chest and the crew member's inventory is in its new place for all clients.
- POST-2. The chest is closed and unclaimed.

**Main Success Scenario:**

1. The crew member interacts with the chest.
2. The system claims the chest for the crew member (`UC-DECK-claim-station`) and opens the chest and inventory views side by side.
3. The crew member moves items between the chest and their inventory.
4. The system updates both and syncs the changes to all clients.
5. The crew member closes the chest.
6. The system releases the chest.
7. Use case ends.

**Extensions:**

- **2a. Another crew member already has the chest open:**
    - 2a1. The system denies the request and tells the crew member the chest is in use.
    - 2a2. Use case ends.
- **2b. The chest is a shipwreck loot chest being opened for the first time:**
    - 2b1. The system fills it with random loot from the item pool (`UC-SYS-item-pool`).
    - 2b2. Flow rejoins the main scenario at step 3.
- **3a. The crew member's inventory is full:**
    - 3a1. The system blocks moving more items into the inventory; the items stay in the chest.
    - 3a2. Flow rejoins the main scenario at step 3.
- **3b. The deck chest is full:**
    - 3b1. The system blocks moving more items into the chest; the items stay in the inventory.
    - 3b2. Flow rejoins the main scenario at step 3.

**Priority:** High

**Frequency of Use:** Frequent.

**Business Rules:** `BR-single-station-occupant`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| chest type | Enum | Deck chest or shipwreck loot chest | N/A | Chest |
| chest contents | List of item stacks | Deck chest: base capacity TBD, upgradable via merchants; loot chest: filled once from the item pool | Changed only by the Host's instance | Chest |

Failure behavior: This use case makes durable changes to chest and inventory contents. Each item move is applied to both sides together or not at all. The deck chest is emptied on capsize.

**Related Use Cases:** `UC-SYS-player-inventory`, `UC-SYS-item-pool`, `UC-SHIP-repair-damage` (uses wood from the deck chest), `UC-EVT-trade-with-merchant` (capacity upgrades), `UC-WAVE-capsize-ship`, `UC-ISLE-salvage-shipwreck`

**Assumptions:** The ship has one deck chest, and "shared ship storage" means that chest. Repairs draw wood from it.

**Open Issues:**

- What is the deck chest's base capacity, and how much does each upgrade add?

---

### UC-SYS-item-drop: Drop and pick up items

**UC ID and Name:** `UC-SYS-item-drop`: Drop and pick up items

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member drops an item from their inventory, or walks over an item on the ground.

**Description:** Crew members can drop items on the deck or on islands, and anyone can pick them up later by walking over them. This is also how gathered items that don't fit in an inventory stay in the world.

**Preconditions:**

- PRE-1. The crew member is not passed out.

**Postconditions:**

- POST-1. The item is either on the ground at a known position or in a crew member's inventory, never both and never neither.

**Main Success Scenario:**

1. The crew member selects an item in their inventory and drops it.
2. The system removes the item from their inventory and places it on the ground at their position.
3. The system syncs the dropped item to all clients.
4. A crew member walks over the dropped item.
5. The system automatically moves the item into that crew member's inventory and removes it from the ground.
6. Use case ends.

**Extensions:**

- **2a. The crew member is overboard:**
    - 2a1. [TBD] The system blocks the drop, or the item is lost at sea.
    - 2a2. Use case ends.
- **4a. Two crew members reach the item at the same moment:**
    - 4a1. The system gives it to whichever request the Host received first.
    - 4a2. Flow rejoins the main scenario at step 5 for that crew member.
- **5a. The crew member's inventory is full:**
    - 5a1. The system tells them their inventory is full, and the item stays on the ground.
    - 5a2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Occasional.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| dropped item position | Vector2 | Relative to the ship deck or the island | Owned by the Host's instance | Item |

Failure behavior: This use case makes durable changes to where items are. The Host moves each item as one step so it can't be duplicated or lost.

**Related Use Cases:** `UC-SYS-player-inventory`, `UC-ISLE-collect-island-items`

**Assumptions:** Items dropped on the deck move with the ship. Items are picked up automatically by walking over them.

**Open Issues:**

- What happens to an item dropped while overboard?

---

## Area: Map Interaction & Discovery (`MAP`)

### UC-MAP-open-map: View the map

**UC ID and Name:** `UC-MAP-open-map`: View the map

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member claims the Map station.

**Description:** A crew member uses the ship's map station to see where the ship is, which islands have been discovered, how far it is to Paradise Island, and any pins the crew has placed.

**Preconditions:**

- PRE-1. The crew member has claimed the Map station (`UC-DECK-claim-station`).

**Postconditions:**

- POST-1. The crew member has seen the current state of the map.

**Main Success Scenario:**

1. The system opens the map view for the crew member.
2. The system shows the revealed areas, the ship's current location, the discovered islands, the distance to Paradise Island (`UC-PROG-track-progress`), and all pins with their distances (`UC-MAP-pin-distance`).
3. The crew member views the map.
4. The crew member leaves the station (`UC-DECK-use-station`, step 7).
5. The system closes the map view.
6. Use case ends.

**Extensions:**

- **2a. No areas have been revealed yet (start of voyage):**
    - 2a1. The system shows only the ship's location and the distance to Paradise Island.
    - 2a2. Flow rejoins the main scenario at step 3.
- **3a. The crew member selects a discovered island:**
    - 3a1. Flow continues in `UC-MAP-view-island-info`.
    - 3a2. Flow rejoins the main scenario at step 3.
- **3b. The crew member places or removes a pin:**
    - 3b1. Flow continues in `UC-MAP-place-pin`.
    - 3b2. Flow rejoins the main scenario at step 3.

**Priority:** High

**Frequency of Use:** Frequent.

**Business Rules:** `BR-single-station-occupant`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| revealed tiles | Set of tile IDs | Tiles the ship has visited | Shared by the whole crew | Map |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-DECK-use-station`, `UC-MAP-discover-map`, `UC-MAP-view-island-info`, `UC-MAP-place-pin`, `UC-MAP-pin-distance`, `UC-PROG-track-progress`

**Assumptions:** The map is a station on the deck, not a menu. The whole crew shares one map and its discoveries.

**Open Issues:**

- Is the map a station, or a menu anyone can open anytime? (Unconfirmed.)
- If it's a station, can only one crew member use it at a time?

---

### UC-MAP-view-island-info: View a discovered island's info

**UC ID and Name:** `UC-MAP-view-island-info`: View a discovered island's info

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member selects a discovered island on the map.

**Description:** A crew member checks a discovered island's stats on the map to decide whether it's worth sailing to. The map shows islands, not the items on them.

**Preconditions:**

- PRE-1. The crew member is viewing the map (`UC-MAP-open-map`).
- PRE-2. At least one island has been discovered.

**Postconditions:**

- POST-1. The crew member has seen the selected island's stats.

**Main Success Scenario:**

1. The crew member selects a discovered island on the map.
2. The system shows that island's stats ([TBD] which stats).
3. The crew member closes the island info.
4. Use case ends.

**Extensions:**

- **1a. The crew member selects an undiscovered area:**
    - 1a1. The system shows nothing.
    - 1a2. Use case ends.

**Priority:** Medium

**Frequency of Use:** Occasional.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| island stats | [TBD] | TBD | N/A | Island |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-MAP-open-map`, `UC-MAP-discover-map`

**Assumptions:** Item locations are never shown on the map.

**Open Issues:**

- What stats does an island show (e.g. visited or not, shipwreck count, merchant present, challenge completed)?

---

### UC-MAP-discover-map: Reveal the map as the ship explores

**UC ID and Name:** `UC-MAP-discover-map`: Reveal the map as the ship explores

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (affected)

**Trigger:** The ship enters a tile (`UC-SYS-track-boat`).

**Description:** The map starts hidden and fills in with each place the ship visits, so the crew builds up their chart as they sail.

**Preconditions:**

- PRE-1. A voyage is in progress.

**Postconditions:**

- POST-1. Every tile the ship has visited is revealed on the map for all crew members.
- POST-2. Any island in a revealed tile is marked as discovered.

**Main Success Scenario:**

1. The system is notified that the ship has entered a tile.
2. The system reveals that tile on the map.
3. The system marks any island in that tile as discovered.
4. The system syncs the revealed tiles and discovered islands to all clients.
5. Use case ends.

**Extensions:**

- **2a. The tile is already revealed:**
    - 2a1. The system makes no change.
    - 2a2. Use case ends.
- **4a. The ship is reset by a capsize:**
    - 4a1. [TBD] The system keeps the revealed map, or resets it.
    - 4a2. Use case ends.

**Priority:** High

**Frequency of Use:** Continuous while sailing.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| revealed tiles | Set of tile IDs | Only tiles visited this voyage | Owned by the Host's instance | Map |
| discovered islands | Set of island IDs | Islands in revealed tiles | Owned by the Host's instance | Island |

Failure behavior: Map state lasts for the voyage only and is never saved. Clients that desync get the Host's map on the next sync.

**Related Use Cases:** `UC-SYS-track-boat`, `UC-MAP-open-map`, `UC-MAP-view-island-info`

**Assumptions:** Only visited tiles are revealed; there's no reveal radius around the ship and no lookout bonus.

**Open Issues:**

- Does a capsize keep the revealed map, or reset it?

---

### UC-MAP-place-pin: Pin a marker to the map

**UC ID and Name:** `UC-MAP-place-pin`: Pin a marker to the map

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member selects a spot on the map to pin.

**Description:** A crew member places a marker on the map to plan a route or remember a spot. The whole crew sees the pin and its distance.

**Preconditions:**

- PRE-1. The crew member is viewing the map (`UC-MAP-open-map`).

**Postconditions:**

- POST-1. The pin appears on the map for all crew members.

**Main Success Scenario:**

1. The crew member selects a location on the map.
2. The crew member chooses to place a pin.
3. The system places the pin and syncs it to all clients.
4. The system starts showing the distance from the ship to the pin (`UC-MAP-pin-distance`).
5. Use case ends.

**Extensions:**

- **2a. The crew member selects an existing pin and removes it:**
    - 2a1. The system removes the pin for all clients.
    - 2a2. Use case ends.
- **3a. The pin limit has been reached:**
    - 3a1. [TBD] The system blocks the new pin, or removes the oldest one.
    - 3a2. Use case ends.

**Priority:** Low

**Frequency of Use:** Occasional.

**Business Rules:** `BR-pin-limit`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| pin position | Vector2 (map) | Within map bounds | Shared by the whole crew | Pin |
| pin limit | Integer | TBD | N/A | Pin |

Failure behavior: Pins last for the voyage only.

**Related Use Cases:** `UC-MAP-open-map`, `UC-MAP-pin-distance`

**Assumptions:** Any crew member can place or remove any pin, and pins can be placed on unrevealed areas.

**Open Issues:**

- Is there a pin limit?
- Can anyone remove anyone's pin?

---

### UC-MAP-pin-distance: Show distance to map pins

**UC ID and Name:** `UC-MAP-pin-distance`: Show distance to map pins

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** System

**Secondary Actors:** Crew Member (views distance)

**Trigger:** A pin exists and the ship's position changes.

**Description:** The system shows how far the ship is from each pin, in meters, so the crew can tell how close they are to where they're heading.

**Preconditions:**

- PRE-1. At least one pin is on the map.

**Postconditions:**

- POST-1. Each pin shows the current distance from the ship in meters.

**Main Success Scenario:**

1. The system detects that the ship's position has changed.
2. The system calculates the distance from the ship to each pin in map pixels.
3. The system converts the pixel distance to meters.
4. The system updates each pin's distance label on the map.
5. Use case ends.

**Extensions:**

- **2a. The ship reaches a pin's location:**
    - 2a1. The system shows the distance as 0 m ([TBD] or removes the pin automatically).
    - 2a2. Flow rejoins the main scenario at step 4.

**Priority:** Low

**Frequency of Use:** Continuous while pins exist.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| pin distance | Float (meters) | ≥ 0 | N/A | Pin |
| pixels-to-meters scale | Float | TBD | N/A | Map |

Failure behavior: This use case makes no durable change.

**Related Use Cases:** `UC-MAP-place-pin`, `UC-MAP-open-map`, `UC-SYS-track-boat`

**Assumptions:** Distance is straight-line from the ship to the pin.

**Open Issues:**

- What is the pixels-to-meters scale?

---

## Area: Island Interaction (`ISLE`)

### UC-ISLE-arrive-at-island: Travel between the ship and an island

**UC ID and Name:** `UC-ISLE-arrive-at-island`: Travel between the ship and an island

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member interacts with the rowboat, or jumps off the plank, while the ship is near an island.

**Description:** Crew members get ashore fastest by taking the rowboat to the island's dock, or more slowly by jumping off the plank and swimming. They come back the same ways.

**Preconditions:**

- PRE-1. The ship is within range of an island.
- PRE-2. The crew member is not passed out.

**Postconditions:**

- POST-1. The crew member is either on the island or back on the ship's deck, and all clients agree.

**Main Success Scenario:**

1. The crew member interacts with the rowboat on the ship.
2. The system seats the crew member in the rowboat.
3. The system moves the rowboat to the island's dock.
4. The system places the crew member on the dock.
5. When ready to return, the crew member interacts with the rowboat at the dock.
6. The system moves the rowboat back to the ship.
7. The system places the crew member on the deck.
8. Use case ends.

**Extensions:**

- **1a. The crew member jumps off the plank instead:**
    - 1a1. The system puts the crew member in the water (overboard state).
    - 1a2. The crew member swims to the island at swimming speed, which is slower than the rowboat.
    - 1a3. The system places the crew member on the island's shore.
    - 1a4. Flow rejoins the main scenario at step 5.
- **1b. The rowboat is not at the ship (it's docked at the island):**
    - 1b1. The system tells the crew member the rowboat is away.
    - 1b2. The crew member swims instead (1a) or waits.
    - 1b3. Use case ends, or flow continues at 1a.
- **3a. The ship capsizes while crew members are ashore or in the rowboat:**
    - 3a1. The system applies the capsize reset to all crew members (`UC-WAVE-capsize-ship`).
    - 3a2. Use case ends.
- **5a. The crew member swims back instead:**
    - 5a1. The crew member swims to the ship's ladder.
    - 5a2. The system places them on the deck (see `UC-DECK-move-on-deck`, 2b).
    - 5a3. Use case ends.
- **5b. The ship has moved out of range while the crew member was ashore:**
    - 5b1. [TBD] The system blocks the return trip until the ship comes back in range.
    - 5b2. Use case ends.

**Priority:** High

**Frequency of Use:** Frequent. Every island visit.

**Business Rules:** `BR-rowboat-capacity`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| island range | Float (distance) | TBD | N/A | Island |
| rowboat location | Enum | At ship or at a dock | Owned by the Host's instance | Rowboat |
| rowboat capacity | Integer | TBD | N/A | Rowboat |
| swim speed | Float | Slower than the rowboat; TBD | N/A | Crew Member |

Failure behavior: This use case makes no durable change beyond crew and rowboat positions, which are session state owned by the Host.

**Related Use Cases:** `UC-DECK-move-on-deck`, `UC-WAVE-capsize-ship`, `UC-ISLE-collect-island-items`, `UC-ISLE-salvage-shipwreck`, `UC-EVT-trade-with-merchant`

**Assumptions:** There's one rowboat. The ship stays where it is while crew members are ashore unless someone sails it away.

**Open Issues:**

- How many crew members fit in the rowboat?
- Does the rowboat move on its own, or does someone row it?
- Does the ship need to be stopped (sail lowered) to launch the rowboat?

---

### UC-ISLE-complete-challenge: Complete an island challenge

**UC ID and Name:** `UC-ISLE-complete-challenge`: Complete an island challenge

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** Other Crew Members (if the challenge is co-op)

**Trigger:** A crew member starts an island's challenge.

**Description:** Some islands have a challenge the crew can complete for a reward. The challenge types have not been designed yet; this use case defines the shared flow any challenge will follow.

**Preconditions:**

- PRE-1. The crew member is on an island with a challenge.
- PRE-2. The challenge has not been completed this voyage.

**Postconditions:**

- POST-1. The challenge is marked complete, and its reward has been given.

**Main Success Scenario:**

1. The crew member starts the island's challenge.
2. The system runs the challenge ([TBD] by challenge type).
3. The crew member completes the challenge.
4. The system gives the reward ([TBD]).
5. The system marks the challenge complete and syncs this to all clients.
6. Use case ends.

**Extensions:**

- **1a. The challenge is already complete:**
    - 1a1. The system tells the crew member it's done.
    - 1a2. Use case ends.
- **3a. The crew member fails the challenge:**
    - 3a1. [TBD] The system lets them retry, or locks the challenge.
    - 3a2. Use case ends.

**Priority:** Low

**Frequency of Use:** Occasional.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| challenge types | List | Empty for now; to be designed | N/A | Challenge |
| challenge reward | [TBD] | TBD | Granted only by the Host's instance | Challenge |
| completed flag | Boolean | Per challenge, per voyage | N/A | Challenge |

Failure behavior: [TBD] Depends on the reward. Any reward must be granted at the same time the challenge is marked complete.

**Related Use Cases:** `UC-ISLE-arrive-at-island`, `UC-MAP-view-island-info`

**Assumptions:** none yet

**Open Issues:**

- What are the challenge types?
- What are the rewards?
- Can a failed challenge be retried?

---

### UC-ISLE-collect-island-items: Collect island items

**UC ID and Name:** `UC-ISLE-collect-island-items`: Collect island items

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member interacts with a resource on an island, such as a fruit tree or wood.

**Description:** Crew members gather fruit and wood on islands. Fruit keeps them fed, and wood is needed to repair the ship.

**Preconditions:**

- PRE-1. The crew member is on an island.
- PRE-2. The crew member is within interaction range of a resource that still has items.

**Postconditions:**

- POST-1. The gathered item is in the crew member's inventory, or on the ground if their inventory is full.
- POST-2. The resource's remaining amount has decreased.

**Main Success Scenario:**

1. The crew member interacts with a resource.
2. The system drops one item from the resource (`UC-SYS-item-drop`).
3. The crew member walks over the item.
4. The system adds the item to the crew member's inventory.
5. The system decreases the resource's remaining amount.
6. Use case ends.

**Extensions:**

- **1a. The resource has been used up:**
    - 1a1. The system shows it as empty.
    - 1a2. Use case ends.
- **4a. The crew member's inventory is full:**
    - 4a1. The item stays on the ground.
    - 4a2. Flow rejoins the main scenario at step 5.

**Priority:** High

**Frequency of Use:** Frequent. Every island visit.

**Business Rules:** none

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| resource type | Enum | Fruit tree, wood; more may be added | N/A | Resource |
| resource amount | Integer | ≥ 0; set when the island is generated; TBD | Owned by the Host's instance | Resource |

Failure behavior: Handled by `UC-SYS-item-drop`, which moves each item fully or not at all.

**Related Use Cases:** `UC-SYS-item-drop`, `UC-SYS-player-inventory`, `UC-SURV-consume-food`, `UC-SHIP-repair-damage`

**Assumptions:** Interacting drops the item, and walking over it picks it up. Resources don't regrow during a voyage.

**Open Issues:**

- Is the collection method right (interact to drop, walk over to pick up)?
- Do resources regrow?

---

### UC-ISLE-salvage-shipwreck: Salvage a shipwreck

**UC ID and Name:** `UC-ISLE-salvage-shipwreck`: Salvage a shipwreck

**Created By:**

**Date Created:** 2026-09-30

**Primary Actor:** Crew Member

**Secondary Actors:** none

**Trigger:** A crew member interacts with a shipwreck's loot chest on an island.

**Description:** Islands can have zero, one, or several shipwrecks, generated along with the island. Each wreck has a loot chest filled with random items that the crew can take.

**Preconditions:**

- PRE-1. The crew member is on an island with a shipwreck.
- PRE-2. The crew member is within interaction range of the wreck's loot chest.

**Postconditions:**

- POST-1. Every item the crew member took is in their inventory; anything left stays in the chest.
- POST-2. The wreck is marked salvaged once its chest is empty.

**Main Success Scenario:**

1. The crew member interacts with the wreck's loot chest.
2. The system opens the chest (`UC-SYS-shared-inventory`), filling it with random loot on first open.
3. The crew member takes the items they want.
4. The crew member closes the chest.
5. The system marks the wreck as salvaged if the chest is now empty.
6. Use case ends.

**Extensions:**

- **1a. Another crew member already has the chest open:**
    - 1a1. The system tells the crew member the chest is in use.
    - 1a2. Use case ends.
- **3a. The crew member's inventory fills up:**
    - 3a1. The remaining loot stays in the chest for later or for another crew member.
    - 3a2. Flow rejoins the main scenario at step 4.

**Priority:** Medium

**Frequency of Use:** Occasional. On islands that have wrecks.

**Business Rules:** `BR-single-station-occupant`

**Associated Information:**

| Property name | Data type | Validation rule | Security or access concerns | Glossary reference |
|---|---|---|---|---|
| shipwreck count | Integer | ≥ 0; random per island | Generated only by the Host's instance | Island |
| salvaged flag | Boolean | True once the wreck's chest is empty | N/A | Shipwreck |

Failure behavior: Handled by `UC-SYS-shared-inventory`, which applies each item move fully or not at all.

**Related Use Cases:** `UC-SYS-shared-inventory`, `UC-SYS-item-pool`, `UC-ISLE-arrive-at-island`

**Assumptions:** Salvaging is just opening the chest, with no minigame or hold.

**Open Issues:** none

---

_**Checklist for each use case:** Does the name start with a verb? Can the system test every precondition? Does every step alternate actor and system? Is there at least one extension per step that can fail? Does every business rule appear as an identifier only? Could a tester write test cases from this without asking you anything?_
