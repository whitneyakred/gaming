# Island challenge totems

Integrated from `merge-everything-fest` into `systems-revamp` as `8794889` on November 16, 2026. Published with the redesigned title screen to https://holy-ship.pages.dev.

Every generated island has a totem near its center, placed inside its coastline.
The 30 world islands reuse all 19 existing minigame scenes. Their original puzzles,
objectives, art, timers, and reward mechanics remain in those scenes.

## Play in Godot

1. Click **Run Project (F5)** and start a solo voyage, or open `scenes/ship.tscn`
   in the **FileSystem** dock and click **Run Current Scene (F6)**.
2. Sail to an island, swim ashore, and walk to the wooden totem near its center.
3. Press **E** within reach. The original minigame opens for that player.
4. Follow its objective; the original rowboat remains the finish line when required.
5. Winning returns you to the totem with prizes. Losing or clicking
   **Leave challenge (no prizes)** returns you without prizes or loss of existing gear.
   **Esc** opens the usual pause menu; **Resume voyage** returns to the challenge.

Each island allows one participant at a time. An occupied totem turns amber and
shows a waiting message. Other islands can run simultaneously. The ocean, ship,
and other players continue running. Only the participant's world movement,
inventory actions, and hunger drain are suspended. Solo pause still pauses the game.

## How the existing work is reused

- `WorldIsland.scene` still selects the original game. No challenge scenes were replaced.
- `IslandChallenges` attaches the reusable `minigame_totem.tscn` marker and owns
  reservations. `MinigameTotem` exposes **Interaction Distance** in the Inspector.
- Each participant runs the scene in an independent `SubViewport`/`World2D`.
  The sailing scene stays loaded; the actual player remains at the totem.
- The challenge avatar uses an empty, temporary prize bag. Parrot orders consume
  fruit from that bag, never from your voyage supplies. The HUD shows its contents.
- `IslandGame.embedded_finished` returns the result to the adapter. Standalone
  **F6** minigames retain their old return flow for existing tests and development.
- The host checks proximity, living/available player, occupancy, and attempt token.
  It grants allowed prizes once into the actual player's inventory. Overflow becomes
  ordinary world pickups beside the totem; step away and back after freeing space.
- Cancellation, failure, disconnection, death, and a ten-minute reservation limit
  release the island. Replay is allowed. Reservations are temporary, not saved.

## Current boundaries

The minigame simulation and reported outcome are local to the participant. The
host validates reservation ownership and per-scene prize limits, but does **not**
independently verify puzzle completion. This is a cooperative prototype trust
model, not cheat-resistant authoritative minigame simulation. The `PRIZES` table
must be updated if designers increase the original scenes' reward amounts.

The game and deployed Harbor use session protocol `holy-ship-coop-11`, preventing connections to older clients without the totem RPCs. Reload browser tabs after updating. Local ENet host/guest tests pass with the new protocol.

## Validation

Run with a Godot 4 executable from the project directory:

```text
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/island_totems.gd
godot --headless --path . --script res://tests/island_minigames.gd
```

The totem suite covers all 19 scene types, land placement on all 30 islands,
input isolation, visible exit controls, rewards, loss/cancel, stale/foreign
results, expiration, inventory overflow, and return position. Add `-- --capture`
without `--headless` to save rendered previews under `.godot/`.

For the localhost integration test, start these two processes together:

```text
godot --headless --path . --script res://tests/island_totems_network.gd -- --test-host --crew-profile totem-host
godot --headless --path . --script res://tests/island_totems_network.gd -- --crew-profile totem-guest
```

The two-process test covers occupancy, independent islands, guest control,
authoritative reward delivery, replay, and disconnect cleanup. It needs localhost
UDP access (the restricted command sandbox blocks that). No hosted service is used.

November 16 verification: clean Godot 4.7.2 editor import, 215 passing totem
checks, 20 passing localhost host/guest checks, and zero failures in the original
minigame suite. Rendered previews were inspected with the Compatibility renderer.
The network test processes also emitted ObjectDB/resource-in-use warnings at
shutdown; their gameplay assertions passed. These warnings are not a claim of
clean runtime resource teardown.
