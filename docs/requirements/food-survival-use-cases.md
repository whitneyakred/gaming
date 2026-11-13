# Connected food and survival

The working use cases now live in [Use Cases](use-cases.md#area-cooking-cook), covering cooking, food consumption, action hunger costs, starvation, death and fatigue. This file is a navigation note rather than a competing requirements draft.

- [Cooking, survival and fatigue rules](business-rules.md#24-cooking-survival-and-fatigue): thresholds, poison, death, sailing and pause behavior.
- [Cooking content](recipes-and-preparation.md): ingredient experimentation, starter recipe proposals and later food candidates.
- [Survival design](../design/SURV.md): state ownership, food/cooking integration and health transitions.
- [Fatigue design](../design/FTG.md): low-resource evaluation, cooking feedback, pause animation and rest questions.

## Existing integration gaps

Fishing grants inventory loot, island coconut pickups count challenge progress, and cooking holds separate fish/meal counters. Those are not yet a connected supply system. Future cooking/survival work needs retained owned ingredients, meal output and hunger/health effects; it must preserve the existing source interactions until their own changes are requested.

The documentation describes planned behavior. No gameplay code, assets, commits or published build are supplied.
