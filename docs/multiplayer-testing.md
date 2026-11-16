# Holy Ship multiplayer testing

This is an invited desktop playtest for up to four sailors. Internet crews use
Epic's lobby directory and relay networking. No IP address, router port forwarding,
or tunnel is needed for the default Host a crew / Browse crews flow.

## Windows + Mac hotspot test

1. Windows: extract all of HolyShip-Online-Windows.zip into a folder, then run
   HolyShip.exe. Keep the PCK and all DLLs beside the executable.
2. Mac: transfer HolyShip-Online-Mac.zip to the Mac and extract it there. Open
   Holy Ship.app. This is an ad-hoc signed test build, not notarized. If macOS
   blocks it, use System Settings > Privacy & Security > Open Anyway for this
   app after trying to open it. Do not disable Gatekeeper globally.
3. Connect the Mac to the phone's hotspot; leave Windows on its normal internet.
   Give each sailor a different name on the title-screen character card.
4. Windows: Sail with a crew > Host a crew. Name it, optionally set a password,
   leave Local network only unchecked, then Launch crew. For a new test voyage,
   uncheck Continue my saved voyage (this replaces that host's hosted save).
5. Mac: Sail with a crew > Browse crews. Leave Search my local network instead
   unchecked. Wait a few seconds and use Refresh crews, then select the crew.
6. Confirm both players appear with the right names. Move on both devices;
   operate helm and sail; transfer chest items; drop and collect an item;
   fish while moving and confirm the other player sees the line and bobber;
   swim to an island and walk ashore.
7. Have the Mac leave and rejoin. Confirm its inventory returns without duplicate
   starter tools. Have the host leave: the Mac should return to the harbor with
   an explanation. Refresh browsing: the old listing should disappear shortly.
8. Repeat with the Mac hosting and Windows joining. Try a wrong password as well
   as the correct one. Up to four distinct devices can join the same crew.

Keep the host awake and running. Hosting ends when that game closes. Everyone
must use this same build/protocol. If a connection fails, record the on-screen
message and which device hosted. Logs are under Godot's user-data folder:
Windows: %APPDATA%\Godot\app_userdata\Holy Ship\logs\godot.log
macOS: ~/Library/Application Support/Godot/app_userdata/Holy Ship/logs/godot.log

## Godot editor and local fallback

Install the pinned native dependency with tools/install-eos.ps1, restart Godot,
and press F5 (Run Project). Editor and exported builds use the same online
service and can find each other. Editor configuration is .local/eos.cfg;
desktop exports embed it via the project's export plugin.

For LAN play, check Local network only on the host and Search my local network
instead on clients. LAN discovery uses UDP 24566 and hosting UDP 24567; firewall
or guest Wi-Fi isolation may block it. Direct connect remains an advanced ENet
fallback. The headless --server command also uses ENet, not EOS browsing.

Two processes under the same OS user have the same Epic device identity. Use
LAN for same-PC tests, passing -- --crew-profile second to the second instance.
Use separate devices/OS accounts for online testing.

## Shared gameplay and saves

The host authoritatively simulates the boat, wind, sails, wheel, anchor, crew,
station ownership, chest, inventory transfers, dropped items, fishing and catches.
Fishing lines, bobbers and reel state are visible to other players. Swimming
onto islands is seamless. Cameras, spyglass, map and menus stay local.
Pause/settings do not freeze an online voyage for other players.

The host saves every 20 seconds and on graceful leave/quit and disconnection.
Saves include boat location, chest, floor items and crew bags. Resumed boats are
anchored. Returning online players are identified by their EOS product-user ID;
LAN saves use the local crew identity. These are separate identities. Do not
expect an old LAN bag to automatically become your online bag.

There is one hosted-voyage.save per normal OS user. In Godot, Project > Open User
Data Folder opens the data folder. Saves remain on the host, not in the cloud.
Solo voyages still do not persist. There is no host migration or movement
prediction, so high latency is noticeable. Browser exports remain solo-only.

## Validation

- Live Windows EOS lifecycle: sign-in, host/world startup, crew search, occupancy,
  password marker, lobby destruction, and clean process exit.
- Three local processes with --snapshot-chunks: movement, chest contention,
  dropping/pickup, station ownership, fishing/catch, swimming/land and reconnect.
- Menu flow regression: 46 checks passed.
- Actual Windows-to-Mac internet gameplay and macOS launch require the above
  hotspot test. This is ready for that test, not a claim it already passed.

Developer scripts: tests/eos_lifecycle.gd uses live EOS; tests/eos_network.gd
has --test-host/client roles for two distinct online identities;
tests/network_smoke.gd uses --test-host, --test-alpha, --test-beta over local UDP
24678. Always add --settings-test to isolate test saves. Add --snapshot-chunks
to exercise the EOS-sized packet format through local ENet.

Rollback checkpoint: commit 38ca32e, tag pre-multiplayer. Inspect it using a
separate worktree/branch rather than resetting ongoing work.

Exported diagnostics (close other Holy Ship instances first):
Windows: HolyShip.exe --headless -- --settings-test --online-check
Mac: ./"Holy Ship.app"/Contents/MacOS/"Holy Ship" --headless -- --settings-test --online-check
This creates a temporary password-protected test lobby, checks discovery and
removal, then exits. It does not prove a second device can join. Test files are
isolated under .godot; launch from an extracted, writable folder.
