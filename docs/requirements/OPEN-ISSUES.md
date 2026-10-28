# Open Issues

**Project:** Holy Ship
**Team:** Team 13 (Gaming)

---

_**What this file is.** Every question about the project that you cannot answer yet, in one place, with the name of the person who can answer it. It is the shortest document in `docs/requirements/` and the one your client meetings run on._

_**Why it exists.** A draft specification with confident guesses in the gaps is more dangerous than one with holes in it, because nobody can tell the guesses from the facts. Writing "we do not know" is not an admission of failure in week 3, it is the correct state. What fails is knowing and not writing it down._

_**Where entries come from.** Three places, and all three are routine:_

- _Drafting a section of [vision-and-scope.md](vision-and-scope.md) and hitting something the client brief does not say._
- _Your agent's list. When you ask it to draft a section, ask it to list every question it could not answer from the material you gave it. Its list is longer than yours and it is not embarrassed to ask obvious things._
- _The meeting itself. Your client says something that contradicts your notes, or answers a question with "I would have to check"._

_**How they leave.** Answered in a client meeting, in Slack, or by reading a document. Record the answer and the date, mark it resolved, and put the substance where it belongs (an objective, a term in the [glossary](project-glossary.md), a business rule). This file is a queue, not a home: an answer that stays here has not been filed._

Existing numeric and named `OI-*` identifiers are retained so citations remain stable. New entries use the next unused number; do not rename older named issues.

## Before a client meeting

