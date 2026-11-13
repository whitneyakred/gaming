# Fatigue Design

**Status:** Planned single-player design. Requirements are [FTG use cases](../requirements/use-cases.md#area-fatigue-ftg) and [survival/fatigue rules](../requirements/business-rules.md#24-cooking-survival-and-fatigue). This document describes how fatigue will fit the game; no fatigue implementation is claimed.

## Overview

Fatigue presents low hunger and low character health through increasingly tired, dizzy and cluttered feedback. It affects both deck play and cooking. SURV owns hunger/health and food effects; FTG reads committed state and owns fatigue presentation. Do not retain the old steady energy drain, automatic pass-out or 25% recovery as hidden parallel mechanics. Whether a separate energy reserve is useful remains an open decision.

## Components and ownership

| Planned boundary | Responsibility |
|---|---|
| Fatigue evaluator | Derive hunger and health contributions from committed survival state; combine once using a pending capped-severity rule. |
| Fatigue settings | Inspector-configurable thresholds, severity curves and presentation limits; exact tuning pending. |
| Fatigue presentation | Read-only HUD warnings, world/overlay dizziness and clutter; share the same severity across deck and cooking. |
| Warning counter | Optional simulation-time urgency indicator; do not implement until trigger, duration, clearing and expiry are agreed. |
| Rest station | Reusable station entry/leave; no duplicate survival state or hunger/health refill. Its positive recovery benefit remains open. |

All additions are planned, not existing classes. Use typed GDScript, scenes, signals and exported settings; preserve Compatibility renderer and Web compatibility.

## Sequence

### UC-FTG-deplete-fatigue: Evaluate hunger and health fatigue

1. SURV commits hunger/health and signals the change.
2. FTG activates hunger fatigue below 40% and increases it as hunger falls.
3. FTG evaluates low health at the owner's 10% threshold; ≤10% is the proposed exact comparison.
4. Combine contributions once and publish severity/cause information.
5. Above 40% hunger remove its contribution, independently of health. At exactly 40%, proposed prior-state retention needs confirmation.
6. At death, stop gameplay updates; FTG must not request recovery or revive the player.

Above 50% is comfortably healthy, not a second recovery threshold. Combined severity and numerical curves remain TBD.

### UC-FTG-warn-exhaustion: Warn the player to cook or eat

1. Show the low-resource cause with readable text/icon/bar.
2. Apply increasing dizziness/clutter/tiredness on deck and in the square cooking overlay.
3. If agreed later, advance the warning counter only with simulation time.
4. Re-evaluate after eating/healing; clear only resolved causes.

Do not silently subtract accuracy, change recipe outcomes or add movement slowdown. Fatigue affects the cooking experience through its agreed presentation; mechanical modifiers need explicit values/approval. Proposed reduced-motion feedback uses a static urgency display instead of sway.

### UC-FTG-rest: Use the rest station

Claim the station, expose leave, and release on leave/death. The ship continues moving unless anchored. Rest does not refill hunger/health or remove their warnings. Idle/rest hunger costs and any additional rest benefit are still open; do not invent an energy-recovery loop to fill the gap.

## Pause and cooking integration

Gameplay pause freezes survival progression, logical cooking targets, score, recipe countdown and warning counters under the proposed simulation contract. Existing shake/wobble continues visually at frozen severity on a separate presentation clock. Render offsets must never move gameplay coordinates, score inputs, spend supplies or cause damage while paused. Cooking entry/exit and anchoring do not reset effects or counters.

## Acceptance checks

- Hunger 39% activates feedback; 20% is stronger; 41% clears the hunger contribution.
- Healthy hunger with low health retains the health contribution; validate equality once agreed.
- Deck and cooking share severity. Tuning leaves success achievable during fatigue.
- Pause keeps wobble visible without advancing gameplay, stats, scores or counters.
- Rest can start while sailing and cannot erase hunger/health consequences or revive death.
- Game over occurs through SURV; no fatigue-only collapse resets stats.

## Open decisions

Exact 40% equality, inclusive health threshold, combined-severity curve, effects/intensity, optional reduced motion, counter semantics, any movement penalty, separate energy reserve and useful rest benefit. These are implementation blockers for their respective behavior, not permission to guess.
