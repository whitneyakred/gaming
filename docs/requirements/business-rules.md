# Business Rules

**Project:** Holy Ship
**Team:** Team 13
**Client:** None — student-led project; product decisions belong to the development team.
**Version:** 0.3

---

_**How to use this template.** Instructions appear in italic square brackets. Fill in underneath them and leave them in place until the document is stable._

_**What a business rule is.** A corporate policy, a government regulation, a law, an industry standard, or a computational formula. Business rules are a rich source of requirements, because they dictate properties your system must have in order to conform to them._

_**What a business rule is not: a software requirement.** This is the distinction students get wrong, so read it twice. A rule is a property of the **business**. It exists whether or not your software does, it was true before you arrived, and it will still be true if the project is cancelled. "A student may only submit a peer evaluation during an active week" is a rule the course had before anyone wrote code._

_What belongs to your software is the **enforcement** of that rule, and that is a functional requirement, written in the specification and cited back here. Keeping the two apart is what lets you answer the question that comes up every semester: "who decided this, and can we change it?" If it is a rule, the client's organization decides and you comply. If it is a requirement, your team decides and you can negotiate._

## How to hear one in a meeting

_[Rules almost never arrive announced. They surface in the middle of a story about something else, usually in one of these shapes:]_

- _"Must comply with..."_
- _"Only `<someone>` may `<do something>`"_
- _"If `<condition>`, then `<something happens>`"_
- _"Must be calculated according to..."_
- _"...unless it has been more than a year."_

_Examples of a client stating a rule without knowing it: "A new client must pay 30 percent of the estimated consulting fee and travel expenses in advance." "Time-off approvals must comply with the company's vacation policy."_

_When you hear one, write it down in the meeting. You will not reconstruct it afterward, and the exact wording matters because the rule is someone else's sentence, not yours._

## The five shapes a rule takes

_[Useful for recognizing rules, not for organizing this document. Sections below are grouped by topic, not by these categories.]_

| Shape | What it does | Example |
|---|---|---|
| **Fact** | States something always true about the business | Every senior design team belongs to exactly one course section. |
| **Constraint** | Restricts what may be done, or by whom | Only a course admin may create a course section. |
| **Action enabler** | Triggers an action when a condition holds | If a student has not completed safety training in 12 months, the request is refused. |
| **Inference** | Derives a new fact from known facts | A team with no submissions for two consecutive weeks is at risk. |
| **Computation** | Defines how a value is calculated | The peer evaluation score is the mean of all scores received that week. |

_Computations are the ones teams forget are rules. A formula the client uses today is a rule you must reproduce exactly, not a design decision you get to make. Ask for the spreadsheet._

## What a rule turns into

_[One rule usually propagates into several requirements of different kinds. This is why the document exists as its own artifact rather than being scattered through the specification.]_

| Requirement type | How the rule shows up | Example |
|---|---|---|
| Business requirement | A regulation drives a business objective | The system must enable compliance with all federal and state chemical reporting regulations within five months. |
| User requirement | A privacy policy dictates who may do what | Only laboratory managers may generate chemical exposure reports for anyone other than themselves. |
| Functional requirement | A company policy becomes system behavior | If an invoice is received from an unregistered vendor, the system shall email the vendor the supplier intake form and the W-9. |
| Quality attribute | A safety regulation becomes a checked property | The system must maintain safety training records and check them before a user can request a hazardous chemical. |

## Identifiers and traceability

_Each rule carries a stable `BR-<slug>` identifier, a name-based slug coined from the rule's gist: `BR-active-weeks`, `BR-section-admin-only`, `BR-artifact-key-unique`. Never renumber, rename, or repoint one. The thematic grouping into sections below is organizational only and does not affect a rule's identity, so moving a rule between sections is free and renaming it is not._

_**Cite rules, do not copy them.** When a use case is governed by a rule, its Business Rules field carries the identifier only, never the rule's text. One rule, one home. A rule copied into three use cases will be updated in one of them._

_A rule may cite another rule by identifier where one depends on another._

## Every rule needs a source

