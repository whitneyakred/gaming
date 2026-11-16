# Local responsiveness and prompt disconnects

Companion to [the multiplayer system guide](multiplayer-system.md). This describes
the current implementation, not a proposed design. Updated November 15, 2026.

## Local movement and station controls

Previously, guests waited for the captain's next snapshot and interpolated their
own player toward it. This added a round trip to the feeling of movement. Sail
angles also jumped directly to each snapshot value.

`NetworkSession._physics_process()` now calls `_predict_local()` for the local
guest each physics frame. It calls the same `player.move_crew()` movement method
used by the host, including its collision and movement-lock rules. Sail trim
and helm angles also react immediately when that player owns the station.
Ownership itself is still confirmed by the host; taking a station is not guessed.

Input is normally sent every 0.05 seconds. Direction changes send immediately,
so starting and stopping do not wait for the next scheduled send. The sequence
number is the client's physics-frame number. The host accepts only increasing
sequences and includes its last accepted sequence as `crew[id].ack` in snapshots.
The current network protocol is `holy-ship-coop-6`; old clients must reload.

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

Local sail/helm drift is corrected by 25% of the acknowledgement error per
snapshot, preserving adjustments made since that input. Other players, the
boat transform and remote station angles interpolate at rate 18 per second.
Local player positions are excluded from that remote-player interpolation pass.

This is bounded local prediction with acknowledgement-based correction, not a
deterministic rollback simulation or a replacement for authority. WebSockets
still deliver ordered traffic, the host still samples input, and poor connections
can still cause corrections. Inventory, catches, chest transfers, cooking and
station ownership remain authoritative. Do not make those optimistic merely to
hide latency: doing so can duplicate items or show a catch the host rejected.

### Files and tuning points

- `scripts/network/network_session.gd`: prediction history, input sending,
  acknowledgements, reconciliation, interpolation, and reset on leaving.
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
remain: five-second client heartbeats, a 20-second client silence timeout,
30-second server alarm checks with a 60-second socket-silence threshold, and
75-second directory expiry refreshed by live rooms. These are not exact UI
deadlines. Browsers already showing the list normally refresh every 15 seconds;
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
Protocol 6 adds local fishing input replay. Both game and Worker must use the
matching protocol; existing players must reload. Save loading accepts protocols 1–6.


## November 15 update: protocol 6

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


## World survival update (protocol 8)

The bounded seeded world, shared sharks, health, death and sinking rules are
implemented in [world survival](world-survival.md). Protocol 8 is current; both
game and harbor must match. Saves from protocols 1–7 remain loadable.
