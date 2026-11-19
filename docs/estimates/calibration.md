# Calibration and December 4 forecast

Status: we report approximately 15 future hours per teammate through December 4 (90 gross team hours). The project contact has confirmed the team estimate summary. Coarse team estimates have been recovered below; original individual estimates and WAR source entries remain missing. A proposed 18-hour reserve is a planning assumption, not a team commitment. Blank values mean unknown, never zero. This worksheet includes every matrix use case so finished cases cannot silently disappear. The team must classify completion before calculating ratios.

## Reported areas of responsibility

Source: team retrospective summary supplied through the project contact, November 19, 2026. This is a starting point for collecting records, not a complete contribution ledger, an exclusive ownership assignment, or evidence of equal hours. This summary does not establish separately recorded hours for each person. Cross-cutting work can support several use cases; allocate its hours once rather than repeating the same hours on every row.

| Team member | Reported work areas | Records to collect |
|---|---|---|
| Leiton | Sailing, steering, multiplayer | Relevant NAV and PROG host/join estimates and WAR entries |
| Liliana | Island minigames | ISLE challenge estimates and WAR entries; identify individual minigames |
| Ivan | Inventory and fishing | SYS inventory estimates and WAR entries; identify the requirement covering fishing |
| Gustavo | Cooking station and in-game music | COOK estimates and WAR entries; record audio work separately where cross-cutting |
| Whitney | Island, ship and other art | Asset-task records; identify supported use cases without counting the same art hours repeatedly |
| Shana | Map and map design | MAP estimates and WAR entries |

## Missing-record procedure

1. Recover original estimates from the existing coarse-estimate CSV, issues and planning notes; keep team estimates distinct from individual estimates.
2. Each person supplies their own WAR entries. If those cannot be recovered, record a personally confirmed retrospective range in a separate field labeled **retrospective estimate, not WAR actual** with its date and basis. Do not populate the WAR-actual column with it.
3. Ask the TA whether retrospective estimates can be accepted as supplemental evidence. Until that is confirmed, the required calibration remains incomplete and actual/estimate ratios remain unknown.
4. Collect remaining availability independently of past work. A future-hours forecast can use explicitly labeled assumptions, but cannot be presented as an evidence-based calibration forecast without the required inputs.

We report a retrospective range of approximately 2–3 hours per assigned use case in the work areas above. This is a retrospective team estimate, not a transcription of WAR records. It is recorded as supplemental context only; it is not inserted into the original-estimate or WAR-actual columns, and no equal-contribution claim is made. Exact use-case attribution and treatment of cross-cutting work remain unconfirmed.

## Use-case worksheet

Recovered baseline: the existing issues describe coarse team estimates dated November 4, 2026; these are not individual estimates or actuals. Their meeting provenance has not been independently verified. The CSV was first committed in `50ac406`. Preserve these historical estimates, including superseded release assignments. No coarse baseline was found for pause-game.

For each completed case record one row per person: person, original estimate low/high and date, WAR actual hours since that date, actual / estimate midpoint, evidence reference, biggest miss. The team row uses summed actuals / summed corresponding individual estimate midpoints; keep the existing coarse team estimate separate to avoid double counting. Preserve original estimates; do not rewrite them to match actuals.

