# Shared gameplay update — protocol 19

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
A claimed fish approaches at 45 pixels/second, then triggers the existing bite and
local 60 Hz tension minigame. Its identity/species/attraction position travel with
the angler's existing state; observers see that fish instead of an ambient copy.
Two anglers cannot claim one member. A successful catch consumes its claim and
hides that member for 90 seconds. Cancellation releases it. No nearby fish means
no reward; an empty cast times out after 25 seconds. Fishing never awards rope.

School rendering remains a bounded 5x5 recycled window / one MultiMesh; remote
angler searches use a separate cache capped at 45 cells. Harvest history is capped
at 256 entries, with expiry cleanup on searches. It is session state, not a
permanent depletion save. Harvest/marker changes use the existing reliable shared
revision channel, not repeated full data in every motion packet.

## Map, damage and sharks

- Click/tap the map to set your one destination. C clears your destination.
  No extra pin tool. Up to four crew destinations use distinct colors; positions
  are validated and ownership comes from the sender. Departed crew markers clear.
  Local marker drawing is immediate; a pending edit survives older snapshots.
- Closed-map world/edge markers show distance from the local sailor. The map has
  the single Paradise quest sentence and circle-to-key icon legend.
- Damage flash uses each sailor's existing replicated hurt serial, so observers
  see it too. This adds no damage effect RPC or per-frame color synchronization.
- Each new swim gets a random 4–8 second shark activation delay. Sharks approach
  from nearby, circle briefly, track the first portion of a faster lunge, and
  retreat briefly between attacks. They linger for 3.5 seconds after losing a
  swimmer before departing. Shore/deck remain protected by navigation/eligibility.
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
