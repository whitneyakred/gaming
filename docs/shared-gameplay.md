# Shared gameplay update — protocol 20

## Backups and cooking provenance

- `backup/systems-revamp-before-gameplay` preserves `systems-revamp` at `bcbd998`.
- `backup/furnace-cooking-before-minigame` preserves the furnace/fuel system plus
  protocol 18 networking at `2c77de2`.
- The teammate's `scripts/galley_cooking.gd` and `scenes/galley_cooking.tscn` on
  `main` / `origin/main` (`87b9ab5`) were the original integration source. The activity and four SVG ingredients/tools
  were subsequently refreshed from `origin/cooking-visuals-survival` (`d4a89b7`),
  also present on `dev-testing`. The newer no-water recipe flow, cutting feedback,
  illustrated board/pot and result visuals are retained. Its standalone
  `VoyageSurvival` references are adapted to this game's multiplayer player state;
  the host-owned one-fish escrow/reward contract remains unchanged.
- One caught fish starts an exclusive preparation attempt. The host consumes it
  into escrow, validates owner, attempt token, elapsed time and bounded rating,
  then awards at most one cooked fish. Local pointer movement is never streamed.
  Cancellation, closing, walking away and disconnect refund unfinished escrow.
  A saved unfinished attempt becomes recoverable stock. Old furnace food/fuel
  can be recovered through the galley menu. A zero-star served meal burns the fish.
- Cooking skill scoring is still client-side, as in the teammate prototype. The
  host guards inventory and duplicate results; it does not replay the slice/drag
  trace. This is not an anti-cheat guarantee for untrusted public matchmaking.

## Fishing actual world fish

World fish use seed + cell + member index + shared host clock. World rendering now
uses those deterministic poses directly; menu fish keep their cosmetic smoothing.
Client-specific escape offsets no longer shift catchable world fish independently.
There is no position stream for all ocean fish.

The host searches at most four times per second while waiting, within 110 world
pixels of the bobber. Only visible, water-valid, unclaimed school members qualify.
A claimed fish retains its original length, heading and animation phase. It turns
and swims at 45 pixels/second, stops with its nose beside the bobber, then triggers the existing bite and
local 60 Hz tension minigame. Its identity/species/attraction position travel with
the angler's existing state; observers see that fish instead of an ambient copy.
Two anglers cannot claim one member. A successful catch consumes its claim and
hides that member for 90 seconds. Cancellation releases it along a three-second return to its original school route;
returns farther than 600 pixels may reset immediately. At most 32 return records
are retained, sent only with shared-state changes. No nearby fish means
no reward; an empty cast times out after 25 seconds. Fishing never awards rope.

School rendering remains a bounded 5x5 recycled window / one MultiMesh; remote
angler searches use a separate cache capped at 45 cells. Harvest history is capped
at 256 entries, with expiry cleanup on searches. It is session state, not a
permanent depletion save. Harvest/marker changes use the existing reliable shared
revision channel, not repeated full data in every motion packet.

## Map, damage and sharks

- M or Tab toggles the map. Closed-map markers are plain circles on a layer above
  the health/hunger HUD.
- Click/tap the map to set your one destination. C clears your destination.
  No extra pin tool. Up to four crew destinations use distinct colors; positions
  are validated and ownership comes from the sender. Departed crew markers clear.
  Local marker drawing is immediate; a pending edit survives older snapshots.
- Closed-map world/edge markers show distance from the local sailor. The map has
  the single Paradise quest sentence and circle-to-key icon legend.
- Damage flash uses each sailor's existing replicated hurt serial, so observers
  see it too. This adds no damage effect RPC or per-frame color synchronization.
- Each new swim gets a random 4–8 second shark activation delay. Sharks approach
  from 1,500 pixels away, circle briefly, track the first portion of a faster lunge, and
  retreat briefly between attacks. They linger for 3.5 seconds after losing a
  swimmer before departing. Shore/deck remain protected by navigation/eligibility.
  Reentering while your sharks linger resumes pursuit without another spawn delay.
  Maximum shark count remains eight. These difficulty settings need human tuning.

## Validation / next playtest

