# Local responsiveness and prompt disconnects

Protocol 18 adds host-side remote-player presentation smoothing, bounded relay
snapshot flow, and always-on RTT/negotiation diagnostics. See
[WebRTC follow-up](webrtc-networking.md#protocol-18-follow-up-host-presentation-and-relay-flow-control).

## Movement replay and presentation update — November 26, 2026 / protocol 16

Implemented on `codex/network-smoothing-replay`. This is selective client movement
replay, not deterministic whole-world rollback. No new dependency, transport, or
hosted service is required. The host still owns collisions, items, damage,
traversal completion, and shared gameplay decisions.

- Local movement history now retains input directions. On acknowledgement, the
  guest restores the authoritative position and replays only later inputs using
  the shared movement/collision function with an explicit fixed time step, even
  when a snapshot arrives outside a physics callback. Deck sweeps/sliding use
  that same function in solo, host, guest, and replay. Replay never runs pickup, reward,
  damage, sound, or traversal-transition logic. Each reconciliation is capped at
  60 input frames; longer pending history falls back to a bounded position reset.
- Position correction no longer pushes the collision body over subsequent
  ticks. A presentation node carries a bounded, exponentially decaying offset
  for the sailor and held item. Name labels, swimmer camera, spyglass focus, and
  wakes follow the visual position. State changes clear the visual offset.
- Plank/ladder triggers share the host's eligibility function. A guest can begin
  jump/alignment immediately, but cannot complete a phase or board without the
  host. Older pre-input snapshots cannot erase the preview. A processed-input
  rejection, death, challenge/station change, or expired 1.5-second preview is
  resolved against the next authoritative snapshot, with a 500 ms retry cooldown.
  With no snapshots at all, the animation holds at its endpoint; it does not
  invent an outcome. Rejection counts appear in diagnostics.
- The host defaults to 15 Hz snapshots, configurable from 10–20 via the autoload's
  `snapshot_hz` property. Automated tests can pass `--settings-test --snapshot-hz
  10` (or 15/20). Existing 10 Hz hosts remain compatible. The guest estimates
  cadence from host timestamps and serial differences, targeting a 100 ms buffer
  at stable 15/20 Hz or 150 ms at 10 Hz, growing up to 300 ms with jitter.
- Ship position uses monotone velocity-aware cubic interpolation between known
  endpoints. Tangents are constrained to avoid overshoot. Rotations still use
  shortest-path interpolation. Extrapolation stays disabled: an outage holds
  the latest confirmed pose instead of guessing through shore. Teleports reset
  the buffer rather than constructing a curve across the jump.
- Diagnostics keep 240 half-second samples (about two minutes) plus 600 recent
  snapshot-send/receive events. Samples include replay cost/count, traversal
  rejection, input queue/acknowledgement, FPS, frame peaks, RTT when enabled,
  buffer age/gaps, corrections, and throughput. Events retain snapshot serials
  and host timestamps to correlate exports from both peers. Rejoining starts a
  new recording; disconnect retains the final recording until then.

Press **F6** or **Esc → Export network history** to save JSON. Browsers download
the file; native builds save it in `user://` and print the absolute path to the
log. Recording is bounded and local; no identities, tickets, IP addresses, saves,
or inventory contents are included. Nothing uploads automatically. Keep the
overlay enabled when measuring RTT. Export from both host and guest just after
a hitch; device UTC clocks may differ, so use snapshot serial/host-time pairs
alongside the local timestamps.

Replay uses the currently known collision world; it does not rewind moving ship
geometry or all other players. Corrections can still be necessary around changing
obstacles and state transitions. Increasing snapshot frequency increases traffic
and host serialization work; it cannot remove a long network interruption.
The older implementation notes below describe the November 20 release.

Validation on November 26: smoothing/replay/UI property tests, 82 responsiveness
checks, 47 traversal checks, 33 character-animation checks, 84 fishing checks,
72 survival checks, swimming integration, and pause checks passed. Three-player
ENet passed 65 checks. Three-player impaired relay runs passed 68 checks at each
of 10, 15, and 20 Hz (80–120 ms delay in each direction, 300 ms recurring stalls).
Observed total host packet rates were approximately 11.6, 16.2, and 20.8 packets/s
respectively. These are regression measurements, not a controlled mobile-device
performance benchmark or a guarantee against real cellular interruptions.
The isolated release Web export and two-browser host/join/disconnect smoke also
passed, including an actual F6 diagnostic JSON download. The browser runner uses
SwiftShader software rendering; its FPS must not be used as a hardware benchmark.

The comparison also exposed disconnect ordering issues. HarborPeer now removes
queued RPCs from a departing peer before delivering its disconnect event to
SceneMultiplayer. Native ENet disables unused peer-to-peer server relay features
before connecting: all gameplay already follows the host/guest star topology,
and remote crew presence comes from world snapshots. This avoids unnecessary
peer notifications during simultaneous departures. See Godot's
[server_relay documentation](https://docs.godotengine.org/en/stable/classes/class_scenemultiplayer.html#class-scenemultiplayer-property-server-relay).

## Current implementation — November 20, 2026 / protocol 16

The `better-networking` branch retains the existing WebSocket relay, player-host
authority, solo mode, Compatibility renderer, and non-threaded Web export. No
dependencies or paid services were added. This work does not introduce WebRTC or
a hosted simulation server.

### Movement

Guests still predict walking, sail trim, and helm input immediately. Moving input
is now sent reliably in batches of at most six physics frames (normally 10 batches
per second at 60 Hz), with immediate flushes on changes. Idle players coalesce
neutral frames and refresh every 0.5 seconds. The host validates and queues the
frames, then acknowledges only the exact last input it simulated. It no longer
increments a guest acknowledgement just because the host had another tick.

The input queue holds at most 120 frames. Catch-up uses real elapsed-time credit
capped at 0.5 seconds and consumes at most six frames per host tick. Duplicate,
out-of-order, oversized, malformed, and non-finite input is rejected atomically.
The existing 1.5-second input watchdog remains. Prediction history is bounded at
120 frames, with gradual correction and resets for genuine state transitions.

Remote ship/crew playback starts at 150 ms and adapts up to 300 ms when arrival
jitter increases. Its clock changes gradually; outages hold the last known pose.
It does not predict boat collisions through land. This favors smooth playback
over minimum remote-pose latency on uneven connections.

Guest jump, dunk, surface, ladder alignment, climb, and step-on animations now
advance locally every physics tick within the host-confirmed phase. Snapshot
updates cannot rewind that phase's visual progress. Ship-attached paths recover
their origin using the host transform and follow the rendered moving ship.
Phase completion, collisions, and boarding remain authoritative: during an
outage the guest holds the endpoint, rather than speculatively boarding. The
initial transition still waits for the host. Walking reconciliation history is
cleared during scripted traversal so it does not fight the animation path.

### Local UI

Hotbar selection belongs to the local player after their first selection;
older snapshots cannot switch the highlight or held item back. Initial restored
selection and remote players' held items still come from the host. Scroll bursts
are coalesced to at most one selection send per 100 ms during ordinary input.
A following gameplay command flushes the latest selection first on the same
reliable channel. A mismatched host snapshot schedules a retry, so rate-limited
selection commands do not leave the two peers permanently out of sync.

Closing a chest or grill is immediate, with stale-open snapshots suppressed
until host confirmation (bounded to two seconds). A new interaction clears that
protection. Map/pause menus, cursor movement, tooltips, and hotbar highlights are
local presentation; shared item transfers, chest access, grill contents, rewards,
and station ownership still require host validation. This avoids speculative
inventory edits or duplicate items. Panel opening can still wait for authority.

### Fishing

Guest casting now has immediate cosmetic feedback. An older pre-cast snapshot
cannot erase it while the host decision is in flight; this protection expires
after 1.5 seconds. The host still validates casts, controls bites, replays seeded
reeling input, and alone grants catches. No inventory or catch is speculative.

The 60 Hz local tension simulation is retained. Fishing replay uses its own
sequence/count/elapsed-time validation rather than sharing the generic UI
command rate bucket, so a delayed reliable burst cannot lose a middle batch to
that limiter. Guest visual clocks advance between snapshots, and bobber origins
and targets retain their ship-relative coordinates. This puts the line and boat
on the same presentation timeline. Shoreline endpoint searches are cached at
10 Hz, and off-screen anglers skip drawing work. Tiny bobber-motion water checks
remain per draw to keep the visible motion near water.

### Synchronization and bounded work

World motion remains at 10 Hz. Inventories, storage, dropped items, quest state,
discovery state, island locks, and the world seed travel in reliable shared-state
revisions only when changed or when a peer joins. Each motion packet references
the exact shared revision it needs; there is no dependency on the previous
unreliable motion packet. Clients retain eight shared revisions and at most one
motion packet waiting for its shared state.

Inventory captures are cached by resource revision. Identical inventory and grill
restores no longer copy state or emit update signals. Selection refreshes happen
only when selection changes; unchanged floor drops are not cleared/rebuilt.
The host still sends compressed motion once for relay fan-out. Guests still keep
only the newest pending motion snapshot. The outgoing unreliable-data threshold
is reduced from 64 KiB to 16 KiB; it prevents adding more obsolete data but cannot
remove bytes already queued inside TCP. Reliable gameplay remains reliable.

All four crew members still share the boat state. Per-recipient world interest
management is deliberately deferred: current traffic is small and the crew can
interact with the same objects. Decorative ocean fish remain deterministic/local.

### Playtest diagnostics

While online, press **Esc**, click **Network diagnostics**, or press **F3**.
Press **F4** to write a text sample to the local Godot/browser console. Native
test runs can pass `--network-diagnostics`. Nothing is uploaded as telemetry.
When enabled, each guest sends one diagnostic ping every two seconds through
the relay to the host and receives an echo: this is host RTT, not relay-only ping.

The overlay shows FPS, recent local/host frame peaks, host RTT, snapshot gap/age,
peak gap, playback delay, underrun frames, correction size/peak, hard correction
count, prediction history, compressed snapshot size, build/apply time, rejected
packets, relay throughput/backlog/skipped packets, and fishing simulation/replay
progress and geometry cost. Host views also show each guest's input queue.

- High frame time with stable RTT points toward CPU/rendering work.
- Large gaps/age and growing underruns with steady FPS point toward delivery or
  host stalls. The host frame measurement helps distinguish them.
- Large corrections with normal gaps merit checking collision/state transitions.
- Fishing's local frame can lead host replay because it is predicted; a growing,
  persistent gap is the useful warning. The bar should still react locally.
- State resets count changes such as boarding, stations, and respawns separately
  from drift resets (position errors exceeding 150 pixels without a state change).
- Underruns count physics frames, not lost packets. Skips include coalesced motion
  snapshots, which are expected after a burst; neither is a packet-loss meter.

The November 20 cellular-host screenshots showed 77–85 FPS, 90–102 ms host RTT,
about 11 KiB/s download, zero outgoing backlog, and a 600 ms peak snapshot gap.
They establish a past delivery/simulation interruption, not its location. The
unchanged underrun counter across captures does not establish ongoing stalls.
Peak values retain earlier events; compare successive samples and record both
host and guest diagnostics. Inactive fishing counters can retain the last fight.

### Validation and release

Use `tests/network_responsiveness.gd` for malformed input, bounded exact replay,
delayed reversals/stalls, real deck collisions and reconciliation, shared-state
ordering, skipped snapshots, unchanged inventory notifications, local fishing,
and ship-relative casts. Existing smoothing, classroom policy, grill, pause,
solo fishing, and three-player smoke suites remain applicable.

`tests/network_smoothing.gd` additionally checks stale hotbar snapshots, selection
retry/confirmation, close suppression, restored selection, and all six guest
traversal phases under missing snapshots. `tests/swim_transition_test.gd` checks
the authoritative animation sequence; `tests/swimming_integration.gd` checks
continuous shoreline travel and boarding without obsolete island scene changes.

Follow-up release validation: 81 responsiveness checks, 47 authoritative swim
transition checks, smoothing/UI and swimming integration suites passed. The
three-player relay run passed 68 checks with 80–120 ms delay in each direction
and a 300 ms stall every five seconds, including an 80-selection scroll burst.
TypeScript validation, 19 relay/service checks, and the release web export passed.
These are automated regression results, not a guarantee against cellular stalls.

`tools/run-network-playtest.mjs` runs isolated host/Alpha/Beta processes and keeps
logs under `.godot/network-validation/`. It rejects a zero-check guest run.
`tools/network-delay-proxy.mjs` adds deterministic delay/jitter and periodic
stalls to a local relay's ordered TCP stream. This models delivery interruption;
it does **not** claim to simulate raw UDP packet loss. The shared-state test
separately verifies that skipped motion snapshots cannot lose inventory changes.
See [multiplayer testing](multiplayer-testing.md) for runnable commands.

Protocol 16 is intentionally incompatible with older live peers. Deploy the
matching harbor Worker and Web export together and have all players reload.
Protocol-15 and earlier supported voyage saves remain loadable. These branch
changes and local exports do not publish anything to the live site.

Observed local validation on November 20:

- 81 targeted responsiveness checks passed, including real deck collision and
  reversal reconciliation within 0.5 pixels under delayed input playback.
- Final delayed-relay run: 65 checks passed (host 31, Alpha 20, Beta 14), with no
  rejected valid packets. Guest host-RTT samples were 221–222 ms; the long-lived
  guest observed a 400 ms peak snapshot gap from the injected stream stall.
- Host traffic averaged 11.62 packets/s and about 9.1 KiB/s; active Alpha averaged
  7.73 packets/s and about 1.0 KiB/s, including reconnect traffic. These are one
  scripted run's measurements, not a classroom capacity or free-tier guarantee.
- 84 solo fishing checks, 21 grill checks, 8 classroom policy checks, smoothing,
  pause, island co-op (20 checks), separate chest, and dedicated access/save tests
  passed. Older fixture assumptions and audio shutdown timing were corrected.
- All 19 relay/backend tests and the TypeScript check passed. The delay proxy's
  byte-order/EOF integrity test passed before the final delayed gameplay run.
- A fresh Web export completed without errors. Two isolated Chromium players
  hosted/joined, moved, displayed diagnostics, and received host departure with
  no browser runtime errors. This uses software rendering and is not a GPU FPS
  benchmark. Screenshots and local logs are under `.godot/`.

Still necessary: a real Windows/Mac/Safari/hotspot playtest and observation of the
diagnostics while multiple people fish and steer. Synthetic tests do not prove
subjective WAN smoothness. WebSocket ordered-delivery stalls and host browser
background throttling remain architectural limits. Revisit WebRTC after collecting
these measurements; a higher snapshot rate or new hosting provider is not assumed
to be the answer.

## Earlier implementation notes (protocols 6–15)

Companion to [the multiplayer system guide](multiplayer-system.md). This describes
the earlier implementation. Updated November 18, 2026; the protocol-16 section
above supersedes conflicting timing, input, and synchronization details below.

## Local movement and station controls

Previously, guests waited for the captain's next snapshot and interpolated their
own player toward it. This added a round trip to the feeling of movement. Sail
angles also jumped directly to each snapshot value.

`NetworkSession._physics_process()` now calls `_predict_local()` for the local
guest each physics frame. It calls the same `player.move_crew()` movement method
used by the host, including its collision and movement-lock rules. Sail trim
and helm angles also react immediately when that player owns the station.
Ownership itself is still confirmed by the host; taking a station is not guessed.

Changed controls send immediately; unchanged controls refresh every 0.5 seconds.
The sequence number is the client's physics-frame number. The host accepts only
increasing sequences and advances its acknowledgement while simulating held
input between refreshes. Snapshots include that acknowledgement as crew[id].ack.
World snapshots target 10 Hz. The current protocol is holy-ship-coop-13.

Each guest retains at most 120 predicted frames, with position, sail trim and
wheel angle. `_reconcile_local()` discards frames through the acknowledgement
and compares the matching predicted position with the host's position. The
remaining movement is kept, rather than resetting the player to an old snapshot.

Small position errors are corrected exponentially at rate 12 per second in
`_predict_local()`. The same adjustment shifts retained prediction records so
the next acknowledgement compares positions in the corrected space. Large
errors over 150 world/design pixels, boarding changes and station changes reset
the prediction history. Those resets deliberately favor host correctness over
concealing a genuine teleport or movement-state change.

Local sail/helm drift is corrected exponentially at rate 8 per second, preserving
adjustments made since the acknowledged input. Ship and remote crew positions
use the timestamped playback buffer described below. Remote station angles
add exponential easing at rate 18 per second. Local player positions are
excluded from remote-player playback.

Opening the map retains an occupied station and its keyboard controls. Map
clicks are not forwarded as held gameplay mouse input. Walking without a station
remains blocked by the map in the online input path. Station UI and camera focus
belong to the local operator; the shared station state still belongs to the host.

This is bounded local prediction with acknowledgement-based correction, not a
deterministic rollback simulation or a replacement for authority. WebSockets
still deliver ordered traffic, the host still samples input, and poor connections
can still cause corrections. Inventory, catches, chest transfers, cooking and
station ownership remain authoritative. Do not make those optimistic merely to
hide latency: doing so can duplicate items or show a catch the host rejected.

### Files and tuning points

- `scripts/network/network_session.gd`: prediction history, input sending,
  acknowledgements, reconciliation, interpolation, and reset on leaving.
- `scripts/network/snapshot_buffer.gd`: playback delay, bounded history, clock
  adjustment, transition handling and local underrun counter.
- `scripts/player.gd`: movement and movement-lock rules shared by prediction
  and host simulation.
- `scripts/sailing/ship_motion.gd`: clamps for sail and helm values.
- `scripts/network/harbor_peer.gd`: bounded queues and congestion behavior.

Keep host and guest movement speeds/clamps consistent. Raising snapshot rate
increases relay traffic; it is not the first fix for responsiveness. Test start,
stop, reversal, diagonal motion, deck collisions, swimming, boarding, station
entry/exit and reconnect when changing these values. Host physics and guest
presentation are different, so always inspect a guest as well as the captain.

## Normal exit versus lost connection

Normal exits now have explicit notifications instead of relying only on timeout:

1. `HarborPeer._close()` sends a WebSocket `leave` control message before closing.
2. On Web, `HarborService` installs a `pagehide` handler for browser Back, reload
   and tab close. It sends a one-time `navigator.sendBeacon()` POST to
   `/api/crews/{room_id}/leave`. If queuing the beacon fails, it attempts a
   keepalive fetch. Normal in-game leaving invokes this handler too.
3. The body contains the original connection ticket. The room keeps only its
   hash on the socket attachment and accepts it solely for that connection's
   departure. It is not the persistent sailor token or a room-wide permission.
4. `VoyageRoom.depart()` marks the attachment departed before asynchronous
   cleanup. `sessions()` excludes departed sockets immediately, freeing both
   capacity and the duplicate-identity check. Remaining peers receive
   `peer_left`, and the directory is updated. Host departure ends the room.
5. Repeated notifications are harmless. A late notification from an old page
   cannot remove the same sailor's new connection because it has a new ticket.

The departure endpoint can also cancel a not-yet-used ticket. Leaving while a
connection is being established therefore does not leave that ticket reserving
a guest slot until its normal expiration. Do not log tickets or beacon bodies.

No new repeating timer or faster polling was added. A departure adds a small
number of messages/requests once at exit. Simply switching tabs does not fire
this departure path; `visibilitychange` is intentionally not used to kick players.

Browser lifecycle delivery is best effort. A crash, power loss or lost internet
can prevent all exit messages from reaching the service. Existing safeguards
remain: ten-second client heartbeats, a 20-second client silence timeout,
120-second room housekeeping alarms with a 60-second socket-silence threshold,
and 180-second directory leases. These are not exact UI deadlines. Browsers
showing Browse crews refresh about every 30–35 seconds;
**Refresh crews** fetches sooner, and opening Browse fetches a fresh list.

## Testing and observed results

Local relay, in two terminals from `online-service/`:

```powershell
npm.cmd run dev
```

```powershell
npm.cmd run check
npm.cmd test
```

`test/departure.test.mjs` checks immediate slot release, same-identity rejoin,
wrong-ticket protection, repeated old notifications, explicit socket leave and
host listing removal. The relay suite also checks admission, capacity and packet
identity/routing. The combined suite passed 11 tests when this change shipped.

For the browser navigation regression, use isolated test crews, not a real crew:

```powershell
$env:HARBOR_TEST_URL = 'https://holy-ship.pages.dev'
$env:DEPARTURE_CHECK = '1'
node test/browser-pair.mjs
```

This launches separate Chromium profiles, hosts and joins, navigates the guest
away, verifies occupancy after one second, then reloads in the same profile and
rejoins. The deployed test passed with the guest slot released by that one-second
check. This is an observed result, not a guarantee for every network or browser.
The script currently uses the Windows Chrome executable path; adjust it when
running on another development machine.

`tests/network_smoke_suite.gd` additionally checks immediate predicted guest
movement before a host response, shared gameplay and reconnect inventory. See
[multiplayer-testing.md](multiplayer-testing.md) for the three-process setup.
Real Mac/hotspot and high-latency play sessions remain important subjective
checks: passing a scripted connection test does not prove movement feels ideal.

## Shipping related changes

Export the game and deploy Pages for changes to GDScript or menu/game assets.
Deploy the harbor Worker for relay code changes. For changes spanning both,
deploy the backend and matching game as described in the
[release guide](online-services-setup.md), then have players reload.
Both game and Worker must use matching protocol identifiers. The smoothing
addition keeps protocol 13 and supports older protocol-13 snapshots without
timestamps. Have every player reload for consistent behavior. See the main
multiplayer guide for save-version compatibility.


## Historical context: November 15 / protocol 6

Guest fishing runs locally at 60 Hz. Reliable batches of six hold/release inputs
are sent at 10 Hz; the host replays the seeded fight and alone awards catches.
Snapshots do not overwrite the local tension bar. Stale, duplicate and excessively
fast input is rejected. Bite timing includes 750 ms transport grace.

Host departure marks the room ended before closing guest sockets. The directory
keeps a three-minute hidden tombstone so late guest disconnects cannot republish
the listing. Normal departure is immediate; crashes still rely on timeout cleanup.

Hosts now select one of three dated local saves. Browser storage is synchronous
localStorage; desktop saves use atomic files. Autosave runs every 20 seconds and
on normal exit/page navigation. Old native single saves migrate once. Protocols
1–6 load. See [save slots](save-slots.md) for persistence and capacity details.


## Historical context: world survival / protocol 8

The bounded seeded world, shared sharks, health, death and sinking rules are
implemented in [world survival](world-survival.md). That release introduced protocol 8. The current protocol is 13;
the game and harbor must match.


## Guest smoothing update — November 18, 2026

Guest ship movement now uses a bounded 150 ms snapshot playback buffer with
host monotonic timestamps. Remote crew positions use that same timeline.
Playback gently adjusts its clock for drift; duplicate/out-of-order snapshots
are ignored, teleports and gaps over 500 ms reset it, and outages hold the last
host pose rather than extrapolating through land. At most 12 snapshots remain
in memory. SnapshotBuffer.underruns counts frames that exhaust the buffer for
local diagnostics; it sends no telemetry. Older hosts without timestamps use
the existing 10 Hz sequence as a fallback.

Walking, helm angle and sail trim remain locally predicted. Helm/trim drift is
now corrected exponentially at 8 per second, with matching corrections to the
prediction history, instead of a visible 25% jump when a packet arrives.
Ownership transitions discard pending control corrections. Remote boarding,
respawns and station transitions bypass positional blending across different
coordinate spaces. Ship physics/collision authority remains with the host;
this pass does not predict the boat through shore collisions.

The snapshot frequency (10 Hz), immediate changed inputs, unchanged-input
refresh (0.5 s), room fan-out, heartbeat and discovery rates are unchanged.
The only wire addition is a timestamp in the existing compressed snapshot.
There are no added HTTP requests, telemetry uploads or database operations.
This is compatible with protocol 13; deploy all peers for consistent behavior.

Free-plan limits are account-wide, not a per-crew guarantee. Cloudflare's
Durable Objects pricing lists 5 million SQL rows read/day, 100,000 rows
written/day and 100,000 request units/day; incoming WebSocket messages use a
20:1 billing ratio. Gameplay packet forwarding does not access SQL/KV, but
admission, discovery, request gates, alarms and room lifecycle do. Fifty or
more players can still exhaust request or duration allowances over long
sessions. Check the dashboard before and after a realistic class-length test;
this change does not claim unlimited free hosting or modify the account plan.
Source: https://developers.cloudflare.com/durable-objects/platform/pricing/

Regression commands (replace `godot` with your Godot executable):

```powershell
godot --headless --path . --script res://tests/network_smoothing.gd -- --settings-test
godot --headless --path . --script res://tests/classroom_policy.gd -- --settings-test
```

The smoothing suite checks uneven arrivals at 30/60/144 FPS, stalled streams,
stale packets, teleports, reset, and immediate local helm input with gradual
correction. Real WAN/browser play remains necessary to judge perceived latency.

Validation: three local ENet peers passed 49 existing multiplayer smoke checks
(host 28, guests 13 and 8). The traffic-policy suite passed 8 checks, menu
flow passed 61, and shore-recovery and playtest-UI suites passed. These are
local/synthetic checks, not a 50-player production load or real WAN benchmark.
## WebRTC branch update (November 26, 2026)

Protocol 17 adds an optional browser WebRTC fast path for unreliable traffic,
using free Cloudflare STUN and the existing relay as fallback. Reliable input
batches and actions remain on WebSocket. See [WebRTC networking](webrtc-networking.md)
for architecture, free-service boundaries, diagnostics, disable switch and tests.

## Protocol 19 shared gameplay

See [shared gameplay](shared-gameplay.md) for deterministic catchable fish,
shared waypoints, cooking escrow and damage effects. It retains protocol 18
movement/relay smoothing, WebRTC fast lane, free STUN and WebSocket fallback.
