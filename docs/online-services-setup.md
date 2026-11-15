# Internet crews: setup handoff

The current browser discovers LAN games. It is not an internet directory.
The next integration is Epic Online Services (EOS) Lobbies plus P2P transport,
so a player can host a named crew and others can browse and join without addresses.

EOS describes its services as free and engine/platform agnostic:
https://dev.epicgames.com/docs/epic-online-services/eos-overview

## Project owner: first step

1. Sign in at https://dev.epicgames.com/portal with your Epic account.
2. Create/select your development organization and create a product called **Holy Ship**.
3. Open **Product Settings**. Keep the development sandbox/deployment for testing.
4. Tell the coding assistant the product is created. Do not send your account
   password or account recovery information. Client policy/SDK configuration comes
   next, after checking the selected Godot integration's requirements.

Official product setup reference:
https://dev.epicgames.com/docs/dev-portal/product-management

## Implementation still required

- Select and validate a maintained Godot EOS native extension against Godot 4.7.2
  and Windows/Linux/macOS. Game code stays GDScript; browser solo remains independent.
- Configure the game client and narrowly scoped policies for Connect, Lobbies and P2P.
- Authenticate game instances, publish/update crew name, capacity and current occupancy,
  search compatible lobbies, and clean up on graceful leave or timeout.
- Replace direct ENet for online sessions with EOS P2P/relay transport while preserving
  server authority, peer 1 assumptions, three RPC channels and existing gameplay validation.
- Preserve local discovery and direct connect as fallback paths.
- Verify editor-to-editor and exported clients across separate internet connections,
  full/private crews, disconnects, reconnect identity, and deployment access restrictions.

Do not advertise global browsing as available until those tests pass. EOS removes
the need to operate our own lobby/relay service, but introduces a service dependency
and native plugin maintenance. The player's hosting device still runs the world
simulation and must stay online; this is not an always-running hosted world.