Automated checks cover actual-fish ownership/depletion, no fabricated rewards,
legacy cooking recovery, ingredient escrow and duplicate results, map ownership,
shark timing and damage, deterministic schools, existing movement smoothing, and
host/two-guest cooking/fishing over the fallback relay. The existing fishing
minigame regression now uses a real visible school. Native render captures verify
map legend, galley menu and teammate activity. Browser host/join and forced
WebRTC-to-relay fallback exercise the actual exported game.

Playtest on separate networks: approach visible fish, try two anglers on one
school, observe the hooked fish from the host, complete/cancel cooking, set one
marker per player, then swim long enough to observe arrival, damage flashes and
post-boarding lingering. Refresh every device to protocol 19 before joining.
No TURN, paid service, new dependency or transport change was introduced.

## Playtest polish follow-up

The hooked-fish MultiMesh now receives an identity instance transform (the missing
transform collapsed its geometry), higher opacity and a nose-to-bobber attachment.
The waiting fish remains visible while approaching; reeling draws it at the hook.
Early clicks still cancel an unhooked cast, but no longer show the “Too soon” text.

The preparation menu is titled **Food Preparation Table**. Cooking visuals and
no-water stage progression come from `origin/cooking-visuals-survival` `d4a89b7`
(the same activity is on `dev-testing`), adapted to existing host-owned inventory.
This does not import the other branch's global survival singleton or recipe book.

Hunger loses one pip every 100 seconds idle, 75 walking, or 38 swimming (previously
120/90/45). Chewing uses softer filtered noise; a separate short synthesized burp
plays only on the replicated successful-eat serial, never on a cancelled hold.
No new audio asset, dependency or paid service is required.

## Totem supplies and medical use — November 26

A successful totem attempt spawns two different supply types beside the totem:
coal, string, leather, rope (1–3 each), or one medpack. Temporary minigame loot
never transfers into the voyage bag. Rewards use the existing reliable world-drop
state; each client animates a 0.75-second pop-out using the shared clock, with a
0.8-second pickup grace period. No per-frame reward animation messages are sent.

Success starts a five-minute cooldown shared by the crew and saved as an absolute
expiry. Failing, leaving or disconnecting releases the attempt without cooldown.
The HUD shows the objective and remaining totem energy, with no pirate track or
temporary-loot messages. Completion remains participant-reported; the host owns
reward selection, quantities, reservation tokens, duplicate prevention and cooldown.

Medpacks occupy one slot each. Select one and hold the use button for two seconds:
local bandaging sound/progress begins immediately, then the host validates elapsed
time, selected slot and unchanged inventory before consuming it and healing fully.
Releasing early cancels; full-health players cannot consume one. A replicated heal
serial triggers the completion sound. Eating has a louder, longer voiced burp only
after successful consumption.

Water-entry splashes now use a replicated event serial and position so observers
see them too; initial snapshots do not replay historical splashes. Sanctuary seal
instructions use supported numerals and commas instead of missing arrow glyphs.

Protocol 20 preserves the existing WebRTC/relay transport, prediction and smoothing.
Refresh every device together. Validation includes all 19 totem scenes, cooldown
save/restore, distinct rewards, held-medpack cancellation/consumption, malformed
return records, remote splashes, and three-player relay gameplay. Browser testing
covers direct WebRTC and forced fallback; physical-phone latency still needs a
real playtest.

## Death drops

The host resolves death inventory once. Death on the ship drops each carried stack
in ship-local coordinates so it moves with the deck. Death on an island drops it
at the death position. Drowning within 120 world pixels of a coastline places
stacks just inside that coastline; drowning farther away loses carried supplies.
Being near the ship while swimming never sends loot onto its deck.

Tune **Shore Drop Distance** on the ship's **Survival** node in the Inspector.
Shore lookup runs only on death and validates the landing point against the real
coast polygon, including concave coastlines. Drops use existing reliable shared
state, pickup rules, saving and five-minute ground lifetime; no new transport or
per-frame network work is introduced.

Keys dropped on deck or shore remain recoverable and cannot simultaneously respawn
at their pedestal. A key lost at sea (or later expired on the ground) returns to
its original pedestal with solved seals preserved. Keys in other inventories,
storage or the Paradise gate remain accounted for. Respawning does not create a
second set of drops. Survival tests cover these death locations and key recovery;
the three-player network test verifies guest death loot reaches both observers.
