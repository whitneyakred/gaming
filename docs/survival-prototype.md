# Playable cooking and survival prototype

This branch connects the existing cooking visuals to owned ingredients, hunger, separate character health, fatigue and game over. State stays in memory for the current voyage and survives island scene changes. Starting a new voyage resets it; there is no disk save.

## Run and controls

In Godot's Project Manager, click **Import**, select `project.godot`, then click **Import & Edit**. In the editor, press **F5 (Run Project)**. The project keeps the Compatibility renderer. Use Godot for normal playtesting; packaged builds are created only when requested and kept outside this repository.

- **WASD / arrow keys:** Walk. **E:** Use/leave stations; use the existing sail, helm and anchor controls.
- At cooking, press **E**, select up to three fish/potato units, then click **Prepare**. Follow the existing slice, transfer and heat tasks; water is skipped. **Escape** cancels without spending ingredients. A completed batch spends ingredients once; press **E** to collect it.
- **F** or **Meals:** Open owned meals/supplies while outside a station. Click a meal to eat it, or eat an owned coconut. Poisonous meals are explicitly labeled harmful. Incidental rope can be discarded to free a pack slot.
- The slim top HUD uses heart/food icons with numeric values; refill changes ease smoothly and low resources pulse subtly. **Meals [F]** keeps the temporary meal panel available until the inventory UI replaces it.
- **P** or **II:** Freeze gameplay. Existing fatigue wobble continues visually. **M** or the motion button in the pause menu toggles reduced-motion presentation.
- At game over, click **Start new voyage** to reset the session.

## Connected loop

Start with a rod, two cod and three potatoes. Fishing grants real inventory loot. Coconut pickups now grant owned food exactly once and remain counted on challenge retries. Winning the collection island grants up to three potatoes, once per voyage; any ungranted portion remains eligible on a later win. Existing four-type inventory capacity still applies.

Cooking supports fish-only, potato-only, fish/potato and a mixed fallback. The result's 0–3 stars measure preparation separately from ingredient compatibility. The first deliberately horrible game recipe is two cod plus one potato: it remains poisonous even at three stars. This is a fictional galley rule, not a real food-safety claim. Discovered recipe names are recorded for the voyage and announced on completion. Coconut preparation is not a new minigame in this slice; owned coconuts can be eaten directly.

Food output stays ready across scene transitions and moves to an eight-serving meal tray on collection. Meals do not add new inventory item types. This is a small prototype supply interface, not the planned expanded inventory system.

## Build defaults for open tuning

These defaults make the documented loop playable; they are adjustable implementation choices, not new approved requirements.

| Setting | Initial value / behavior |
|---|---|
| Hunger and health | Start at 100 each; capped at 100 |
| Walking cost | 0.30 hunger/second while actually moving |
| Station activity cost | 0.16 hunger/second while participating, including cooking and ingredient selection |
| Ship travel cost | 0.06 hunger/second above 5 pixels/second; can combine with station/walking cost |
| Idle/rest cost | None; no independent fatigue-energy reserve or new rest-recovery mechanic |
| Hunger fatigue | Enter below 40%, clear above 40%; exactly 40% retains prior warning state |
| Health fatigue | Active at or below 10% health |
| Combined fatigue | Stronger active cause; capped progressive severity, no hidden score subtraction or movement slowdown |
| Starvation | At zero hunger, lose 2 health/second until positive hunger or death |
| Zero stars / timeout | Zero-star food is poisonous; timeout yields zero stars if served. Leaving/cancelling spends no ingredients |
| Poison | Immediate 30% maximum-health damage for botched preparation; 40% for the horrible recipe; no healing or hunger restoration |
| Safe grilled cod | +28 hunger, +12 health |
| Safe roasted potato | +24 hunger, +8 health |
| Safe fish/potato skillet | +55 hunger, +25 health |
| Safe mixed fallback | +18 hunger and +5 health per selected food unit |
| Coconut | +16 hunger, +5 health |

The stronger hunger fatigue is, the more the world and cooking overlay sway and the more edge clutter appears. Targets and displayed gestures use the same visual transform, so the score still measures actual input. Pause freezes hunger/health, starvation, cooking logic/countdown, scores, ship/station motion and scene-transition delays, while presentation keeps animating at frozen intensity. No separate urgency/death counter is invented; the HUD shows hunger and starvation warnings.

Health loss comes from starvation and poisonous food. Zero health latches death, releases active station control, closes cooking and pauses gameplay with game over; delayed callbacks cannot restore health. Food can heal at full hunger. Rest cannot substitute for food or healing. Thirst, water supplies, raw-food illness, progression and networking remain outside this build.

## Files and tuning

- `scenes/survival/voyage_survival.tscn`, `scripts/survival/voyage_survival.gd`: single voyage owner. In the **FileSystem** dock, double-click `scenes/survival/voyage_survival.tscn`, select **VoyageSurvival** in the **Scene** dock, then edit **Needs**, **Fatigue** or **Supplies** in the **Inspector**. This autoload scene exposes hunger costs, thresholds, starvation damage, supplies and effect amplitude.
- `scripts/survival/food_recipes.gd`: the small recipe table and meal effects.
- `scripts/survival/survival_hud.gd`: bars, meals, pause/game-over controls and visual fatigue.
- `Cook.gd`, `scripts/galley_cooking.gd`: station participation, ingredient selection and reusable preparation.

## Validation

Run Godot headlessly with `--path . --script res://tests/survival_integration.gd` for threshold, starvation, healing, poison, pause, cancellation, duplicate-input, island retention and death checks. Existing sailing, anchor and wind integration suites cover compatibility with the sailing loop. A rendered preview checks the survival HUD and cooking/pause layout. A Windows pack is a local test artifact, not a published Web build.
