# Networking playtest release and rollback

## November 27 workbench and smooth walking (protocol 24)

- Gameplay source: `f71c298` on `systems-revamp`; crafting commit `f1d72a7`.
- Pages deployment: https://115e4d5f.holy-ship.pages.dev
- Harbor version: `813c06fa-633b-4b81-89f5-f391727894f5` (matching new game assets; relay code/protocol unchanged).
- Public game: https://holy-ship.pages.dev/play/
- Previous release pair for rollback: Pages `9ec01793-10da-4dfd-9f8d-9012730ea9c0`, Harbor `fae37c4c-372e-4588-8f0c-1f3fc0d20dd5`.

Includes the simple weathered Workbench, icon-based recipe selection, fishing
rod recipe (3 wood, 1 rope, 1 string), persistent rod/axe/pickaxe durability, and
an unlimited-use spyglass. Local walking renders between physics ticks;
multiplayer snapshot presentation advances per rendered frame. Island minigame
camera follow now matches ordinary shore walking. See [crafting](crafting-and-durability.md)
and [movement validation](movement-smoothing.md).

Godot parser and Web export, 76 native three-peer gameplay checks, 20 island
host/guest checks, 370 island checks, animation/camera/smoothing regressions and
local Chrome WebRTC/fallback scenarios passed. Native rendered walking at
1280 x 720 held a 144 FPS cap; p95 frame gaps were 7.5–7.6 ms. After both services
were updated, two fresh hardware-accelerated Chrome clients on the live website
passed host/join, movement, direct WebRTC, diagnostic download and host departure
without runtime errors. Guest samples near the end were 44–47 FPS with both
clients running locally, RTT 20 ms, zero correction distance/drift resets and
0.1 ms prediction replay. This is measured coverage, not a guarantee across all
hardware and networks.

The canonical `/play/index.pck` response passed the exact decompressed-export
hash test, including HEAD behavior; HTML/static chunk hashes and `/api/health`
also passed. **Pages-only publishing is insufficient for game changes:** its
PCK/WASM routes forward to Harbor's assets. The initial Pages-only attempt was
caught and corrected by deploying the matching Harbor assets. Release guidance
now requires both services and the streamed-pack test. Refresh all game tabs.


## November 27 solid props and streamlined challenges (protocol 24)

- Source: `5a5b1d6` on `systems-revamp` (gameplay commits `31e67da`, `94e8fd5`, `53a2baf`), pushed to GitHub.
- Pages: `9ec01793-10da-4dfd-9f8d-9012730ea9c0`.
- Worker: `fae37c4c-372e-4588-8f0c-1f3fc0d20dd5`.
- Rollback pair: Pages https://0bdc38b6.holy-ship.pages.dev and Worker `70cabbb8-80bd-4474-952f-4e2c46a6f10a` (protocol 23). Source before this update: `5e4dbae`.
- Website: https://holy-ship.pages.dev/play/

Removes interaction popups, adds immediate name-only inventory hover, enlarges
the medpack icon, shows green healing/blue eating rings and a draining yellow
totem cooldown ring. Props collide with player feet and totems use correct depth
sorting. Challenges retain normal zoom and automatically finish their objectives.
See [implementation and tests](prop-collision-and-ui.md).

Protocol 24 requires both clients and Harbor to update together because collision
affects prediction. Protocol-23 saves are accepted without adding another pickaxe
kit. Older builds may reject saves rewritten by protocol 24; preserve a prior slot
when testing rollback. No paid service, transport change or new dependency.

Godot parser, HTML5 export, focused UI/collision tests, all 19 standalone puzzle
regressions, 370 totem checks, 26 three-process collision/regrowth checks and the
full 76-check native three-player gameplay scenario passed. Live HTML/JS/PCK
hashes match the export and health reports protocol 24. Two live browser sessions
passed host/join, direct WebRTC, movement/hotbar input and forced relay fallback
without runtime errors. Refresh both devices.

## November 27 small interaction hints (protocol 23)

- Source: `f9ad281`, pushed to `systems-revamp` (hint positioning: `8285139`).
- Pages deployment: https://0bdc38b6.holy-ship.pages.dev
- Worker: `70cabbb8-80bd-4474-952f-4e2c46a6f10a`.
- Small white 12 px `Space - interact` text follows the nearby object; the bottom panel is removed. No networking changes.
- Godot parser, native visual inspection and HTML5 export passed; live HTML/JS/PCK hashes match the final export.
- Rollback to the clearing release: Pages `8f0cd473-dc5a-4c74-bddb-fb1e519d91e2`, Worker `76b0a412-ecf2-4b5a-b916-93944cd087a3`.

