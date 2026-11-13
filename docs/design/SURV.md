# Survival Design

**Status:** Planned single-player design. [SURV use cases](../requirements/use-cases.md#area-survival-surv) own behavior; [business rules](../requirements/business-rules.md#24-cooking-survival-and-fatigue) own constraints; [Cooking content](../requirements/recipes-and-preparation.md) owns recipe proposals. No integrated survival implementation is claimed.

## Overview

Movement/actions spend hunger, including cooking. Below 40% hunger the character experiences progressive fatigue; low health at the 10% threshold contributes independently through FTG. At zero hunger starvation damages health. Food/recipes restore separate character health and hunger; horrible/poisonous meals damage rather than heal. Zero health ends the voyage in game over. These rules replace the older immediate pass-out/25% recovery model.

Minecraft is the owner's conceptual reference for activity using hunger and eating restoring visible hearts. Holy Ship follows its explicit rules; no exact Minecraft saturation, regeneration or difficulty behavior is imported.

## Current integration gaps

Fishing currently adds catalog loot to player inventory. Coconut pickup counts island challenge progress rather than retained food. Cooking currently uses its own raw-fish/collected-meal counters. Those are not a shared supply loop. Future integration must use owned supplies, retain food and needs across boat/island scene transitions, and give collected meals their defined effects. This design does not rewrite fishing, island, inventory or travel use cases.

## Components and ownership

| Planned boundary | Responsibility |
|---|---|
| Survival state/controller | Sole owner of hunger, character health, alive/dead state and committed notifications. State stays in memory for the voyage. |
| Action-cost settings | Movement/action hunger costs, starvation rate/interval and maximum values. Idle/rest and passive ship travel policies remain open. |
| Food/recipe definitions | Ingredient identity/quantity, compatibility, prepared result, hunger restoration, healing and poisonous harm. |
| Inventory owner adapter | Reserve/spend recipe inputs and remove servings through existing inventory APIs; prevent duplicates and partial effects. |
| Cooking station/activity | Ingredient selection, relevant preparation, 0–3 accuracy stars and ready output; do not write health directly. |
| Death transition | Latch death, disable actions, release stations/overlays, reject late callbacks and show game over once. |
| FTG | Read committed hunger/health and own fatigue effects; no second stat writer. |

Use typed GDScript, Resources/exported settings, reusable scenes and signals with the Compatibility renderer and Web compatibility. Paths/class names are implementation choices; no new code is supplied here.

## Sequence

### UC-COOK-prepare-meal: Experiment with ingredients and prepare a meal

Show owned foods, accept an untried combination, resolve its predetermined compatibility/recipe, and reserve inputs. Run only relevant preparation steps while sailing, fatigue effects and action hunger costs continue. Resolve stars separately from safety; an incompatible meal remains poisonous at three stars. Failed preparation also poisons food, with zero-star interpretation provisional and timeout undecided. Spend inputs once, keep one result ready, and grant the meal once on collection. A full inventory keeps output at the station. Cancellation/refund policy needs agreement.

Initial recipe content uses fish/potato assets without water resources. The prototype's pitcher/pouring stage does not authorize a bucket/water system. See the recipe draft for candidate results.

### UC-SURV-consume-food: Eat food to restore hunger and health

Validate alive/owned food. Remove one serving and apply its defined effects together. A safe meal restores hunger/health up to maximum. Poison overrides healing, causing at least 30% health loss with worse meals causing more; percentage of maximum health is proposed but not confirmed. Re-evaluate starvation/fatigue and invoke death if health reaches zero. Full hunger must not block health restoration. Poison hunger effects and damage timing remain open.

### UC-SURV-deplete-hunger-thirst: Spend hunger and apply starvation damage

Use elapsed movement/activity or completed eligible action costs rather than rendered frames or repeated input events. While hunger is zero, apply starvation at its pending rate/interval. Positive hunger stops starvation; it does not necessarily clear fatigue. Anchor stops sailing, not needs. No automatic pass-out restoration. Thirst is deferred despite the retained historical use-case identifier.

### UC-SURV-die: End the voyage at zero health

Set terminal state once, reject further actions, release station control, close activity overlays, stop ordinary survival simulation and show game over. Delayed meal, recipe or recovery callbacks cannot revive a dead character. Restart/menu choices and same-update healing/damage precedence need definition.

### Deferred SURV cases

UC-SURV-consume-water and UC-SURV-recover-from-illness are deferred from this slice. No water, bottle, barrel, raw-food illness timer or illness fatigue floor is needed. UC-SURV-pass-out is superseded here by starvation damage and terminal health-based death.

## State, pause and consistency

Preserve the same voyage supplies/needs across scene transitions; returning from an island must not reset them. Do not add disk persistence or networking. Consumption and recipe transfers must be all-or-nothing; reserve/spend/release must be idempotent. Failed inventory operations must not grant effects.

Proposed pause contract freezes action costs, starvation/poison progression, recipe and warning timers, ship/station logic and scoring without catch-up. Existing FTG wobble continues visually at frozen intensity. Presentation-only updates cannot mutate survival state.

## Acceptance checks

- Equivalent actions have equivalent hunger costs across frame rates; missing/rejected actions cannot spend twice.
- Zero hunger damages health until positive hunger or death; no automatic 25% restoration.
- Safe meals restore both defined stats with caps; full hunger/low health can still heal.
- Poison damages instead of healing and can kill, including three-star incompatible meals.
- A recipe spends once, output collects once, and inventory capacity cannot erase output.
- Death during cooking/rest triggers one game over and rejects late callbacks.
- Pause keeps stats/timers frozen while wobble animates.
- Planned food/needs handoff survives island return without loss, duplication or free restoration.

## Open decisions

Starvation rate, action/idle/rest costs, passive travel cost, health/hunger starting values, food restoration, exact thresholds/combined fatigue (with FTG), warning counter, poisonous recipe definitions, zero-star wording, timeout, poison denominator/severity/timing/hunger effect, cancellation/refunds, death ordering and game-over controls.
