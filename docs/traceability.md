# Traceability Matrix

**Project:** Holy Ship
**Team:** Team 13 (Gaming)
**Version:** 0.2

This matrix links the current requirements without claiming implementation or test completion. The current milestone is single-player; co-op flows are deferred. [Vision section 4.3](requirements/vision-and-scope.md#43-mvp-scope) owns scope, [business rules](requirements/business-rules.md) owns rule text, and [use cases](requirements/use-cases.md) owns behavior.

## 1. Feature to use case area

The vision's two proposed objectives are `BO-independent-play` and `BO-player-engagement`. The source does not assign an approved objective to each feature, so per-feature objective attribution remains TBD rather than fabricated. Historical/open ideas explicitly have no current behavioral coverage.

| Feature | Use case areas or explicit gap |
|---|---|
| `FEAT-deck-movement` | DECK |
| `FEAT-single-player-survival` | SURV, FTG |
| `FEAT-ship-stations` | DECK, NAV, FTG |
| `FEAT-sailing-control` | NAV |
| `FEAT-ocean-travel` | SYS, MAP, NAV |
| `FEAT-food-water-management` | SURV, SYS, ISLE |
| `FEAT-island-exploration` | ISLE, MAP |
| `FEAT-stamina-movement` | Historical idea; no separate stamina requirement |
| `FEAT-ship-repair` | SHIP |
| `FEAT-floating-chests` | Open idea; no dedicated active use case |
| `FEAT-voyage-progress` | PROG, MAP |
| `FEAT-cooperative-play` | PROG (deferred co-op) |
| `FEAT-session-setup` | PROG |
| `FEAT-trading-encounters` | EVT, SYS |
| `FEAT-ocean-encounters` | EVT, WAVE, SYS |
| `FEAT-npc-assistance` | Open idea; no active use case |
| `FEAT-overboard-rescue` | Open idea; DECK overboard movement is not a rescue system |
| `FEAT-role-attributes` | Open idea; no active use case |

All 18 defined features are represented; all 11 current use-case areas are reached. Open ideas are gaps to decide, not missing cases to invent.

## 2. Business rule to citing use cases

These are requirement-level citations, not evidence that code enforces a rule. Source provenance is the repository use-case draft originally dated 2026-09-30 (v0.2); its current scope clarification is v0.3. Each row lists the exact Business Rules field references.

| Business rule | Source | Cited by |
|---|---|---|
| `BR-deck-bounds` | [Use cases](requirements/use-cases.md) | `UC-DECK-move-on-deck` |
| `BR-single-station-occupant` | [Use cases](requirements/use-cases.md) | `UC-DECK-use-station`, `UC-DECK-claim-station`, `UC-NAV-steer-ship`, `UC-NAV-rotate-sail`, `UC-NAV-raise-lower-sail`, `UC-NAV-use-lookout`, `UC-WAVE-balance-ship`, `UC-SYS-shared-inventory`, `UC-MAP-open-map`, `UC-ISLE-salvage-shipwreck` |
| `BR-station-slots` | [Use cases](requirements/use-cases.md) | `UC-DECK-use-station`, `UC-DECK-claim-station`, `UC-FTG-rest`, `UC-SHIP-repair-damage` |
| `BR-sail-rotation-limit` | [Use cases](requirements/use-cases.md) | `UC-NAV-rotate-sail` |
| `BR-wind-change-cooldown` | [Use cases](requirements/use-cases.md) | `UC-NAV-change-wind` |
| `BR-waves-rough-weather-only` | [Use cases](requirements/use-cases.md) | `UC-WAVE-generate-waves` |
| `BR-capsize-conditions` | [Use cases](requirements/use-cases.md) | `UC-WAVE-balance-ship`, `UC-WAVE-capsize-ship`, `UC-SHIP-take-damage`, `UC-EVT-weather-storm` |
| `BR-capsize-reset` | [Use cases](requirements/use-cases.md) | `UC-WAVE-capsize-ship` |
| `BR-damage-interval` | [Use cases](requirements/use-cases.md) | `UC-SHIP-take-damage`, `UC-EVT-weather-storm` |
| `BR-repair-cost` | [Use cases](requirements/use-cases.md) | `UC-SHIP-repair-damage` |
| `BR-stat-max` | [Use cases](requirements/use-cases.md) | `UC-SURV-consume-food`, `UC-SURV-consume-water`, `UC-FTG-rest` |
| `BR-barrel-fill-rate` | [Use cases](requirements/use-cases.md) | `UC-SURV-consume-water` |
| `BR-stat-depletion-rate` | [Use cases](requirements/use-cases.md) | `UC-SURV-deplete-hunger-thirst`, `UC-FTG-deplete-fatigue` |
| `BR-pass-out-recovery` | [Use cases](requirements/use-cases.md) | `UC-SURV-pass-out` |
| `BR-illness-fatigue-floor` | [Use cases](requirements/use-cases.md) | `UC-SURV-recover-from-illness` |
| `BR-event-roll-once-per-tile` | [Use cases](requirements/use-cases.md) | `UC-EVT-generate-event` |
| `BR-merchant-pricing` | [Use cases](requirements/use-cases.md) | `UC-EVT-trade-with-merchant` |
| `BR-host-ends-session` | [Use cases](requirements/use-cases.md) | `UC-PROG-quit-voyage` |
| `BR-host-controls-session` | [Use cases](requirements/use-cases.md) | `UC-PROG-start-voyage`, `UC-PROG-pause-game` |
| `BR-session-cap-4` | [Use cases](requirements/use-cases.md) | `UC-PROG-host-join` |
| `BR-inventory-slots` | [Use cases](requirements/use-cases.md) | `UC-SYS-player-inventory` |
| `BR-pin-limit` | [Use cases](requirements/use-cases.md) | `UC-MAP-place-pin` |
| `BR-rowboat-capacity` | [Use cases](requirements/use-cases.md) | `UC-ISLE-arrive-at-island` |

All 23 active rules have use-case citations. `BR-single-helmsman` is a superseded reference, not a 24th active rule. Candidate IDs in the historical interview and instructional templates are not active project definitions.

## 3. Use cases to area designs

These links identify design coverage. Proposed designs, unresolved tuning, and deferred flows remain unverified until their code and relevant tests exist. The [prototype guide](minimal-mvp.md) records current code; [sailing validation](sailing-integration.md#validation) covers the existing integration test only.

| Use case | Area design |
|---|---|
| `UC-DECK-move-on-deck` | [DECK](design/deck.md) |
| `UC-DECK-use-station` | [DECK](design/deck.md) |
| `UC-DECK-claim-station` | [DECK](design/deck.md) |
| `UC-NAV-steer-ship` | [NAV](design/NAV.md) |
| `UC-NAV-rotate-sail` | [NAV](design/NAV.md) |
| `UC-NAV-raise-lower-sail` | [NAV](design/NAV.md) |
| `UC-NAV-check-wind` | [NAV](design/NAV.md) |
| `UC-NAV-change-wind` | [NAV](design/NAV.md) |
| `UC-NAV-use-lookout` | [NAV](design/NAV.md) |
| `UC-WAVE-generate-waves` | [WAVE](design/WAVE.md) |
| `UC-WAVE-balance-ship` | [WAVE](design/WAVE.md) |
| `UC-WAVE-capsize-ship` | [WAVE](design/WAVE.md) |
| `UC-SURV-consume-food` | [SURV](design/SURV.md) |
| `UC-SURV-consume-water` | [SURV](design/SURV.md) |
| `UC-SURV-deplete-hunger-thirst` | [SURV](design/SURV.md) |
| `UC-SURV-pass-out` | [SURV](design/SURV.md) |
| `UC-SURV-recover-from-illness` | [SURV](design/SURV.md) |
| `UC-FTG-rest` | [FTG](design/FTG.md) |
| `UC-FTG-deplete-fatigue` | [FTG](design/FTG.md) |
| `UC-FTG-warn-exhaustion` | [FTG](design/FTG.md) |
| `UC-SHIP-take-damage` | [SHIP](design/ship.md) |
| `UC-SHIP-repair-damage` | [SHIP](design/ship.md) |
| `UC-EVT-generate-event` | [EVT](design/EVT.md) |
| `UC-EVT-trade-with-merchant` | [EVT](design/EVT.md) |
| `UC-EVT-weather-storm` | [EVT](design/EVT.md) |
| `UC-PROG-track-progress` | [PROG](design/PROG.md) |
| `UC-PROG-reach-paradise` | [PROG](design/PROG.md) |
| `UC-PROG-quit-voyage` | [PROG](design/PROG.md) |
| `UC-PROG-start-voyage` | [PROG](design/PROG.md) |
| `UC-PROG-host-join` | [PROG](design/PROG.md) |
| `UC-PROG-pause-game` | [PROG](design/PROG.md) |
| `UC-PROG-choose-character` | [PROG](design/PROG.md) |
| `UC-SYS-item-pool` | [SYS](design/SYS.md) |
| `UC-SYS-player-inventory` | [SYS](design/SYS.md) |
| `UC-SYS-track-boat` | [SYS](design/SYS.md) |
| `UC-SYS-shared-inventory` | [SYS](design/SYS.md) |
| `UC-SYS-item-drop` | [SYS](design/SYS.md) |
| `UC-MAP-open-map` | [MAP](design/MAP.md) |
| `UC-MAP-view-island-info` | [MAP](design/MAP.md) |
| `UC-MAP-discover-map` | [MAP](design/MAP.md) |
| `UC-MAP-place-pin` | [MAP](design/MAP.md) |
| `UC-MAP-pin-distance` | [MAP](design/MAP.md) |
| `UC-ISLE-arrive-at-island` | [ISLE](design/isle.md) |
| `UC-ISLE-complete-challenge` | [ISLE](design/isle.md) |
| `UC-ISLE-collect-island-items` | [ISLE](design/isle.md) |
| `UC-ISLE-salvage-shipwreck` | [ISLE](design/isle.md) |