## November 27 merged clearing-challenge release (protocol 23)

- Merged source: `86b243fa29a12bc0890130bfe4d0585564d167b8`, pushed to the existing `systems-revamp` branch.
- Pre-merge Git rollback point: `3a26492bd39a856a15e8f7761b0519d3f52daf88`. The merge preserves this as its first parent; no backup branch was created.
- Pages: `8f0cd473-dc5a-4c74-bddb-fb1e519d91e2`.
- Worker: `76b0a412-ecf2-4b5a-b916-93944cd087a3`.
- Previous website pair: Pages `38a9069d-e9d3-4f4a-ad7a-5d37df2707c8`, Worker `8242009b-8fd7-4ed6-8c52-1a9e231e1597` (also protocol 23). Restore both to return to the immediately preceding island/mining playtest.
- Website: https://holy-ship.pages.dev/play/

Includes the generated-island branch, mining, named map markers, and the latest
[clearing challenge and interaction polish](clearing-challenges.md). All 19
minigame regressions, harvesting/catalog/inventory tests, three-player mining
replication, smoothing and HTML5 export passed before release. Live HTML,
JavaScript and decompressed PCK hashes match the merged export; health reports
protocol 23. Two live browser sessions passed host/join, direct WebRTC traffic,
movement/hotbar input and forced relay fallback with no runtime errors.
Refresh both devices before joining. Use a new voyage in an empty
slot for generated islands; old layout-version-1 saves intentionally keep their
old world geometry.

To undo the entire Git merge without rewriting shared history, use
`git revert -m 1 86b243fa29a12bc0890130bfe4d0585564d167b8`, then review/export and
deploy the matching old client/relay pair. The pre-merge branch used protocol
20, so restoring only its client against a protocol-23 relay will not work.
The historical protocol-20 deployment pair remains recorded below. Preserve
old save slots: older builds may reject saves rewritten by newer protocols.

## November 27 mining and item-art playtest (protocol 23)

- Source: `8251233` (map update `26d0743`), local `codex/procedural-islands`.
- Pages: `38a9069d-e9d3-4f4a-ad7a-5d37df2707c8`.
- Worker: `8242009b-8fd7-4ed6-8c52-1a9e231e1597`.
- Rollback pair: Pages `31d6f0c5-e4d9-4b13-b367-f15461c181b7`, Worker `c15e1b91-8447-4179-973d-5d58de2d52c2` (protocol 22). Restore both together.
- Website: https://holy-ship.pages.dev/play/

Includes shared stone mining, palm coconut drops/eating, cropped pixel-art icons
for the entire item catalog, prop/player depth ordering, larger clipped key-search
circles and owner labels on shared map dots. See [implementation and artwork
notes](mining-and-item-art.md). Existing generated island geometry and tree IDs
are preserved. Pickaxes are supplied in the second ship chest; older saves are
upgraded once subject to chest capacity.

Live HTML, JavaScript and decompressed game-pack hashes match the export; health
reports protocol 23. Parser/export, 3,328 resource checks, 12 save checks, 27
mining/marker relay checks, the full 84-check relay scenario, 19 service tests,
responsiveness, survival, world interactions and smoothing passed. Exported
browser WebRTC and fallback checks passed. Refresh both devices before joining.
The deployed website also passed host/join, direct traffic and forced fallback
in two browser sessions without runtime errors.

No merge or GitHub push. `systems-revamp` remains at
`3a26492bd39a856a15e8f7761b0519d3f52daf88`; Pages uses its existing production
channel name while directly uploading this feature branch's files. No new paid
services or dependencies. Protocol 22 may reject saves rewritten by protocol 23;
preserve a prior slot if testing rollback.

## November 27 generated-island forestry playtest (protocol 22)

- Source: `b28d0e4`, local `codex/procedural-islands` branch. No GitHub push or merge; `systems-revamp` remains `3a26492bd39a856a15e8f7761b0519d3f52daf88`.
- Website: https://holy-ship.pages.dev/play/
- Pages: `31d6f0c5-e4d9-4b13-b367-f15461c181b7`.
- Worker: `c15e1b91-8447-4179-973d-5d58de2d52c2`.
- Rollback pair: Pages `4ace7b4b-d39a-4806-a4c3-0a1b84cc0cb9`, Worker `967e3ad0-3039-4a0d-ae0a-70325fb20855` (protocol 20). Restore both together.

