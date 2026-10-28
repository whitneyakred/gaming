# Cooking content

**Status:** Planned behavior with recipe/content proposals. [UC-COOK-prepare-meal](use-cases.md#uc-cook-prepare-meal-experiment-with-ingredients-and-prepare-a-meal) owns the use-case flow. [Cooking, survival and fatigue rules](business-rules.md#24-cooking-survival-and-fatigue) own requirements. Specific recipes and numerical values below remain proposals until selected.

## Recipe selection and results

Players select owned ingredients and can try combinations without already knowing their recipe. Results are predetermined, rather than random. Ingredient compatibility and preparation stars are separate: a horrible combination can be poisonous at three stars; failed preparation can poison an otherwise compatible recipe.

Proposed matching contract: allow up to three food units, ignore selection order, resolve explicit incompatible/specific compatible recipes before category/fallback recipes, and use deterministic precedence. Unknown does not automatically mean poisonous: a safe mixed fallback may apply only when no incompatible rule matches. Never allow non-food rope/tool items into a recipe. Discovery history for the current voyage is proposed, with no unlock levels or progression tree.

## Initial asset-based recipe proposals

The inspected cooking assets include fish, potato, knife and jug SVGs. Fish/coconut exist in the catalog; potato is visible in cooking but still needs catalog/source integration. Start with fish/potato rather than requiring new ingredient art. No water cost, bucket or water gathering is part of these recipes. The existing pouring/boiling stage will need a later recipe-specific redesign; this documentation does not change the activity.

| Proposed dish | Inputs | Preparation steps | Intended result |
|---|---|---|---|
| Grilled cod | 1 cod | Cut, transfer, heat | Hunger and modest healing; exact amounts TBD |
| Roasted potato | 1 potato | Slice, transfer, heat | Hunger-focused with some healing; amounts TBD |
| Fish and potato skillet | 1 cod + 1 potato | Both cuts, transfer, heat | More substantial meal; balance TBD |
| Horrible dish | Explicit incompatible combination, still to select | Relevant ingredient steps | Poisonous even at three stars |
| Botched dish | Compatible ingredients with failed preparation | Attempted recipe steps | Poisonous; zero-star interpretation provisional, timeout TBD |

No specific fish/potato combination is declared inherently poisonous just to fill the table. Horrible combinations must be intentionally selected as game rules and communicated through results/discovery. One inventory unit is not one sliced piece; exact batch quantities/output need agreement.

## Poison and preparation quality

The current scale is 0–3 stars. The owner's “under 0 stars” is provisionally interpreted as zero stars, not a new negative score. Confirm it before implementation. A three-star poisonous result keeps its high preparation score while remaining harmful because of its ingredients.

Poison damages health instead of healing by 30% or more, increasing with the meal's badness. Percentage of maximum health is proposed; immediate versus timed damage and hunger restoration are open. Candidate tiers of 30/40/50 percentage points can be reviewed, but only the 30%-or-more direction is agreed. Safe-meal benefits, quality bonuses and poison labeling also require selection. Poison can end the voyage at zero health.

## Reusable ingredient activities

Reuse the square overlay and existing cuts, transfer and heat steps. Build activity sequences from the chosen ingredients instead of forcing fish cutting into every dish. Coconut shake/open/flesh separation is a proposed later variant; it must eventually grant a food result rather than only challenge score. No bespoke full minigame is needed for every recipe. The current 90-second timer is the prototype reference, not an agreed limit for every future dish.

Fatigue, dizziness and clutter stay active inside these activities. The ship continues sailing unless anchored; movement/actions including cooking spend hunger. Opening cooking cannot reset needs or warnings. Proposed pause behavior freezes logical activity, scoring, supplies and countdown while existing wobble animates at frozen severity. No hidden accuracy deduction is implied.

## Later ingredient candidates

These are themed food ideas, not committed additions or an instruction to expand the inventory.

| Source | Candidates | Reusable preparation |
|---|---|---|
| Fishing | Mackerel, sardines, tuna, squid | Shared fish cutting/transfer/heat |
| Island shores | Crab, shrimp, clams, mussels | Shell-opening/cleaning, heat |
| Island trees | Coconut, banana, mango, papaya, breadfruit | Open, peel, cut or roast |
| Island patches | Sweet potato, pumpkin, carrot, onion | Shared slice/transfer/heat |
| Flavor plants | Lime, ginger, chili, herbs | Small ingredient-prep variations |

Coconut-fish skillet, fruit bowls and roasted roots are possible later results. Each needs a source, item identity, recipe rule and hunger/healing values before inclusion. No nutrition simulation, buffs, water loop, progression or large crafting system is required.

## Open decisions

Choose starter dishes/quantities, incompatible combinations, fallback precedence, restoration values, star/timeout failure policy, poison damage denominator/timing/hunger effect, cancellation/refunds, result labeling and discovery retention. Keep numerical tuning centralized in recipe/settings data when implementation is requested.
