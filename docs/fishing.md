# Mouse fishing

Select the fishing rod (slot 1 on a fresh voyage), then **left-click nearby
water near visible fish**. The bobber attracts one unclaimed fish within 110
world pixels; empty water cannot produce a catch. When it dips and the bite chime plays, **click again** to hook the
fish. Holding left-click raises tension; releasing lowers it. Follow the moving
green zone until the Catch meter fills. Too much or too little tension builds
Line Strain and eventually snaps the line. **Right-click** cancels at any time.

A bite must be hooked within 1.25 seconds. A nearby fish approaches the bobber before biting (minimum wait 1.8–4.5 seconds);
each fish gets a different green-zone width, movement pattern, and 8–11 seconds
of required time in the green. Brief mistakes are recoverable: strain decreases
in the green. A fight ends after 35 seconds if the fish hasn't been landed.
Snapping loses the catch, not the rod. Every landed fish becomes a generic Fish item; rope is never fishing loot.
The old casting/waiting banner is hidden; watch the bobber and listen for the bite.
A full inventory drops the catch at the player's feet without losing it.

The rod works aboard ship and on island shores. Cast range defaults to 40–360
world pixels. Land, deck, and cliffs reject casts. Ship casts follow the boat through movement and turns, so sailing cannot cause
an out-of-reach failure. Retrieval stops outside the hull with clearance for
the bobber and its wobble; island fishing stops at the shoreline.
Fishing holds the player's stance without changing the camera. Switching tools,
opening storage/map/pause, swimming, losing focus, or leaving the scene ends the
attempt. The old E/Space fishing station is no longer instanced on the ship.

Open `scenes/inventory/inventory_system.tscn` and select **Fishing** to change
**Cast Range**, **Minimum Cast Distance**, **Bite Wait**, **Bite Window**, and
**Cast Seconds** in the Inspector. Tension tuning is in
`scripts/fishing/fishing_fight.gd`; the HUD, world visuals, and audio are separate
components under `scripts/fishing`. The six original synthesized effects (cast,
splash, bite, reel, snap, catch) respect **Settings > Audio > Effects**.

Validation:

```
godot --headless --path . res://tests/fishing_test.tscn -- --settings-test
godot --path . res://tests/fishing_test.tscn -- --settings-test --capture
```

Tests cover 30 seeded fish, both failure directions, frame-size consistency,
mouse-to-world casting, water/range rejection, hooking/releasing, cancellation,
rewards, full bags, island land detection, and audio generation. Captures are
`.godot/fishing-cast.png` and `.godot/fishing-reel.png`.

While casting/waiting, only a single outlined status line is shown. The full
tension panel appears after hooking. Clicking during casting or before a bite
cancels the attempt and requires a recast. The green zone spans 20–26% of the
bar, changes targets every 0.8–1.7 seconds, and moves at 0.18 bar widths/second.