Pages' existing production channel is named `systems-revamp`; the direct upload
uses that channel but contains the feature branch's export. It does not update
the Git branch. Live HTML, JavaScript and decompressed PCK hashes match the local
export, and `/api/health` reports protocol 22.
The deployed website also passed a two-browser host/join, direct WebRTC traffic,
movement/hotbar and forced-relay-fallback smoke test without runtime errors.

Refresh both devices and use a new voyage in an empty slot. Old voyages retain
legacy terrain. Do not overwrite a rollback save: protocol 20 may reject saves
rewritten by protocol 22. See [forestry](island-forestry.md) for controls,
artwork provenance, limitations and test evidence. No new paid services or
runtime dependencies were added.

## November 26 map-dot playtest build (protocol 20)

- Source: `89e6b5d` (map change `805bf97`), existing `systems-revamp` branch.
- Pages: `4ace7b4b-d39a-4806-a4c3-0a1b84cc0cb9`.
- Worker: `967e3ad0-3039-4a0d-ae0a-70325fb20855`.
- Rollback pair: Pages `d857bec9-d44f-4166-a0d6-f79021bf75c6`,
  Worker `b46bc34c-85f4-477c-9866-6b0d4b620fa3`.

Map destinations are filled dots. Click/tap once to place, again anywhere inside
the map to clear only your destination, then again to place anew. C no longer
clears it. Four active peers receive distinct red/blue/green/purple colors.
Closed-map distance indicators retain their existing circle presentation.

Validation: clean parser/export; 32 shared-interaction checks (including four
arbitrary peer IDs and delayed clear acknowledgements), 84 responsiveness checks,
smoothing suite, 26 RTC checks, native access host/client, 80 relay gameplay checks,
and 19 service tests pass. Rendered map inspected; final browser host/join,
direct WebRTC and forced fallback passed without runtime errors. Live HTML/JS/PCK
hashes and protocol match the export.

Test harness fixes: relay guests now join this run's explicit room rather than a
possibly stale cached listing; expanded gameplay has a 100-second timeout with
phase diagnostics. An initial browser run timed out awaiting direct traffic; the
diagnostic rerun passed. This is not a guarantee that STUN-only direct connections
work on every network. Keep relay fallback and use the next separate-network
phone/computer playtest to check real latency and jitter. No production smoothing
parameters, transport behavior, dependencies or paid services changed.


## November 26 death-drop follow-up (protocol 20)

- Source: `9cfb6a9`, pushed to the existing `systems-revamp` branch with the
  earlier gameplay commits. No new branch created.
- Pages: `d857bec9-d44f-4166-a0d6-f79021bf75c6`.
- Worker: `b46bc34c-85f4-477c-9866-6b0d4b620fa3`.
- Previous deployment pair: Pages `2278b81d-2780-41a6-8ec0-5bb7760da95f`,
  Worker `0e7cdf3c-5ba8-4f72-a546-81c86edecdc4`.
- Protocol unchanged; refresh clients so every possible host has the new rules.
- Godot parser/export, 84 survival checks and 72 native three-player checks pass.
  The latter verifies guest death loot reaches both observers. Live game file
  hashes and relay protocol match the tested export.

