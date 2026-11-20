# Networking playtest release and rollback

Prepared November 20, 2026 from `better-networking`, protocol 16.
The `systems-revamp` Git branch remains at
`a585b0809f29408b0600d50de0ff31a2fe03d542` with the prior networking implementation.
Networking changes are committed separately on `better-networking`; switching
branches does not carry uncommitted networking changes into `systems-revamp`.

## Captured production rollback targets

Before this release, production was:

- Pages project: `holy-ship`.
- Pages deployment: `fbdd3401-411d-407c-be5f-0c194cffcc94`.
- Pages source metadata: branch `systems-revamp`, commit `fc67461`.
- Worker: `holy-ship-harbor`.
- Worker version: `8545407f-e983-48e3-af26-1b68935b97cd` (100% of traffic).

The Git branch and previously deployed commit are separate rollback references.
Both website and relay must be restored together because protocols 15 and 16
cannot join each other's live sessions. The Pages project production branch is
being switched to `better-networking` for this release; this is Cloudflare
deployment metadata, not a modification to the `systems-revamp` Git branch.

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
historical versions subject to its retention limits; the unchanged Git branch
provides a source-based rebuild path if a hosted rollback target expires.

Do not clear browser site data merely to refresh the game: that removes locally
stored voyage saves and sailor identity. Protocol-16 code can load protocol-15
saves; an older game may not accept a save subsequently overwritten by protocol
16. Use a separate save slot for the new playtest if you need to retain an old save.
