# Holy Ship browser and desktop multiplayer tests

Architecture and release workflow: [Multiplayer system and operations guide](multiplayer-system.md).

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
8. Host Private: the password field appears with 123. Edit it if desired. Check
   wrong-password rejection and successful joining with the correct password.
9. With four different profiles/devices, confirm occupancy 4/4 and full-crew
   rejection. Refresh/reload all clients after a game update.

## What is synchronized

The captain authoritatively simulates the shared boat, wind, sails, wheel,
anchor, players, stations, chest, inventory transfers, dropped items, fishing
and catches. Cameras, spyglass and menus are local. Opening pause does not
freeze the shared world. Moving players send input at 20 Hz; snapshots run at
20 Hz, compressed once per tick. Slow connections drop stale outgoing snapshots
instead of building an unlimited queue. Input timeout prevents stuck controls.
Shared floor stacks are capped at 256; refused drops keep the inventory item.

## Persistence and limits

The hosted world autosaves every 20 seconds and on graceful leaving. Hosting
resumes that save automatically. Browser saves and identities are local browser
storage, not accounts or cloud saves. Clearing site data loses them. Different
browsers have different sailors. Editor/native saves use the Godot user-data
folder. Old EOS identities do not automatically migrate to new browser sailors;
world/chest data from protocols 1 and 2 remains readable.

The host must remain connected and awake. There is no host migration, movement
prediction, moderation console, mobile touch support, or persistent cloud world.
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