_[The column teams leave blank, and the one that matters most. For each rule, record where it comes from: a named policy document, a regulation, a page of the client's handbook, or the person who told you and the date.]_

_A rule you cannot attribute is usually not a rule. It is your team's design decision wearing a rule's clothes, and it belongs in the specification where it can be argued with. The test: if you asked your client to change it tomorrow, who would have to approve? If the answer is "you", it was never a rule._

_Where a rule is expected to change, say so and say when. Rules change on the business's schedule, not on yours._

## Where your AI teammate helps, and where it is dangerous

_[Delegate: turning your meeting notes into candidate rules, spotting sentences in a transcript that have the shape of a rule, and finding use cases in your specification that a given rule ought to govern but does not cite.]_

_**Do not let it invent rules.** This section is the single most dangerous place in your requirements for fabricated content, because an invented rule reads exactly like a real one. "Passwords must be at least 8 characters." "Records must be retained for 7 years." Both are plausible, both are common, and neither is your client's policy unless your client said so. A fabricated rule then propagates into functional requirements, tests that pass, and code that enforces something nobody asked for._

_The Source column is the defense. Every rule traces to a document or a person, or it does not go in the file. When your agent proposes a rule, the only question is: who told us this?_

## Revision History

| Date | Version | Description | Author |
|---|---|---|---|
| _[YYYY-MM-DD]_ | 0.1 | Initial rules from the client brief and first client meeting | _Shana_ |
| 2026-10-14 | 0.2 | Updated all 23 current rule IDs referenced in Use Cases version 0.2, retained unresolved values, and updated scope | _Shana_ |

---

## 1. Introduction

### 1.1 Purpose

This document defines the gameplay rules referenced by Holy Ship’s use cases. These are team-authored domain rules, not external business or regulatory policies. Existing IDs are retained so references remain stable.

### 1.2 Scope

The current milestone is single-player, confirmed by the project owner on 2026-10-20 and consistent with [AGENTS.md](../../AGENTS.md). The use cases preserve a broader planned sailing/survival game. LAN hosting, client synchronization, joint repair, and multi-crew occupancy are deferred co-op design, not current delivery requirements. For local play, the player controls the session and the local simulation owns state; quitting ends the local voyage. `BR-session-cap-4` applies only to deferred co-op. Station capacities do not imply additional current players.

### 1.3 Sources and Unresolved Decisions

The source for Section 2 is the repository [use cases](use-cases.md), originally version 0.2 dated September 30, 2026, now clarified for milestone scope in version 0.3. These citations establish what the draft says, not independent client approval. Values and policies the draft leaves undecided remain TBD, and approximate values remain provisional. No new rule IDs are created for use cases whose Business Rules field says “none.”

---

## 2. Referenced Gameplay Rules

### 2.1 Deck and Station Access

- **`BR-deck-bounds`:** Crew members cannot cross the deck railing; leaving through the plank puts them overboard, and the ladder beside the plank provides the return route to the deck. **Source:** [Use Cases](use-cases.md), UC-DECK-move-on-deck.

- **`BR-single-station-occupant`:** A station or storage chest may have only one occupant at a time, except that Repair Spots allow multiple crew members and the Hammock allows two; a claim does not displace an existing occupant. **Source:** [Use Cases](use-cases.md), UC-DECK-claim-station; UC-DECK-use-station; UC-SYS-shared-inventory.

- **`BR-station-slots`:** Most stations have one slot, the Hammock has two slots, and a Repair Spot supports up to four crew members repairing together. **Source:** [Use Cases](use-cases.md), UC-DECK-claim-station, Associated Information; UC-FTG-rest; UC-SHIP-repair-damage.

### 2.2 Navigation and Weather

- **`BR-sail-rotation-limit`:** The sail rotates only within a limited arc relative to the ship heading, provisionally about −135° to +135° (270° total), with the exact limits TBD. **Source:** [Use Cases](use-cases.md), UC-NAV-rotate-sail, Description and Associated Information.

- **`BR-wind-change-cooldown`:** Normal random wind changes occur when the wind-change cooldown expires, after which a new cooldown begins; its duration and any storm-specific wind rules are TBD. **Source:** [Use Cases](use-cases.md), UC-NAV-change-wind.

- **`BR-waves-rough-weather-only`:** Waves affect the ship only during rough weather and stop affecting it when rough weather ends. **Source:** [Use Cases](use-cases.md), UC-WAVE-generate-waves.

### 2.3 Capsizing and Ship Repair

- **`BR-capsize-conditions`:** The ship capsizes when stability reaches zero or integrity reaches 0%, with integrity equal to 100% minus 5 percentage points per open leak, so 20 open leaks cause a capsize. **Source:** [Use Cases](use-cases.md), UC-WAVE-balance-ship; UC-WAVE-capsize-ship; UC-SHIP-take-damage.

- **`BR-capsize-reset`:** Capsizing continues the voyage by returning the ship and all crew members to the last visited island (or the starting point if none has been visited), emptying all personal inventories and the deck chest, releasing station claims, restoring full stability and integrity, removing Repair Spots, and lowering the sail. **Source:** [Use Cases](use-cases.md), UC-WAVE-capsize-ship.

- **`BR-damage-interval`:** Leaks appear at timed intervals that are shorter during storms and shorter still when the ship is not diagonal to the waves or the sail is raised; normal and storm interval values are TBD. **Source:** [Use Cases](use-cases.md), UC-SHIP-take-damage; UC-EVT-weather-storm.

- **`BR-repair-cost`:** A completed leak repair consumes a TBD amount of wood from the deck chest once per repair regardless of participant count and restores 5 percentage points of integrity; insufficient wood prevents the repair. **Source:** [Use Cases](use-cases.md), UC-SHIP-repair-damage.

### 2.4 Survival and Fatigue

- **`BR-stat-max`:** Each crew member’s hunger, thirst, and fatigue is bounded between zero and its respective maximum, and food, water, or rest cannot restore a stat beyond that maximum; maximum values are TBD. **Source:** [Use Cases](use-cases.md), UC-SURV-consume-food; UC-SURV-consume-water; UC-FTG-rest, Associated Information.

- **`BR-barrel-fill-rate`:** The shared water barrel collects drinkable water at a steady TBD rate up to its TBD capacity, and bottle refills are limited by available barrel water and the bottle’s TBD capacity. **Source:** [Use Cases](use-cases.md), UC-SURV-consume-water.

- **`BR-stat-depletion-rate`:** Hunger and thirst decrease at their own constant TBD rates during active, unpaused play while a crew member is conscious, and normal fatigue depletion follows the same conditions except that it stops while resting; hunger and thirst continue to decrease during rest. **Source:** [Use Cases](use-cases.md), UC-SURV-deplete-hunger-thirst; UC-FTG-deplete-fatigue; UC-FTG-rest.

- **`BR-pass-out-recovery`:** A crew member whose hunger, thirst, or fatigue reaches zero passes out without permanent death, loses the ability to act and any station claim for a TBD cooldown, and then recovers with all three stats at 25% of their respective maxima. **Source:** [Use Cases](use-cases.md), UC-SURV-pass-out.

- **`BR-illness-fatigue-floor`:** Illness from raw non-fruit food adds fatigue drain only while fatigue is above a provisional floor of about 50% of maximum and the illness timer remains active; normal depletion can continue below that floor, whose exact value or variation is TBD. Whether illness drain resumes after rest raises fatigue above the floor is also TBD (`OI-12`). **Source:** [Use Cases](use-cases.md), UC-SURV-recover-from-illness.

### 2.5 Events and Trading

- **`BR-event-roll-once-per-tile`:** Each map tile receives at most one event roll per voyage and produces at most one event from its event list, with the tile marked as rolled even when no event occurs. **Source:** [Use Cases](use-cases.md), UC-EVT-generate-event.

- **`BR-merchant-pricing`:** Merchant purchases spend the crew’s shared gold at the displayed price only when sufficient gold and inventory space are available, and confirmed sales remove the sold item and add the offered gold; gold cannot be negative, and item prices and sell values are TBD. **Source:** [Use Cases](use-cases.md), UC-EVT-trade-with-merchant; UC-SYS-item-pool, Associated Information.

### 2.6 Session Management

Host permissions and disconnect semantics below describe deferred co-op. In single-player, the local player starts, restarts, pauses, resumes, and quits; the same pause freeze applies to all simulation timers. These rules describe planned session controls, not an implemented pause menu.

- **`BR-host-ends-session`:** The Host quitting or disconnecting ends the session for everyone and discards the unsaved voyage, with no host migration, while another crew member leaving does not end the session. **Source:** [Use Cases](use-cases.md), UC-PROG-quit-voyage; UC-DECK-claim-station, Failure behavior.

- **`BR-host-controls-session`:** Only the Host may start, restart, pause, or resume the voyage, and pausing freezes movement, stat depletion, wind, waves, and all timers for the whole crew until resumed. **Source:** [Use Cases](use-cases.md), UC-PROG-start-voyage; UC-PROG-pause-game.

- **`BR-session-cap-4`:** A session contains one Host and at most three additional crew members, for a maximum of four players including the Host. **Source:** [Use Cases](use-cases.md), UC-PROG-host-join.

### 2.7 Inventory, Map, and Island Travel

The six quick slots and 30-item stacks below are the planned inventory contract. The current prototype instead has four distinct-item spaces and per-item stack limits; see the [inventory implementation guide](../../scripts/inventory-system/Inventory-sys-information.md). Updating documentation does not change those code limits.

- **`BR-inventory-slots`:** Each personal inventory has exactly six quick slots plus a TBD number of expanded slots, with at most 30 matching items per stack and no additional item accepted when every slot and matching stack is full. **Source:** [Use Cases](use-cases.md), UC-SYS-player-inventory.

- **`BR-pin-limit`:** If a shared map-pin limit is adopted, the number of active pins must not exceed it; whether a limit exists, its value, and whether excess placement is blocked or replaces the oldest pin are all TBD. **Source:** [Use Cases](use-cases.md), UC-MAP-place-pin, Extensions and Open Issues.

- **`BR-rowboat-capacity`:** The rowboat may carry no more than its passenger capacity, whose value is TBD. **Source:** [Use Cases](use-cases.md), UC-ISLE-arrive-at-island, Associated Information and Open Issues.

### 2.8 Superseded Reference

`BR-single-helmsman` appears only in the replacement note in UC-DECK-claim-station and is superseded by `BR-single-station-occupant`. It is not a separate active rule; the replacement covers Steering and other stations, including the Repair Spot and Hammock exceptions.

---
