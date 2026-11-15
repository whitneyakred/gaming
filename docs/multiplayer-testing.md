# Holy Ship co-op public-test build

This is a small, invite-based desktop playtest for up to four people. The host
simulates the shared boat, players, stations, inventory and fishing. Browser
exports remain solo-only. There is no public server directory or host migration.

## Host & Play

1. Start `HolyShip.exe`, choose **Co-op • Host / Join**.
2. Enter your sailor name and optionally a session password.
3. Leave **UDP port** at **24567** (or choose an unused port).
4. Leave **Host: continue saved voyage** checked to resume the previous hosted
   world. Uncheck it to start a new hosted voyage, replacing the current save.
5. Click **Host & Play**. The host PC must remain awake with the game running.

Friends choose **Co-op • Host / Join**, enter their own name, the host address,
the public UDP port, and the same session password, then click **Join crew**.
Everyone must use the same build. Local testing uses address `127.0.0.1` only
when both game processes are on the same computer; other PCs use your LAN IP or
public/tunnel address. Each normal OS user has a persistent crew identity.

## Friends on different Wi-Fi networks: free UDP tunnel

The game does not automatically make your home PC publicly reachable.

1. Create/sign in to a playit.gg account and download its agent from
   https://playit.gg/ . Only the host needs the agent.
2. Run the agent and link it to your account using the link it provides.
3. Create a **UDP** tunnel targeting **127.0.0.1**, local port **24567** (or the
   local port chosen when hosting). Generic UDP is currently listed on the free
   tier; custom TCP and TCP+UDP require Premium. No paid service is required by
   Holy Ship itself.
4. Keep both the agent and Holy Ship running.
5. Give friends the **public hostname and public port** shown by playit. The
   public port can differ from your local port. Put the hostname alone in the
   address box and the public port in **UDP port**.
6. Have someone outside your network join. Test walking, helm/sail ownership,
   shared chest transfers, drops, fishing, swimming and reconnecting.

Alternative: forward your chosen **UDP** port on your router to the host PC and
share your public IP and port. ISP carrier-grade NAT may prevent that route;
use a UDP tunnel instead. If Windows asks, allow the game through the firewall
for the network on which you intend to host. No router/firewall rules are changed
by the game or by this repository's setup.

## Dedicated server on your PC or a spare PC

The same executable can run without graphics. Open PowerShell in the game folder:

```powershell
$env:HOLY_SHIP_PASSWORD = 'choose-a-session-password'
.\HolyShip.exe --headless -- --server --port 24567
```

On Linux use `./HolyShip.x86_64 --headless -- --server --port 24567` and set
`HOLY_SHIP_PASSWORD` in the shell environment first if desired. The Linux binary
is cross-exported and needs Linux runtime testing. The server resumes its saved
world. Add `--new-world` to deliberately replace it with a new voyage. Connect
from another game instance using `127.0.0.1` on the same machine or the tunnel
address from elsewhere. A dedicated server does not occupy a crew slot.

## What is shared

- Server-driven boat position/rotation, wind, sail level/trim, wheel and anchor.
- Four independently controlled crew, with names and per-player inventories.
- Exclusive helm, sail and galley occupancy. E takes/releases a station;
  A/D steers/trims, W/S cycles sail deployment. Anchor is a one-press toggle.
- The ship chest, item transfers, drops, pickup and open/closed chest artwork.
- Fishing rods, lines, bobbers, reeling state and catch animations. The server
  checks cast range, bite timing and tension, and awards the catch once.
- Swimming and walking directly on world islands. Islands no longer launch
  minigames or rowboat cutscenes. Use the port plank to enter the water and the
  ladder to return. Islands currently have no new objectives or resources.
- Galley: interact near the kitchen; after three seconds, one sea bass becomes
  dried fish if there is inventory room. The old solo recipe UI remains solo-only.

Cameras, spyglass, map UI and menus stay local. Opening pause/settings does not
freeze an online voyage: your controls stop and your station/fishing interaction
is released while the other players keep going. Server loss returns clients to
the title with a message; it does not silently create a new solo voyage.

## Saves and reconnects

The host autosaves every 20 seconds and on graceful leaving/quitting and player
disconnection. Saves include boat location, chest, floor items and crew bags.
The resumed boat is anchored. Rejoining players spawn safely aboard with their
previous inventory; their rod and spyglass are not duplicated.

Use **Project > Open User Data Folder** in Godot to find the active user-data
folder. Exported Windows builds normally use
`%APPDATA%\Godot\app_userdata\Holy Ship\`. `hosted-voyage.save` is the hosted
world; `crew_identity.cfg` identifies this installation to hosts. Keep that
identity file to retain your bag across reconnects. Saves are local to the host,
not uploaded. There is one hosted save per OS user. A separate dedicated-server
OS account gives it a separate save. Solo voyages are still not saved to disk.

## Scope and remaining external verification

This build is intended for small invited playtests, not unattended anonymous
public hosting. Session passwords are access gates, not encrypted account login.
There is no Steam/account service, voice chat, matchmaking, moderation UI, or
host migration. Clients use server snapshots with visual interpolation; high
latency will be noticeable because movement prediction is not implemented yet.

Local UDP tests cover three simultaneous instances, chest contention, drops and
pickup, station ownership, fishing replication, seamless land travel, reconnect,
password rejection, dedicated server operation and save reload. Windows rendered
clients were inspected. An actual off-network playit/router test and Linux/macOS
runtime tests require those environments. The current workstation lacks the
macOS export template, so no Mac binary is included.

## Developer checks

- `tests/network_smoke.gd`: start host with `--test-host` and two clients with
  `--test-alpha` / `--test-beta`, each using `--settings-test`. Uses UDP 24678.
- `tests/network_access.gd`: host/client roles on UDP 24679; checks passwords,
  dedicated hosting and save reload. Always add `--settings-test`.
- `tests/fishing_test.tscn`, `tests/inventory_integration.tscn`,
  `tests/spyglass_test.tscn`, and `tests/menu_flow.gd` cover solo regressions.
- Test identities and saves live under `.godot/`, leaving player data untouched.

Rollback checkpoint: commit `38ca32e` and tag **pre-multiplayer**. To inspect the
old game without losing current work, use a separate Git worktree or branch at
that tag rather than resetting this branch.
