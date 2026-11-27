# Networking playtest release and rollback

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
