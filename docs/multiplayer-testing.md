# Holy Ship browser and desktop multiplayer tests

Architecture and release workflow: [Multiplayer system and operations guide](multiplayer-system.md).

## Protocol 16 local validation and diagnostics

Use a Godot executable in place of `GODOT_EXE`. These commands test the branch
without deploying it. Run the local relay from `online-service/` with
`npm.cmd run dev -- --port 8790`. In another terminal at the repository root:

```powershell
node tools/run-godot-checkpoint.mjs GODOT_EXE network_responsiveness network_smoothing classroom_policy grill pause_game
node tools/run-network-playtest.mjs GODOT_EXE --relay-test --harbor-url http://127.0.0.1:8790 --network-diagnostics
```

For delayed guests, leave this proxy running in another terminal:

```powershell
node tools/network-delay-proxy.mjs 8791 8790 80 40 300
```

Then run:

```powershell
node tools/run-network-playtest.mjs GODOT_EXE --relay-test --harbor-url http://127.0.0.1:8790 --guest-harbor-url http://127.0.0.1:8791 --network-diagnostics
```

This adds 80–120 ms in each direction on each guest connection and 300 ms stream
stalls every five seconds. Only localhost is contacted. Logs are written under
`.godot/network-validation/`. Traffic counters include reconnects.

For browser validation, export **Web Multiplayer** into
`.godot/network-web/index.html`, then run
`node tools/network-preview-server.mjs .godot/network-web 8792 8790`.
From `online-service/`, set `$env:HARBOR_TEST_URL='http://127.0.0.1:8792'` and run
`node test/browser-pair.mjs`. The preview serves only the local export and proxies
its API/WebSocket traffic to the local emulator. It does not publish a site.

For the next real playtest, use matching protocol-16 builds on all devices.
Press **Esc → Network diagnostics** (or **F3**) on both host and guest. Record
the overlay while walking, reversing, colliding with deck edges, boarding,
fishing on a moving boat, opening storage, and operating helm/sails. **F4** writes
a diagnostic sample to the local console. Swap hosts and repeat on a hotspot.
Use [the diagnostics guide](networking-responsiveness.md) to interpret readings.

Open https://holy-ship.pages.dev on Windows and Mac.
No downloads, developer accounts, EOS setup, or router configuration are needed.
Use different browser profiles/devices so each has its own persistent sailor.
Two tabs in one profile share identity and cannot join the same voyage twice.

## Real-device release check

1. Put the Mac on a phone hotspot and keep Windows on normal internet.
2. Choose Play Free, enter different sailor names, then Sail with a crew.
3. On Windows choose Host a voyage, name it, keep Public selected, and launch.
4. On Mac select the voyage in Browse crews. Refresh is automatic every 15
   seconds, or use Refresh crews immediately.
5. Confirm both names/players and movement, sail/helm ownership, shared chest
   transfers, dropping/picking up items, fishing line/bobber/catch, and swimming
   to an island. Keep the host tab in the foreground.
6. Leave and rejoin on the Mac: inventory should return without duplicate tools.
7. End the host voyage: guests should return to the menu with an explanation,
   and the listing should disappear. Retry with Mac hosting.
8. Host Private: the password field appears empty. Enter a password. Check
   wrong-password rejection and successful joining with the correct password.
9. With four different profiles/devices, confirm occupancy 4/4 and full-crew
   rejection. Refresh/reload all clients after a game update.

## What is synchronized

The captain authoritatively simulates the shared boat, wind, sails, wheel,
anchor, players, stations, chest, inventory transfers, dropped items, fishing
and catches. Cameras, spyglass and menus are local. Opening pause does not
freeze the shared world. Moving players send exact input in six-frame reliable
batches (normally 10 Hz), plus immediate changes; idle input refreshes at 2 Hz.
Motion snapshots run at 10 Hz, compressed once per tick. Rarely changing shared
state uses reliable revisions, and identical inventory/UI updates are skipped.
Slow connections skip stale outgoing snapshots
instead of building an unlimited queue. Input timeout prevents stuck controls.
Shared floor stacks are capped at 256; refused drops keep the inventory item.

## Persistence and limits

The hosted world autosaves every 20 seconds and on graceful leaving. Hosting
resumes that save automatically. Browser saves and identities are local browser
storage, not accounts or cloud saves. Clearing site data loses them. Different
browsers have different sailors. Editor/native saves use the Godot user-data
folder. Old EOS identities do not automatically migrate to new browser sailors;
world/chest data from protocols 1 and 2 remains readable.

The host must remain connected and awake. Local movement and sail/helm controls
are predicted immediately, with host acknowledgements correcting drift. Remote
controls interpolate between snapshots. There is no host migration, moderation
console, mobile touch support, or persistent cloud world.
The browser avoids macOS native signing requirements; the old ad-hoc Mac ZIP is
not the recommended player distribution. This is an early-access release, not a
claim that all future bugs or arbitrary public load have been eliminated.

## Automated verification

- tests/menu_flow.gd: 50 checks for menus/layout and simplified public/private UI.
- tests/network_smoke.gd: three simultaneous Godot instances through the relay;
  host 17 checks, Alpha 4, Beta 4. Covers chest contention, drops, fishing/catch,
  swim/land, station ownership and reconnect. Add --settings-test --relay-test
  --harbor-url http://127.0.0.1:8787 plus --test-host/--test-alpha/--test-beta.
- online-service/test/relay.test.mjs: password rejection, concurrent capacity,
  unique identities, forged-source replacement, routing, guest isolation,
  closed listing removal, version checks and cross-origin rejection.
- online-service/test/browser-pair.mjs: two isolated Chrome browser games host,
  discover, join, move and receive host disconnection. Uses HARBOR_TEST_URL to
  target the deployed service. Screenshots/logs are in .godot/.

The Windows-to-Mac hotspot check still requires those actual devices. Automated
browser tests are not a substitute for Safari/macOS hardware verification.

Rollback: pre-multiplayer points to commit 38ca32e. The EOS implementation is
also preserved in Git history. Use a separate worktree rather than resetting
ongoing work.