Death drops follow the death surface; nearby-water recovery uses a 120-pixel shore
radius. Open-water supplies are lost; missing keys return to solved pedestals.
See [shared gameplay](shared-gameplay.md#death-drops) for tuning and item lifetime.


## November 26 protocol 20 gameplay polish

Source: `171e343` on `systems-revamp`, following map/text commit `e8fe9b5`.
Local commits only; no GitHub push. Existing free WebRTC/STUN/relay services remain.

- Website: https://holy-ship.pages.dev/play/
- Pages: `2278b81d-2780-41a6-8ec0-5bb7760da95f`.
- Worker: `0e7cdf3c-5ba8-4f72-a546-81c86edecdc4`.
- Protocol: `holy-ship-coop-20`; refresh every device before joining.
- Immediate rollback: restore protocol 19 Pages
  `ae7c93f6-cb00-43eb-a1d5-b6d4f6b62aa5` and Worker
  `b54145a0-8cfa-43b7-bcaa-3861203b4b6b` together. Previous source: `3996e77`.
  Protocol 20 loads older saves; older releases may reject saves rewritten by 20.

Includes constant-size smoothly turning fish attraction and bounded route returns,
remote water-entry splashes, offshore shark arrivals/reengagement, shared totem
supply drops and persisted success cooldowns, held medpacks, map polish and audio.
See [shared gameplay](shared-gameplay.md) and [totems](island-totems.md).

Validation: clean Godot parser and HTML5 export; 218 totem, 20 native totem co-op,
25 world-interaction, 73 survival, 84 responsiveness, 86 fishing, 74 three-player
relay and 19 service checks pass. Rendered totem UI/rewards inspected. Actual web
host/join, direct WebRTC, movement/hotbar and forced fallback passed without runtime
errors. Live protocol and HTML/JS/PCK hashes match the export. A physical-phone,
separate-network playtest remains necessary for feel and real-world connectivity.


## November 26 protocol 19 shared gameplay release

Merged locally into `systems-revamp` at `b762211` from
`codex/gameplay-integration`. Pages production branch is now `systems-revamp`.
The direct upload does not require a GitHub push.

- Website: https://holy-ship.pages.dev/play/
- Pages: `994b21ea-b93f-41ef-b351-e1e07eb0c9b6`.
- Worker: `05ed6d11-2b98-4f82-93a8-4a47f20dc3f8`.
- Protocol: `holy-ship-coop-19`; live HTML/JS/PCK SHA-256 hashes match the export.
- Source backups: `backup/furnace-cooking-before-minigame` at `2c77de2` and
  `backup/systems-revamp-before-gameplay` at `bcbd998`.
- Immediate website rollback: restore protocol 18 Pages
  `236228c0-1a9c-41b9-be4c-be2235797491` and Worker
  `a6c947bd-a6e3-453d-9a1b-5775a84c2fea` together. Refresh every device.
- Protocol 19 accepts protocol 18 saves and recovers old furnace food/fuel.
  Backup branches preserve source, not browser saves; an older release may not
  accept a save rewritten with protocol 19.

See [shared gameplay](shared-gameplay.md) for controls, bounds and trust limits.
Validation: Godot parser/export; 86 fishing, 18 cooking, 15 shared-interaction,
72 survival, 33 character-animation, 9,968 ocean-fish, 82 responsiveness and 26
RTC checks; smoothing suite; 71 host/two-guest relay checks; 19 service tests;
real-browser WebRTC host/join, movement/hotbar and forced relay fallback.


## November 26 protocol 18 follow-up

Deployed source `132b303` from `codex/webrtc-fallback` after host-presentation,
relay-window and diagnostic fixes. `systems-revamp` remains at `bcbd998`.

- Pages: `236228c0-1a9c-41b9-be4c-be2235797491`.
- Worker: `a6c947bd-a6e3-453d-9a1b-5775a84c2fea`.
- Immediate rollback to protocol 17: Pages
  `3fd4d6d6-88a9-4679-9766-471949c07cfd` plus Worker
  `35814ecf-16d0-46e5-85b0-e9653788a94c`.
- To restore the pre-WebRTC protocol 16 build instead: Pages
  `fb363a21-8e5b-4211-94f8-0caa13899ed5` plus Worker
  `8bbc852e-3772-4566-bf49-93185b47feeb`.

Use the Pages rollback menu and `wrangler rollback VERSION` as described below.
Always restore both game and relay together; refresh all clients. Protocol 18
loads older saves, but an older build may not load a save rewritten with 18.
Live protocol and HTML/JS/PCK hashes were verified against the tested export.

## November 26 WebRTC playtest release

Deployed from `codex/webrtc-fallback`, source `bc93e77`, protocol 17.
`systems-revamp` remains on `bcbd9982a82aceafb32b38da900bae913279b47a`.

- Website: https://holy-ship.pages.dev
- Pages deployment: `3fd4d6d6-88a9-4679-9766-471949c07cfd`.
- Worker version: `35814ecf-16d0-46e5-85b0-e9653788a94c`.
- Previous Pages deployment: `fb363a21-8e5b-4211-94f8-0caa13899ed5`.
- Previous Worker version: `8bbc852e-3772-4566-bf49-93185b47feeb`.

Restore the previous Pages deployment through **Workers & Pages → holy-ship →
Deployments → Rollback to this deployment**, and run
`wrangler rollback 8bbc852e-3772-4566-bf49-93185b47feeb` from `online-service`.
Restore both parts together and reload every device. Pages production branch is
now `codex/webrtc-fallback`; return it to `systems-revamp` before publishing future
production builds from that branch. No Git merge was performed.

Live protocol 17 and HTML/JS/PCK hashes were verified against the export.
This release enables only free STUN; no TURN, paid service or dependency was added.
Use a separate voyage save slot for comparison: protocol 17 loads protocol 16
saves, but the older build does not accept a save rewritten with protocol 17.

## November 26 movement replay release

`codex/network-smoothing-replay` is merged into `systems-revamp` for the phone/PC
playtest. Protocol remains 16. The immediately previous production build is:

- Source commit `cb53c5b88a2b037b71a0d4b04df328cadc7c5cd4`, preserved by tag
  `pre-replay-systems-revamp-20261126`.
- Pages deployment `e8c6845f-dd40-4ed4-9601-04f80c266aee`.
- Worker version `7efd9a0f-1150-49ca-9588-0de181d177d0`.

To restore that build, roll Pages back to that deployment using the dashboard
steps below, then run `wrangler rollback 7efd9a0f-1150-49ca-9588-0de181d177d0`
from `online-service`. Refresh every client. Older rollback targets below remain
historical alternatives; they are not the immediately preceding release.

Prepared November 20, 2026 from `better-networking`, protocol 16.
The follow-up UI/traversal release merges `better-networking` into
`systems-revamp` at the user's request. The old `systems-revamp` source commit
`a585b0809f29408b0600d50de0ff31a2fe03d542` is preserved by the Git tag
`pre-networking-systems-revamp-20261120`. Use that tag for an old-source rebuild;
`systems-revamp` now advances with the networking changes.

The immediately preceding protocol-16 playtest can also be restored using:

- Pages deployment `5f35cb9f-31d5-41f8-9e45-ab95804ca00b` (source `3e250dd`).
- Worker version `cee2fc59-8e28-4ee5-ad67-c2bf6812c4ff`.

The UI/traversal changes remain protocol-16 compatible. Refresh all clients to
receive the local presentation fixes. Pages production metadata returns to
`systems-revamp` for the merged release.

## Captured production rollback targets

Before this release, production was:

- Pages project: `holy-ship`.
- Pages deployment: `fbdd3401-411d-407c-be5f-0c194cffcc94`.
- Pages source metadata: branch `systems-revamp`, commit `fc67461`.
- Worker: `holy-ship-harbor`.
- Worker version: `8545407f-e983-48e3-af26-1b68935b97cd` (100% of traffic).

The Git branch and previously deployed commit are separate rollback references.
Both website and relay must be restored together because protocols 15 and 16
cannot join each other's live sessions. The Pages project production branch was
initially switched to `better-networking` for the first playtest and returns to
`systems-revamp` with the merged follow-up.

## Restore the captured production build

1. In Cloudflare, open **Workers & Pages → holy-ship → Deployments**.
2. Find deployment `fbdd3401-411d-407c-be5f-0c194cffcc94`, open its three-dot menu,
   and choose **Rollback to this deployment**.
3. From `online-service/`, restore the matching Worker version:

   ```powershell
   ./node_modules/.bin/wrangler.cmd rollback 8545407f-e983-48e3-af26-1b68935b97cd --message "Restore pre-networking playtest release"
   ```

4. Verify `/api/health` and reload all players' game pages. A page already open
   can retain a different game build until refreshed.
5. Before future releases from the old branch, set the Pages production branch
   back to `systems-revamp`; otherwise a deploy with that branch name is a preview.

No rollback was performed while preparing these instructions. Cloudflare keeps
historical versions subject to its retention limits; the preserved Git tag
provides a source-based rebuild path if a hosted rollback target expires.

Do not clear browser site data merely to refresh the game: that removes locally
stored voyage saves and sailor identity. Protocol-16 code can load protocol-15
saves; an older game may not accept a save subsequently overwritten by protocol
16. Use a separate save slot for the new playtest if you need to retain an old save.

### Protocol 19 playtest polish

Source `d784df2` on local `systems-revamp`: hooked-fish rendering/attachment,
updated teammate cooking visuals, quieter chewing plus confirmed-eat burp,
and moderately faster hunger drain. No wire-format or service-plan change.

- Pages: `ae7c93f6-cb00-43eb-a1d5-b6d4f6b62aa5`.
- Worker: `b54145a0-8cfa-43b7-bcaa-3861203b4b6b`.
- Roll back this polish to Pages `994b21ea-b93f-41ef-b351-e1e07eb0c9b6`
  and Worker `05ed6d11-2b98-4f82-93a8-4a47f20dc3f8`.
- Validation: 86 fishing, 20 galley, 72 survival and 16 world-interaction checks;
  rendered fish/cooking captures, Godot parser/export, live build hashes.
- User manages GitHub pushes; these changes are committed locally only.