_[Sort the open list by what it costs you to stay wrong, not by what is easy to ask. You will get through fewer questions than you plan to. Take the ones where a wrong guess sends the whole team down the wrong path for a month, and leave the ones you can settle by reading a document or trying the client's current tool yourself.]_

_[Send the shortlist to your client the day before. A client who has seen the questions arrives with answers instead of promises.]_

## Open

| ID | Question | Why it matters | Who can answer | Raised |
|---|---|---|---|---|
| OI-1 | What are the core mechanics the player should begin with? | Getting this wrong could block the initial gameplay mechanics and feature decisions for the first playable version. | The team itself | 2026-09-13 |
| OI-2 | Which features should be included in the first playable version? | Getting this wrong could block the scope and requirements for the first playable version. | The team itself | 2026-09-13 |
| OI-3 | What should the game's final visual/style direction be? | Getting this wrong could block the game's visual design and style decisions. | The team itself | 2026-09-13 |
| OI-4 | Should character roles or ship stations have greater gameplay impact? | Getting this wrong could block the game's role and ship-station mechanics. | The team itself | 2026-09-13 |
| OI-role-type | Should roles be traditional survival roles or fantasy-like roles? | Getting this wrong could block character role design and gameplay decisions. | The team itself | 2026-09-13 |
| OI-NPC | What tasks and responsibilities should NPCs have in single-player? | Getting this wrong could block the design of NPC assistance and single-player gameplay. | The team itself | 2026-09-13 |
| OI-rescue | How should the raft/rescue mechanic work when a player or NPC falls overboard? | Getting this wrong could block the design of the rescue mechanic and related gameplay features. | The team itself | 2026-09-13 |
| OI-coop | When, if ever, should the retained 1–4-player LAN design enter an approved milestone? | Getting this wrong could block the future co-op scope and requirements. | The team itself | 2026-09-13 |
| OI-users | Who is the target player/audience for the game? | Getting this wrong could block decisions about game design and the intended player experience. | The team itself | 2026-09-13 |
| OI-scale | What world/chunk scale and any NPC capacity should be approved? Current milestone: one player; deferred LAN design cap: four. | Getting this wrong could block decisions about game scope, world size, and player/NPC capacity. | The team itself | 2026-09-13 |
| OI-testing | How will the game be tested with players? | Getting this wrong could block the game's testing and evaluation process. | The team itself | 2026-09-13 |
| OI-maintenance | What happens to the game/project after the course is completed? | Getting this wrong could block decisions about the project's long-term maintenance and ownership. | The team itself | 2026-09-13 |

### SHIP design review questions

Raised while drafting [Ship Damage & Repair](../design/ship.md). These refine the existing scope questions rather than recording approved gameplay changes.

| ID | Question | Why it matters | Who can answer | Raised |
|---|---|---|---|---|
| OI-5 | What are the normal, safe-storm, and unsafe-storm damage intervals and combined penalties, and which WAVE predicate defines diagonal safety? Is preserving elapsed interval fraction on risk changes approved? | Determines leak scheduling and the storm contract without guessed rates. | SHIP, EVT, WAVE, and NAV owners with the team | 2026-10-14 |
| OI-6 | Do collisions cause leaks? What registered wood ID, per-repair cost, and exact solo hold duration within the use case's approximate 3–5 seconds should be used? | Required to implement damage extension 1b and repair without arbitrary rules or substitute materials. | Team, SHIP, NAV, and SYS owners | 2026-10-14 |
| OI-7 | Do SYS, DECK, and WAVE accept the proposed chest-consumption transaction, hold/release hooks, and capsize latch/reset ordering in ship.md? | Prevents partial charges, stuck station claims, and repairs undoing a triggered capsize. | SHIP, SYS, DECK, and WAVE owners | 2026-10-14 |
| OI-8 | What joint-repair speed and partial-departure behavior should apply if co-op is later approved? | Single-player/current and co-op/deferred scope was confirmed on 2026-10-20; only future joint-repair mechanics remain open. | Development team | 2026-10-14 |
| OI-9 | Does damage continue while docked or while the ship scene is unloaded for an island trip? How is damage handed through Voyage State, and is bounded no-mutation retry acceptable when placement is exhausted? | Prevents free repairs on scene changes and unreachable capsize thresholds; validate that the deck supports 20 nonoverlapping repair footprints. | Team, SHIP, ISLE, WAVE, and DECK owners | 2026-10-14 |

### Cross-document decisions

These questions identify unresolved gameplay and integration decisions.

| ID | Question | Why it matters | Who can answer | Raised |
|---|---|---|---|---|
| OI-10 | Which NAV prototype differences should be retained: four sail levels, rudder controls, narrower sail arc, zero drift, direction-only wind display, and speed-dependent turning? | NAV currently records code-first departures from use cases. Decide whether each changes the requirement or needs a code fix; exact tuning remains TBD. | NAV owner and team | 2026-10-20 |
| OI-11 | When should the prototype’s four distinct-item spaces and per-item caps be replaced by six quick slots, expanded slots, and 30-item stacks? | BR-inventory-slots is planned behavior, not current inventory implementation. Wood ID/cost also remain unresolved under OI-6. | SYS owner and team | 2026-10-20 |
| OI-12 | How should hunger/health fatigue combine, and what benefit should rest provide? | Raw-food illness/floor is deferred. Current feedback affects cooking; threshold boundaries, severity and rest model remain open. See [FTG](../design/FTG.md). | SURV/FTG owners with team | — |
| OI-13 | Should future island swimming be supported, and how should general island challenges relate to the prototype’s timed retries? | Current DECK/ISLE designs use rowboat-only island access. Retained swimming flows are deferred alternatives; generic rewards and retry policies remain TBD. | DECK and ISLE owners with team | 2026-10-20 |
| OI-14 | Which communication channel and response windows govern: the signed contract’s Slack/6-hour/3-hour entries or the interview/Discord record? | The team must confirm which communication agreement governs. | Development team | 2026-10-20 |
| OI-15 | Which cross-area contracts govern world-item retention, Voyage State ownership, inventory handoff, and capsize reset ordering? | ISLE scene-local drop loss conflicts with SYS lifetime proposals; existing static scene handoffs are not the proposed shared state component. | SYS, ISLE, WAVE, SHIP, and PROG owners | 2026-10-20 |
| OI-17 | What world-grid origin, tile size, placement, and update cadence satisfy indefinite travel and notify every crossed tile? | SYS/MAP positive-only, fixed-route, and coarse-sampling proposals are not approved world constraints. | SYS, MAP, NAV, EVT, and PROG owners | 2026-10-20 |
| OI-18 | Is map access a station or menu, and is discovery retained or reset after capsize? | The use cases leave both open. Capsize continues the voyage regardless; MAP must not end the session or silently choose retention. | MAP, WAVE, and PROG owners with team | 2026-10-20 |
| OI-21 | What should Quit on the pause screen do before `UC-PROG-quit-voyage` and a main menu exist? | Pause-game 4a hands off to quit-voyage, which isn't built. The single-player pause screen ships with Resume only until then. | PROG owner and team | 2026-10-28 |

### Cooking, survival and fatigue decisions

| ID | Question | Why it matters | Who can answer | Raised |
|---|---|---|---|---|
| OI-19 | Confirm exact 40% boundary and ≤10% health boundary; define combined fatigue/rest, starvation rate, action hunger costs and warning-counter semantics. | Health-loss sources settled for this slice: zero-hunger starvation and horrible recipes. Fatigue below 40% hunger and at low health, death at zero health, action hunger costs and paused visual wobble remain recorded. See [revised cases](food-survival-use-cases.md). | Owner and SURV/FTG team | — |
| OI-20 | Confirm zero-star interpretation of “under 0,” timeout result, incompatible recipes, ≥30% poison denominator/timing/hunger effect, food restoration and cancellation. | First slice uses existing assets without water. Three-star incompatible meals can poison; action hunger costs continue during cooking. See [recipes](recipes-and-preparation.md). | Owner and cooking/ISLE/SYS/SURV team | — |

### Detailed use-case questions

Detailed numeric and behavioral questions remain in each use case's **Open Issues** field; the links below index every non-empty field without duplicating its wording. Area owners and the development team decide them. A field saying “none” does not resolve separate cross-area design questions above.

- [UC-DECK-use-station](use-cases.md#uc-deck-use-station-interact-with-a-station)
- [UC-DECK-claim-station](use-cases.md#uc-deck-claim-station-take-over-or-release-a-station)
- [UC-NAV-steer-ship](use-cases.md#uc-nav-steer-ship-steer-the-ship)
- [UC-NAV-rotate-sail](use-cases.md#uc-nav-rotate-sail-rotate-the-sail)
- [UC-NAV-check-wind](use-cases.md#uc-nav-check-wind-check-wind-direction)
- [UC-NAV-change-wind](use-cases.md#uc-nav-change-wind-change-wind-direction)
- [UC-NAV-use-lookout](use-cases.md#uc-nav-use-lookout-use-the-mast-lookout)
- [UC-WAVE-generate-waves](use-cases.md#uc-wave-generate-waves-generate-ocean-waves)
- [UC-WAVE-balance-ship](use-cases.md#uc-wave-balance-ship-balance-the-ship)
- [UC-WAVE-capsize-ship](use-cases.md#uc-wave-capsize-ship-capsize-the-ship)
- [UC-COOK-prepare-meal](use-cases.md#uc-cook-prepare-meal-experiment-with-ingredients-and-prepare-a-meal)
- [UC-SURV-die](use-cases.md#uc-surv-die-end-the-voyage-at-zero-health)
- [UC-SURV-consume-food](use-cases.md#uc-surv-consume-food-consume-food)
- [UC-SURV-consume-water](use-cases.md#uc-surv-consume-water-consume-water)
- [UC-SURV-deplete-hunger-thirst](use-cases.md#uc-surv-deplete-hunger-thirst-spend-hunger-and-apply-starvation-damage)
- [UC-SURV-pass-out](use-cases.md#uc-surv-pass-out-pass-out-and-recover)
- [UC-SURV-recover-from-illness](use-cases.md#uc-surv-recover-from-illness-recover-from-illness)
- [UC-FTG-rest](use-cases.md#uc-ftg-rest-use-the-rest-station)
- [UC-FTG-warn-exhaustion](use-cases.md#uc-ftg-warn-exhaustion-warn-of-exhaustion)
- [UC-SHIP-take-damage](use-cases.md#uc-ship-take-damage-spring-a-leak-or-take-damage)
- [UC-SHIP-repair-damage](use-cases.md#uc-ship-repair-damage-repair-ship-damage)
- [UC-EVT-generate-event](use-cases.md#uc-evt-generate-event-generate-a-random-ocean-event)
- [UC-EVT-trade-with-merchant](use-cases.md#uc-evt-trade-with-merchant-trade-with-a-traveling-merchant)
- [UC-EVT-weather-storm](use-cases.md#uc-evt-weather-storm-weather-a-storm)
- [UC-PROG-track-progress](use-cases.md#uc-prog-track-progress-track-voyage-progress)
- [UC-PROG-reach-paradise](use-cases.md#uc-prog-reach-paradise-reach-paradise-island)
- [UC-PROG-start-voyage](use-cases.md#uc-prog-start-voyage-start-or-restart-a-voyage)
- [UC-PROG-pause-game](use-cases.md#uc-prog-pause-game-pause-the-game)
- [UC-SYS-player-inventory](use-cases.md#uc-sys-player-inventory-manage-personal-inventory)
- [UC-SYS-track-boat](use-cases.md#uc-sys-track-boat-track-the-boat-across-the-map)
- [UC-SYS-shared-inventory](use-cases.md#uc-sys-shared-inventory-use-a-storage-chest)
- [UC-SYS-item-drop](use-cases.md#uc-sys-item-drop-drop-and-pick-up-items)
- [UC-MAP-open-map](use-cases.md#uc-map-open-map-view-the-map)
- [UC-MAP-view-island-info](use-cases.md#uc-map-view-island-info-view-a-discovered-islands-info)
- [UC-MAP-discover-map](use-cases.md#uc-map-discover-map-reveal-the-map-as-the-ship-explores)
- [UC-MAP-place-pin](use-cases.md#uc-map-place-pin-pin-a-marker-to-the-map)
- [UC-MAP-pin-distance](use-cases.md#uc-map-pin-distance-show-distance-to-map-pins)
- [UC-ISLE-arrive-at-island](use-cases.md#uc-isle-arrive-at-island-travel-between-the-ship-and-an-island)
- [UC-ISLE-complete-challenge](use-cases.md#uc-isle-complete-challenge-complete-an-island-challenge)
- [UC-ISLE-collect-island-items](use-cases.md#uc-isle-collect-island-items-collect-island-items)

## Resolved

| ID | Question | Answer | Answered by | Date | Filed in |
|---|---|---|---|---|---|
| OI-16 | Which scope should the documents describe? | Single-player current milestone; retain co-op as deferred design. | Project owner | 2026-10-20 | Vision 4.3; use-case scope; business-rule applicability; glossary; area scope notes |
