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
| `FEAT-food-water-management` | COOK, SURV (food/health active; water deferred), SYS, ISLE |
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
| `BR-stat-max` | [Use cases](requirements/use-cases.md) | `UC-SURV-consume-food`, `UC-SURV-deplete-hunger-thirst` |
| `BR-barrel-fill-rate` | Deferred | `UC-SURV-consume-water` |
| `BR-stat-depletion-rate` | [Use cases](requirements/use-cases.md) | `UC-SURV-deplete-hunger-thirst`, `UC-FTG-deplete-fatigue` |
| `BR-pass-out-recovery` | Retired for current survival slice | `UC-SURV-pass-out` (superseded by `UC-SURV-die`) |
| `BR-illness-fatigue-floor` | Deferred | `UC-SURV-recover-from-illness` |
| `BR-recipe-result` | [Use cases](requirements/use-cases.md) | `UC-COOK-prepare-meal` |
| `BR-poisonous-failed-food` | [Use cases](requirements/use-cases.md) | `UC-COOK-prepare-meal`, `UC-SURV-consume-food` |
| `BR-character-health-death` | [Use cases](requirements/use-cases.md) | `UC-SURV-die`, `UC-SURV-consume-food` |
| `BR-health-loss-sources` | [Use cases](requirements/use-cases.md) | `UC-SURV-deplete-hunger-thirst`, `UC-SURV-consume-food` |
| `BR-starvation-health-loss` | [Use cases](requirements/use-cases.md) | `UC-SURV-deplete-hunger-thirst` |
| `BR-hunger-fatigue-threshold` | [Use cases](requirements/use-cases.md) | `UC-FTG-deplete-fatigue`, `UC-SURV-consume-food` |
| `BR-fatigue-in-cooking` | [Use cases](requirements/use-cases.md) | `UC-COOK-prepare-meal`, `UC-FTG-warn-exhaustion` |
| `BR-solo-station-sailing` | [Use cases](requirements/use-cases.md) | `UC-COOK-prepare-meal`, `UC-FTG-rest` |
| `BR-pause-fatigue-presentation` | [Use cases](requirements/use-cases.md) | `UC-COOK-prepare-meal`, `UC-FTG-warn-exhaustion`, `UC-SURV-deplete-hunger-thirst` |
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

**Release legend.** `v0.1.0` the proving slice (Checkpoint 2); `v0.2.0` Checkpoint 3 (Nov 20); `v1.0.0` the December MVP; `Spring` COSC 40993; `Out` not planned. Rows are placed risk first, then what the client needs first, then dependencies; the pull request that changes a cell says why. No `FR-*` identifiers exist in the specification yet, so every row is a use case.

