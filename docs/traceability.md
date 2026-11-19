# Traceability Matrix

**Project:** Holy Ship
**Team:** Team 13 (Gaming)
**Version:** 0.2

This matrix links the current requirements without claiming implementation or test completion. The confirmed MVP includes solo and co-op, for December 4, 2026. [Vision section 4.3](requirements/vision-and-scope.md#43-mvp-scope) owns scope, [business rules](requirements/business-rules.md) owns rule text, and [use cases](requirements/use-cases.md) owns behavior.

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

**Release legend.** `v0.1.0` the proving slice (Checkpoint 2); `v0.2.0` Checkpoint 3 (Nov 20); `v1.0.0` the December MVP; `Out` not planned for the MVP (deferred co-op, water, and illness per [vision 4.3](requirements/vision-and-scope.md#43-mvp-scope), or superseded). Later scope is added as new use cases after `v1.0.0`. Rows are placed risk first, then what the client needs first, then dependencies; the pull request that changes a cell says why. No `FR-*` identifiers exist in the specification yet, so every row is a use case.

**Coarse estimates.** Each use case not yet designed carries its four-part coarse estimate from planning poker (2026-11-04) on its own issue ([#45–#91](https://github.com/whitneyakred/gaming/issues?q=is%3Aissue+%22coarse+estimate%22)), collected in [`estimates/coarse-estimates.csv`](estimates/coarse-estimates.csv). Historical totals are not a current forecast; reconcile completion and confirmed co-op using [calibration](estimates/calibration.md).

These links identify design coverage. Proposed designs, unresolved tuning, and deferred flows remain unverified until their code and relevant tests exist. The [prototype guide](minimal-mvp.md) records current code; [sailing validation](sailing-integration.md#validation) covers the existing integration test only.

| Use case | Area design | Release | Build | Verify |
|---|---|---|---|---|
| `UC-DECK-move-on-deck` | [DECK](design/deck.md) | `v0.2.0` | Implementation reference: [code](../scripts/player.gd); flow audit pending | Partial: [candidate tests](../tests/station_camera_suite.gd); camera and shared-grill behavior passed; per-extension review pending |
| `UC-DECK-use-station` | [DECK](design/deck.md) | `v0.2.0` | Implementation reference: [code](../scripts/sailing/ship_station.gd); flow audit pending | Partial: [candidate tests](../tests/station_camera_suite.gd); camera and shared-grill behavior passed; per-extension review pending |
| `UC-DECK-claim-station` | [DECK](design/deck.md) | `v0.2.0` | Implementation reference: [code](../scripts/sailing/ship_station.gd); flow audit pending | Partial: [candidate tests](../tests/station_camera_suite.gd); camera and shared-grill behavior passed; per-extension review pending |
| `UC-NAV-steer-ship` | [NAV](design/NAV.md) | `v0.2.0` | Implementation reference: [code](../scripts/sailing/helm_station.gd); flow audit pending | Partial: [candidate tests](../tests/sailing_integration.gd); 18 current sail/helm/anchor checks passed; full specification extensions pending |
| `UC-NAV-rotate-sail` | [NAV](design/NAV.md) | `v0.2.0` | Implementation reference: [code](../scripts/sailing/sail_station.gd); flow audit pending | Partial: [candidate tests](../tests/sail_rotation.gd); 6 rotation checks passed locally; full station-flow/extension coverage pending |
| `UC-NAV-raise-lower-sail` | [NAV](design/NAV.md) | `v0.2.0` | Implementation reference: [code](../scripts/sailing/sail_station.gd); flow audit pending | Partial: [candidate tests](../tests/sailing_integration.gd); 18 current sail/helm/anchor checks passed; full specification extensions pending |
| `UC-NAV-check-wind` | [NAV](design/NAV.md) | `v0.2.0` | Implementation reference: [code](../scripts/ship.gd); flow audit pending | Partial: [candidate tests](../tests/sailing_integration.gd); 18 current sail/helm/anchor checks passed; full specification extensions pending |
| `UC-NAV-change-wind` | [NAV](design/NAV.md) | `v0.2.0` | Implementation reference: [code](../scripts/ship.gd); flow audit pending | Partial: [candidate tests](../tests/sailing_integration.gd); 18 current sail/helm/anchor checks passed; full specification extensions pending |
| `UC-NAV-use-lookout` | [NAV](design/NAV.md) | `v1.0.0` | Implementation reference: [code](../scripts/inventory/spyglass.gd); flow audit pending | Partial: [candidate tests](../tests/spyglass_test.gd); main-flow/extension mapping pending |
| `UC-WAVE-generate-waves` | [WAVE](design/WAVE.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-WAVE-balance-ship` | [WAVE](design/WAVE.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-WAVE-capsize-ship` | [WAVE](design/WAVE.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-COOK-prepare-meal` | [SURV cooking integration](design/SURV.md), [Cooking content](requirements/recipes-and-preparation.md) | `v1.0.0` | Implementation reference: [code](../scripts/galley_cooking.gd); flow audit pending | Partial: [candidate tests](../tests/grill_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-SURV-consume-food` | [SURV](design/SURV.md) | `v1.0.0` | Implementation reference: [code](../scripts/survival/survival_world.gd); flow audit pending | Partial: [candidate tests](../tests/survival_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-SURV-die` | [SURV](design/SURV.md) | `v1.0.0` | Implementation reference: [code](../scripts/survival/survival_world.gd); flow audit pending | Partial: [candidate tests](../tests/survival_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-SURV-consume-water` | [SURV](design/SURV.md) | `Out` | Deferred/superseded | Not claimed |
| `UC-SURV-deplete-hunger-thirst` | [SURV](design/SURV.md) | `v1.0.0` | Implementation reference: [code](../scripts/survival/survival_world.gd); flow audit pending | Partial: [candidate tests](../tests/survival_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-SURV-pass-out` | [SURV](design/SURV.md) | `Out` | Deferred/superseded | Not claimed |
| `UC-SURV-recover-from-illness` | [SURV](design/SURV.md) | `Out` | Deferred/superseded | Not claimed |
| `UC-FTG-rest` | [FTG](design/FTG.md) | `v1.0.0` | Implementation reference: [code](../scripts/survival/survival_world.gd); flow audit pending | Partial: [candidate tests](../tests/survival_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-FTG-deplete-fatigue` | [FTG](design/FTG.md) | `v1.0.0` | Implementation reference: [code](../scripts/survival/survival_world.gd); flow audit pending | Partial: [candidate tests](../tests/survival_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-FTG-warn-exhaustion` | [FTG](design/FTG.md) | `v1.0.0` | Implementation reference: [code](../scripts/survival/survival_world.gd); flow audit pending | Partial: [candidate tests](../tests/survival_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-SHIP-take-damage` | [SHIP](design/ship.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-SHIP-repair-damage` | [SHIP](design/ship.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-EVT-generate-event` | [EVT](design/EVT.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-EVT-trade-with-merchant` | [EVT](design/EVT.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-EVT-weather-storm` | [EVT](design/EVT.md) | `v1.0.0` | Not established; team scope decision needed | Not verified; no mapped executable test |
| `UC-PROG-track-progress` | [PROG](design/PROG.md) | `v1.0.0` | Implementation reference: [code](../scripts/islands/paradise_journey.gd); flow audit pending | Partial: [candidate tests](../tests/paradise_journey_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-PROG-reach-paradise` | [PROG](design/PROG.md) | `v1.0.0` | Implementation reference: [code](../scripts/islands/paradise_journey.gd); flow audit pending | Partial: [candidate tests](../tests/paradise_journey_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-PROG-quit-voyage` | [PROG](design/PROG.md) | `v1.0.0` | Implementation reference: [code](../scripts/network/network_session.gd); flow audit pending | Partial: [candidate tests](../tests/menu_flow_suite.gd); 62 checks passed after stale selector fix; extension coverage pending |
| `UC-PROG-start-voyage` | [PROG](design/PROG.md) | `v1.0.0` | Implementation reference: [code](../scripts/network/network_session.gd); flow audit pending | Partial: [candidate tests](../tests/menu_flow_suite.gd); 62 checks passed after stale selector fix; extension coverage pending |
| `UC-PROG-host-join` | [PROG](design/PROG.md) | `v1.0.0` | Implementation reference: [code](../scripts/network/network_session.gd); flow audit pending | Partial: [candidate tests](../tests/network_smoke_suite.gd); 55 checks passed across three local clients; deployed relay and full extensions pending |
| `UC-PROG-pause-game` | [PROG](design/PROG.md) | `v0.1.0` | Implementation reference: [code](../scripts/pause_menu.gd); flow audit pending | Partial: [candidate tests](../tests/pause_game_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-PROG-choose-character` | [PROG](design/PROG.md) | `v1.0.0` | Implementation reference: [code](../scripts/network/network_session.gd); flow audit pending | Partial: [candidate tests](../tests/menu_flow_suite.gd); 62 checks passed after stale selector fix; extension coverage pending |
| `UC-SYS-item-pool` | [SYS](design/SYS.md) | `v1.0.0` | Implementation reference: [code](../scripts/item-system/item_database.gd); flow audit pending | Partial: [candidate tests](../tests/item_system_test.gd); main-flow/extension mapping pending |
| `UC-SYS-player-inventory` | [SYS](design/SYS.md) | `v1.0.0` | Implementation reference: [code](../scripts/inventory-system/player_inventory.gd); flow audit pending | Partial: [candidate tests](../tests/inventory_test.gd); main-flow/extension mapping pending |
| `UC-SYS-track-boat` | [SYS](design/SYS.md) | `v1.0.0` | Implementation reference: [code](../scripts/voyage_state.gd); flow audit pending | Partial: [candidate tests](../tests/voyage_inventory_test.gd); main-flow/extension mapping pending |
| `UC-SYS-shared-inventory` | [SYS](design/SYS.md) | `v1.0.0` | Implementation reference: [code](../scripts/inventory/ship_inventory.gd); flow audit pending | Partial: [candidate tests](../tests/chest_multiplayer_suite.gd); main-flow/extension mapping pending |
| `UC-SYS-item-drop` | [SYS](design/SYS.md) | `v1.0.0` | Implementation reference: [code](../scripts/inventory/inventory_service.gd); flow audit pending | Partial: [candidate tests](../tests/paradise_journey_suite.gd); suite passed locally; per-extension specification coverage pending |
| `UC-MAP-open-map` | [MAP](design/MAP.md) | `v1.0.0` | Implementation reference: [code](../scripts/map_system/map_ui.gd); flow audit pending | Not verified; no mapped executable test |
| `UC-MAP-view-island-info` | [MAP](design/MAP.md) | `v1.0.0` | Implementation reference: [code](../scripts/map_system/map_ui.gd); flow audit pending | Not verified; no mapped executable test |
| `UC-MAP-discover-map` | [MAP](design/MAP.md) | `v1.0.0` | Implementation reference: [code](../scripts/map_system/map_ui.gd); flow audit pending | Not verified; no mapped executable test |
| `UC-MAP-place-pin` | [MAP](design/MAP.md) | `v1.0.0` | Implementation reference: [code](../scripts/map_system/map_ui.gd); flow audit pending | Not verified; no mapped executable test |
| `UC-MAP-pin-distance` | [MAP](design/MAP.md) | `v1.0.0` | Implementation reference: [code](../scripts/map_system/map_ui.gd); flow audit pending | Not verified; no mapped executable test |
| `UC-ISLE-arrive-at-island` | [ISLE](design/isle.md) | `v1.0.0` | Implementation reference: [code](../scripts/islands/island_game.gd); flow audit pending | Partial: [candidate tests](../tests/island_minigames_suite.gd); full minigame suite passed after test repairs; per-extension specification mapping pending |
| `UC-ISLE-complete-challenge` | [ISLE](design/isle.md) | `v1.0.0` | Implementation reference: [code](../scripts/islands/island_game.gd); flow audit pending | Partial: [candidate tests](../tests/island_minigames_suite.gd); full minigame suite passed after test repairs; per-extension specification mapping pending |
| `UC-ISLE-collect-island-items` | [ISLE](design/isle.md) | `v1.0.0` | Implementation reference: [code](../scripts/islands/island_game.gd); flow audit pending | Partial: [candidate tests](../tests/island_minigames_suite.gd); full minigame suite passed after test repairs; per-extension specification mapping pending |
| `UC-ISLE-salvage-shipwreck` | [ISLE](design/isle.md) | `v1.0.0` | Implementation reference: [code](../scripts/islands/island_game.gd); flow audit pending | Partial: [candidate tests](../tests/island_minigames_suite.gd); full minigame suite passed after test repairs; per-extension specification mapping pending |

## Verification interpretation

Implementation references identify the relevant subsystem, not a claim that every specified flow is built. Candidate tests exist but need per-flow review before Verified. Release cells preserve the previous plan except confirmed co-op inclusion; the team must revise unfinished MVP scope against capacity. The pause suite is locally passing; full co-op pause semantics are not established by that solo test. `node tools/check-traceability.mjs` checks local paths and heading links, not external URLs or behavioral completeness.

| Requirement | Design | Code | Test | Release |
|---|---|---|---|---|
| `ROB-HARBOR-unavailable` | [Reliability](reliability.md) | [Handler](../online-service/src/index.ts) | [Failure test](../online-service/test/degradation.test.mjs) | v0.2.0 |
| `PER-HARBOR-discovery` (initial checkpoint target) | [SLI and limits](reliability.md) | [Probe](../tools/measure-harbor.mjs) | [Recorded sample](evidence/harbor-slo.json) | v0.2.0 |

Local test outcomes and known failures: [validation record](evidence/validation.md).
