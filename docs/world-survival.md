# Bounded world and survival (protocol 8)

## Rules

The world map spans -12,000 to +12,000 on each axis. Red water begins at
+/-11,000; it continues beyond the displayed chart. Water rendering still recycles
small tiles around the camera instead of allocating an enormous ocean mesh.
Thirty islands reuse the existing art/coastline templates, with randomized
positions and scales (0.75–2.3). The center stays clear for ship respawning.
Unknown islands show identical question marks; nearby islands reveal coastlines.

The host generates one world seed. It is saved with the world and sent in
snapshots so guests generate the same layout, including late joiners. Older saves
without a seed receive a new layout once; a ship overlapping new land or outside
the safe area is moved to the origin. Existing inventories are preserved.

Fishing allows movement, including stepping off the boarding plank. Entering
water cancels fishing. Walking on islands is still allowed while fishing.

A ship continuously in red water for 15 seconds sinks. Returning to safe water
resets its timer. A fading wreck marks its old location; passengers become swimmers
there, while the replacement ship appears anchored at (0,0). Chest, deck drops and
grill food/fuel are lost. Starter fuel is not granted again. Carried items remain
with living swimmers and are lost if that swimmer dies.

A swimmer continuously in red water for 15 seconds dies. Leaving red water or
climbing onto land/deck resets that timer. Death clears carried inventory, cancels
fishing/station interactions and respawns the sailor on the current ship at full
health. No new starter tools are granted on death.

There are exactly two shared sharks. A swimmer becomes eligible after 10 seconds;
sharks select distinct eligible swimmers when possible, each having one target.
A fin arrives from 1,800 units away with a fade-in, circles at roughly 155 units,
then briefly submerges and commits to a dodgeable lunge toward a captured target
position. Each lunge can deal one health point once, within 32 units. It retreats
before circling again. Land and the hull block fins. Leaving water releases the
target and fades the fin away. Sharks are session state, not additional saved NPCs.

Health is 15 points, drawn as five hearts in thirds. Hunger is five fish in thirds,
with a maximum of 15. One hunger point drains every 120 seconds idle, 90 seconds
walking, or 45 seconds swimming. Fractional progress carries between activities.
At zero hunger, one health point is lost every two seconds. At exactly full hunger,
one health point regenerates every 12 seconds; dropping below full resets that timer.
Select raw or cooked fish and left-click while on deck or land to eat. Raw restores
one hunger point, cooked restores three; full hunger does not consume food.
Eating is host-validated against the selected slot, inventory revision and cooldown.
Health, hunger and fractional drain progress are retained with saved crew accounts.
Death restores full health and hunger. Local damage and eating sounds use Effects.
Fins have animated wakes, smoothly interpolated headings and guest positions.

Selected hotbar items use their existing inventory icon as an in-hand sprite.
The fishing rod's active casting visual replaces its held sprite during fishing.
Spyglass opening/closing has short synthesized sounds; camera return follows the
moving original camera rather than its stale last rendered screen position.
The map keeps its ordinary blue chart; only actual dangerous water turns red.
Anchoring near an island no longer displays the large instructional banner.

## Authority and performance

Only the host advances timers, shark targets, bites, death and sinking. Snapshot
fields include world seed, two shark states, ship danger/sink event, and per-player
health/hunger/damage/respawn serials and danger timer. A respawn serial forces local
movement reconciliation to snap to the new spawn rather than smooth through it.
Guest fishing remains locally responsive while results are host validated.

World snapshots remain at the existing 20 Hz rate; shark presentation interpolates
per frame. No extra Cloudflare persistence or request stream was introduced. The
new seed and discovery data use the existing three local host save slots.
Game and harbor must both use holy-ship-coop-8; old clients must reload.

## Files and checks

- scripts/survival/world_layout.gd: bounds, seed layout, island placement.
- scripts/survival/survival_world.gd: host rules, sharks, death and sinking.
- scripts/survival/survival_hud.gd: third-heart/fish display and damage feedback.
- tests/survival.gd: world determinism, water timing, inventory loss and respawns.
- tests/network_smoke.gd: host and two guests, shared seed/sharks/health/death,
  plus existing fishing, inventory and station checks over ENet or WebSocket.

Tuning values are exported on SurvivalWorld and constants in WorldLayout. This
replaces the previous unbounded-map requirement at the user's request. Ship repairs
and new island activities remain separate work.

## Death presentation (protocol 9)
Lethal damage clears inventory immediately and leaves health at zero. Movement,
station use and inventory actions remain blocked until the player clicks Respawn
to boat. The red overlay fades in over 0.45 seconds. Respawn is validated by the
host and restores health/hunger on the current ship. Dead account state survives
reconnection. Sailors counter-rotate against the boat so their art stays upright.


Eating now requires holding left-click for 1.4 seconds per fish. Releasing, switching
slots or opening a menu cancels unfinished eating. Local chomp audio and food crumbs
respond immediately; completed uses still pass host inventory validation. Full hunger
regeneration remains exactly one health point (one third heart) every 12 seconds.

