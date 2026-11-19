# Local voyage save slots

**Host a voyage** has three slots. Select an empty slot to launch a fresh world,
or a dated occupied slot to resume it. **Clear selected save** requires confirmation
and clears only that slot. The other two worlds remain intact. Saving never creates
a fourth slot or silently replaces a different slot. Privacy/password are chosen
for the current session rather than stored in the world.

## Where the data lives

- Browser: three keys in localStorage on the host's device, scoped to the exact
  website origin and browser profile. No world snapshots are written to Cloudflare.
- Desktop/editor: three files under Godot's user-data directory. Use **Project >
  Open User Data Folder** in Godot to inspect them.
- The host's sailor token is persistent too, so the host and returning guests can
  regain their remembered inventories when the same host resumes the world.

Normal browser/computer restarts keep saves. Clearing site data, deleting the
browser profile, private-session expiry or browser storage eviction may remove
them. Changing devices, profiles, browsers or domains does not transfer them.
There is no account-based backup or cloud recovery. A guest cannot resume the
captain's world on their own device. Two simultaneously hosting tabs in the same
profile should use different slots; they share the same local storage.

## Snapshot and timing

The captain saves after loading, every 20 seconds, on normal leaving, and in a
browser pagehide callback (Back/reload/tab close). Browser storage writes are
synchronous; errors such as storage quota/blocked access are reported rather than
claiming success. Abrupt process/power loss can lose progress since the last
20-second autosave. Native writes use a temporary file followed by atomic rename.

Snapshots include boat position/rotation, chest contents, floor drops, grill food
and fuel, and remembered crew inventories. Resuming anchors the ship safely;
active fishing fights, station ownership, network connections and private-session
passwords are not restored. Islands still use the existing deterministic world.

The envelope contains title, saved timestamp and a base64 Godot Variant payload
(decoded without object construction). Dates are displayed in local time. The
previous single native hosted-voyage.save is migrated once into slot 1, with its
original file retained as .migrated. Browser snapshots are not uploaded on save.

## Limits and testing

Three slots are a UI/storage policy, not the number of online servers. The game
allows four sailors per crew. Discovery returns up to 100 listings per each of
four shards (400 maximum returned), and the existing abuse guard allows eight
new hosted sessions per hour per IP. These are separate from Cloudflare's shared
free-plan quotas. There is no global room-creation count cap in this code.

Cloudflare Free currently includes 100,000 Durable Object billed requests/day,
13,000 GB-s/day, and 100,000 SQLite rows written/day. WebSocket messages count at
a 20:1 request ratio; gameplay traffic therefore consumes the allowance even
though world saves stay local. Hitting a free quota makes further affected
operations fail until reset; it is not unlimited public-server capacity.
Source: https://developers.cloudflare.com/durable-objects/platform/pricing/

Validation: tests/voyage_saves.gd checks typed-world roundtrips, all three slots,
dates and independent reset. online-service/test/browser-saves.mjs exercises real
browser storage, full browser restart, page navigation departure, menu resume and
confirmation-based clearing. Network smoke tests cover the new local fishing input
path and host validation over ENet and the WebSocket relay.