| Use case | Coarse team baseline (hours) | Finished? | Person/estimate date | Original individual low–high hours | WAR actual hours / source | Ratio | Biggest miss |
|---|---|---|---|---|---|---|---|
| UC-DECK-move-on-deck | 1.5-3; midpoint 2.25 ([#45](https://github.com/whitneyakred/gaming/issues/45)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-DECK-use-station | 1.5-3; midpoint 2.25 ([#46](https://github.com/whitneyakred/gaming/issues/46)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-DECK-claim-station | 1.5-3; midpoint 2.25 ([#47](https://github.com/whitneyakred/gaming/issues/47)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-NAV-steer-ship | 3-6; midpoint 4.5 ([#48](https://github.com/whitneyakred/gaming/issues/48)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-NAV-rotate-sail | 1.5-3; midpoint 2.25 ([#49](https://github.com/whitneyakred/gaming/issues/49)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-NAV-raise-lower-sail | 1.5-3; midpoint 2.25 ([#50](https://github.com/whitneyakred/gaming/issues/50)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-NAV-check-wind | 3-6; midpoint 4.5 ([#51](https://github.com/whitneyakred/gaming/issues/51)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-NAV-change-wind | 1.5-3; midpoint 2.25 ([#52](https://github.com/whitneyakred/gaming/issues/52)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-NAV-use-lookout | 1.5-3; midpoint 2.25 ([#53](https://github.com/whitneyakred/gaming/issues/53)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-WAVE-generate-waves | 1.5-3; midpoint 2.25 ([#54](https://github.com/whitneyakred/gaming/issues/54)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-WAVE-balance-ship | 3-6; midpoint 4.5 ([#55](https://github.com/whitneyakred/gaming/issues/55)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-WAVE-capsize-ship | 1.5-3; midpoint 2.25 ([#56](https://github.com/whitneyakred/gaming/issues/56)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-COOK-prepare-meal | 3-6; midpoint 4.5 ([#57](https://github.com/whitneyakred/gaming/issues/57)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SURV-consume-food | 1.5-3; midpoint 2.25 ([#58](https://github.com/whitneyakred/gaming/issues/58)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SURV-die | 1.5-3; midpoint 2.25 ([#59](https://github.com/whitneyakred/gaming/issues/59)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SURV-consume-water | 1.5-3; midpoint 2.25 ([#60](https://github.com/whitneyakred/gaming/issues/60)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SURV-deplete-hunger-thirst | 1.5-3; midpoint 2.25 ([#61](https://github.com/whitneyakred/gaming/issues/61)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SURV-pass-out | 1.5-3; midpoint 2.25 ([#62](https://github.com/whitneyakred/gaming/issues/62)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SURV-recover-from-illness | 1.5-3; midpoint 2.25 ([#63](https://github.com/whitneyakred/gaming/issues/63)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-FTG-rest | 1.5-3; midpoint 2.25 ([#64](https://github.com/whitneyakred/gaming/issues/64)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-FTG-deplete-fatigue | 1.5-3; midpoint 2.25 ([#65](https://github.com/whitneyakred/gaming/issues/65)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-FTG-warn-exhaustion | 1.5-3; midpoint 2.25 ([#66](https://github.com/whitneyakred/gaming/issues/66)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SHIP-take-damage | 3-6; midpoint 4.5 ([#67](https://github.com/whitneyakred/gaming/issues/67)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SHIP-repair-damage | 1.5-3; midpoint 2.25 ([#68](https://github.com/whitneyakred/gaming/issues/68)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-EVT-generate-event | 3-6; midpoint 4.5 ([#69](https://github.com/whitneyakred/gaming/issues/69)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-EVT-trade-with-merchant | 1.5-3; midpoint 2.25 ([#70](https://github.com/whitneyakred/gaming/issues/70)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-EVT-weather-storm | 3-6; midpoint 4.5 ([#71](https://github.com/whitneyakred/gaming/issues/71)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-track-progress | 1.5-3; midpoint 2.25 ([#72](https://github.com/whitneyakred/gaming/issues/72)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-reach-paradise | 1.5-3; midpoint 2.25 ([#73](https://github.com/whitneyakred/gaming/issues/73)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-quit-voyage | 1.5-3; midpoint 2.25 ([#74](https://github.com/whitneyakred/gaming/issues/74)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-start-voyage | 1.5-3; midpoint 2.25 ([#75](https://github.com/whitneyakred/gaming/issues/75)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-host-join | 1.5-3; midpoint 2.25 ([#76](https://github.com/whitneyakred/gaming/issues/76)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-pause-game | Not present in coarse CSV | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-PROG-choose-character | 1.5-3; midpoint 2.25 ([#77](https://github.com/whitneyakred/gaming/issues/77)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SYS-item-pool | 3-6; midpoint 4.5 ([#78](https://github.com/whitneyakred/gaming/issues/78)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SYS-player-inventory | 1.5-3; midpoint 2.25 ([#79](https://github.com/whitneyakred/gaming/issues/79)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SYS-track-boat | 1.5-3; midpoint 2.25 ([#80](https://github.com/whitneyakred/gaming/issues/80)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SYS-shared-inventory | 1.5-3; midpoint 2.25 ([#81](https://github.com/whitneyakred/gaming/issues/81)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-SYS-item-drop | 1.5-3; midpoint 2.25 ([#82](https://github.com/whitneyakred/gaming/issues/82)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-MAP-open-map | 1.5-3; midpoint 2.25 ([#83](https://github.com/whitneyakred/gaming/issues/83)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-MAP-view-island-info | 1.5-3; midpoint 2.25 ([#84](https://github.com/whitneyakred/gaming/issues/84)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-MAP-discover-map | 3-6; midpoint 4.5 ([#85](https://github.com/whitneyakred/gaming/issues/85)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-MAP-place-pin | 1.5-3; midpoint 2.25 ([#86](https://github.com/whitneyakred/gaming/issues/86)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-MAP-pin-distance | 1.5-3; midpoint 2.25 ([#87](https://github.com/whitneyakred/gaming/issues/87)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-ISLE-arrive-at-island | 3-6; midpoint 4.5 ([#88](https://github.com/whitneyakred/gaming/issues/88)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-ISLE-complete-challenge | 3-6; midpoint 4.5 ([#89](https://github.com/whitneyakred/gaming/issues/89)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-ISLE-collect-island-items | 1.5-3; midpoint 2.25 ([#90](https://github.com/whitneyakred/gaming/issues/90)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| UC-ISLE-salvage-shipwreck | 1.5-3; midpoint 2.25 ([#91](https://github.com/whitneyakred/gaming/issues/91)) | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |

Add one row per contributing teammate and a team total for each finished case. Cases marked Out or unfinished need classification, not fabricated actuals. Original coarse estimates: [source](coarse-estimates.csv).

**Forecast:** unfinished v1.0.0 midpoint sum **PENDING** × team calibration ratio **PENDING** = forecast work **PENDING h**; gross team capacity through **2026-12-04** **90 h (team-reported)**, less proposed integration/rehearsal reserve **18 h**, leaving **72 h** for remaining work; fits: **NOT YET ESTABLISHED**. If over capacity, agree scope changes with the team/client and update release cells by PR. Co-op inclusion is confirmed; its old Out estimate must be reviewed.

| Team member | Available hours through Dec 4 | Integration/rehearsal reserve | Usable hours |
|---|---|---|---|
| Whitney | Approximately 15 (team-reported) | 3 (planning assumption) | 12 (conditional) |
| Leiton | Approximately 15 (team-reported) | 3 (planning assumption) | 12 (conditional) |
| Ivan | Approximately 15 (team-reported) | 3 (planning assumption) | 12 (conditional) |
| Liliana | Approximately 15 (team-reported) | 3 (planning assumption) | 12 (conditional) |
| Gustavo | Approximately 15 (team-reported) | 3 (planning assumption) | 12 (conditional) |
| Shana | Approximately 15 (team-reported) | 3 (planning assumption) | 12 (conditional) |

Do not multiply 2–3 hours by every teammate and every use case: the report concerns assigned areas, not six people working on every case. For calibration, collect **person + use-case ID + hours**; totals alone cannot produce per-use-case or per-person ratios.

## Uncalibrated planning scenario

The checked-in coarse-estimate CSV currently has 36 v1.0.0 rows totaling **101.25 midpoint hours**. Treating all 36 as unfinished and using a hypothetical multiplier of 1.0 gives 101.25 hours against 90 reported gross available hours, exceeding capacity by **11.25 hours** before reserves. This is a sensitivity example, not the required calibrated forecast: several rows may already be built, completion classifications need review, the real calibration ratio is unknown, and the reserve below is only a planning assumption. Under that all-unfinished scenario, a multiplier above approximately **0.889** would exceed even gross capacity. Do not present this as proof that the MVP fits.

## Capacity forecast for the December 4 demo

**Planning assumption, prepared November 19:** reserve 3 of each person's reported 15 hours for integration, bug fixes and rehearsal. This gives 90 gross hours minus 18 reserved hours = **72 usable hours**. The team can change the reserve; it is not a report of work already performed or individual approval.

Let **R** be the sum of estimate midpoints for confirmed unfinished MVP work, and **k** be summed actual hours divided by summed corresponding estimate midpoints for completed work. The decision rule is **R × k ≤ 72 hours**. Partly completed work needs a separately labeled remaining-work estimate. Include any co-op work still needed: its historical CSV release assignment is Out, while the current approved MVP includes co-op.

| Hypothetical multiplier k | Maximum remaining baseline R that fits |
|---|---|
| 0.75 | 96 h |
| 1.00 | 72 h |
| 1.25 | 57.6 h |
| 1.50 | 48 h |
| 2.00 | 36 h |

These are sensitivity scenarios, not measured calibration ratios. Under the all-36-historical-v1.0-rows-unfinished scenario, R = 101.25 h and k = 1 gives **101.25 h**, exceeding the usable budget by **29.25 h**. This does not establish that the actual demo is over budget: some work already exists and remaining scope has not been classified. Conversely, the successful rehearsal does not establish that every historical v1.0 row is complete.

**Does v1.0.0 fit? Not yet established.** The release is runnable, but a calibrated yes/no needs the unfinished-work list and actuals. Keep the demo focused on the existing solo/co-op voyage; historical wave, fatigue, repair or trading requirements must be explicitly budgeted or deferred by the team. No scope has been silently removed here.

## Minimum information needed to finish calibration

Each teammate supplies one line per finished use case:

`Person | Use-case ID | Original estimate range/date | Actual hours | WAR/source reference (or explicitly retrospective) | Biggest miss`

Also mark each MVP use case complete / partly complete / not started, and state what remains for partly complete cases. The existing 2–3-hour summary does not identify which person's hours belong to which case. If Whitney has collected records elsewhere, transfer or link them here; do not recreate them. Historical actuals are required for the course calibration; the planning scenarios can still be used while collecting them.