These links identify design coverage. Proposed designs, unresolved tuning, and deferred flows remain unverified until their code and relevant tests exist. The [prototype guide](minimal-mvp.md) records current code; [sailing validation](sailing-integration.md#validation) covers the existing integration test only.

| Use case | Area design | Release |
|---|---|---|
| `UC-DECK-move-on-deck` | [DECK](design/deck.md) | `v0.2.0` |
| `UC-DECK-use-station` | [DECK](design/deck.md) | `v0.2.0` |
| `UC-DECK-claim-station` | [DECK](design/deck.md) | `v0.2.0` |
| `UC-NAV-steer-ship` | [NAV](design/NAV.md) | `v0.2.0` |
| `UC-NAV-rotate-sail` | [NAV](design/NAV.md) | `v0.2.0` |
| `UC-NAV-raise-lower-sail` | [NAV](design/NAV.md) | `v0.2.0` |
| `UC-NAV-check-wind` | [NAV](design/NAV.md) | `v0.2.0` |
| `UC-NAV-change-wind` | [NAV](design/NAV.md) | `v0.2.0` |
| `UC-NAV-use-lookout` | [NAV](design/NAV.md) | `Spring` |
| `UC-WAVE-generate-waves` | [WAVE](design/WAVE.md) | `Spring` |
| `UC-WAVE-balance-ship` | [WAVE](design/WAVE.md) | `Spring` |
| `UC-WAVE-capsize-ship` | [WAVE](design/WAVE.md) | `Spring` |
| `UC-COOK-prepare-meal` | [SURV cooking integration](design/SURV.md), [Cooking content](requirements/recipes-and-preparation.md) | `v1.0.0` |
| `UC-SURV-consume-food` | [SURV](design/SURV.md) | `v1.0.0` |
| `UC-SURV-die` | [SURV](design/SURV.md) | `v1.0.0` |
| `UC-SURV-consume-water` | [SURV](design/SURV.md) | `Spring` |
| `UC-SURV-deplete-hunger-thirst` | [SURV](design/SURV.md) | `v1.0.0` |
| `UC-SURV-pass-out` | [SURV](design/SURV.md) | `Out` |
| `UC-SURV-recover-from-illness` | [SURV](design/SURV.md) | `Spring` |
| `UC-FTG-rest` | [FTG](design/FTG.md) | `Spring` |
| `UC-FTG-deplete-fatigue` | [FTG](design/FTG.md) | `v1.0.0` |
| `UC-FTG-warn-exhaustion` | [FTG](design/FTG.md) | `v1.0.0` |
| `UC-SHIP-take-damage` | [SHIP](design/ship.md) | `Spring` |
| `UC-SHIP-repair-damage` | [SHIP](design/ship.md) | `Spring` |
| `UC-EVT-generate-event` | [EVT](design/EVT.md) | `Spring` |
| `UC-EVT-trade-with-merchant` | [EVT](design/EVT.md) | `Spring` |
| `UC-EVT-weather-storm` | [EVT](design/EVT.md) | `Spring` |
| `UC-PROG-track-progress` | [PROG](design/PROG.md) | `Spring` |
| `UC-PROG-reach-paradise` | [PROG](design/PROG.md) | `Spring` |
| `UC-PROG-quit-voyage` | [PROG](design/PROG.md) | `v1.0.0` |
| `UC-PROG-start-voyage` | [PROG](design/PROG.md) | `v1.0.0` |
| `UC-PROG-host-join` | [PROG](design/PROG.md) | `Spring` |
| `UC-PROG-pause-game` | [PROG](design/PROG.md). Build: ✅ Built, single-player slice ([pause_menu.gd](../scripts/pause_menu.gd)). Verify: 🟡 Partial, [pause_game_suite.gd](../tests/pause_game_suite.gd) covers the main flow (pause by P; resume by button and by P) and repeated calls; 1a and 4b deferred co-op, 4a deferred until quit-voyage (OI-21). | `v0.1.0` |
| `UC-PROG-choose-character` | [PROG](design/PROG.md) | `Spring` |
| `UC-SYS-item-pool` | [SYS](design/SYS.md) | `v1.0.0` |
| `UC-SYS-player-inventory` | [SYS](design/SYS.md) | `v1.0.0` |
| `UC-SYS-track-boat` | [SYS](design/SYS.md) | `Spring` |
| `UC-SYS-shared-inventory` | [SYS](design/SYS.md) | `Spring` |
| `UC-SYS-item-drop` | [SYS](design/SYS.md) | `Spring` |
| `UC-MAP-open-map` | [MAP](design/MAP.md) | `Spring` |
| `UC-MAP-view-island-info` | [MAP](design/MAP.md) | `Spring` |
| `UC-MAP-discover-map` | [MAP](design/MAP.md) | `Spring` |
| `UC-MAP-place-pin` | [MAP](design/MAP.md) | `Spring` |
| `UC-MAP-pin-distance` | [MAP](design/MAP.md) | `Spring` |
| `UC-ISLE-arrive-at-island` | [ISLE](design/isle.md) | `v1.0.0` |
| `UC-ISLE-complete-challenge` | [ISLE](design/isle.md) | `v1.0.0` |
| `UC-ISLE-collect-island-items` | [ISLE](design/isle.md) | `v1.0.0` |
| `UC-ISLE-salvage-shipwreck` | [ISLE](design/isle.md) | `Spring` |
