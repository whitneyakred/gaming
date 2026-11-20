# Networking playtest release and rollback

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
