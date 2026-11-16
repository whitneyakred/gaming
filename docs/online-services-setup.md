# Holy Ship internet crews

Internet crew browsing and relay transport are integrated using EOSG 2.3.1 and
Epic Online Services Connect + Lobbies + P2P. Game code remains GDScript.
The host device runs the simulation and must stay awake. This is not an
always-running cloud server; ending the host session ends the voyage for guests.

## Project setup

The Holy Ship product and HolyShip-Game client already exist in Epic's portal.
The current client uses the Peer2Peer policy. Its five SDK values are stored in
`.local/eos.cfg` (ignored by Git): product_id, sandbox_id, deployment_id,
client_id, client_secret under an [eos] section. Never commit this file.

Run `powershell -File tools/install-eos.ps1` from the project root on a new
checkout, then restart Godot so it loads the native extension. The installer
pins EOSG 2.3.1 and downloads Windows, macOS, and Linux native dependencies.
Only the low-level wrapper is used; no Epic overlay or microphone is enabled.

On a Mac checkout, close Godot and run `bash tools/install-eos-macos.sh` from
the project folder in Terminal. This downloads and checksum-verifies the pinned
Mac native libraries, preserving framework structure. Copy `.local/eos.cfg`
privately from your Windows project to the same relative location on the Mac;
Finder's Command+Shift+Period shortcut shows hidden folders. Neither dependency
binaries nor local configuration arrives through Git. Reopen Godot after setup.
If the extension still fails to load, inspect the Output panel's first
GDExtension/dynamic-library error; missing files and macOS loading rejection
need different fixes. This setup is for developers, not exported-game players.

The Holy Ship export plugin embeds the game-client configuration in desktop
packages as res://online/eos.cfg. These are untrusted game-client credentials,
not administrative/server credentials. Do not replace the client policy with a
trusted-server policy. Web Solo excludes both the native adapter and credentials.
Native binaries and export templates are ignored by Git and must be installed
on the machine doing exports.

## Connections and identity

Online hosting and browsing are the default. EOS relay routing is forced for
these sessions, so the planned hotspot playtest exercises the relay route.
Players do not enter IP addresses, ports, or Epic account passwords. Device
login identifies each OS user. Two processes under the same OS account share
that online identity and cannot join each other online; use separate devices,
separate OS accounts, or the LAN test path instead. --crew-profile only separates
LAN/save profiles, not Epic's device identity.

Crew names, occupancy, and password markers are published in compatible lobbies.
New/closed listings can take several seconds to appear/disappear in Epic's search
index. Use Refresh crews. The password itself is not a lobby attribute. The host
checks the password and capacity before admitting a player to the world.

A host leaving destroys its lobby; guests leaving release their membership.
Authentication refreshes before token expiry. Failed sign-in, join, and server
loss return an explanation to the player. Host migration is intentionally off.

## Validation and limits

Verified on Windows: live device sign-in, native host creation, game loading,
searchable crew metadata, removal, and clean SDK shutdown. Local three-process
checks exercise gameplay through the relay-sized snapshot packet format.
Windows and macOS packages are provided for a real two-device hotspot playtest.
Actual Windows-to-Mac relay traffic and macOS runtime behavior still need that
external test. Do not call this a verified public release until it passes.

Small invited crews are the testing scope. Movement prediction, moderation,
host migration, and persistent cloud hosting are not implemented. Browser play
remains solo. The CLI dedicated server remains ENet/direct-connect, not an EOS
lobby host.

Dependency and service references:
- https://github.com/3ddelano/epic-online-services-godot/tree/56238973e2cd7ac9ac99ca14f88934465f0a8997
- https://dev.epicgames.com/docs/game-services/lobbies-and-sessions/lobbies
- https://dev.epicgames.com/docs/game-services/p-2-p
