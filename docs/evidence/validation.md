# Local checkpoint validation — November 19, 2026

Environment: Windows, Godot 4.7.2 stable, Node 24.19.0. Branch: `checkpoint-readiness`, based on `fc674619b5cde69a45305d00767dd8ee11b86782`, with uncommitted readiness changes. This is a local working-tree result, not a CI run or tagged-release certification.

| Check | Observed result |
|---|---|
| Godot editor import/parser | Exit 0; no SCRIPT ERROR, Parse Error or Compile Error after rerun with normal editor-settings access |
| Headless project startup, 120 frames | Completed; no script error observed |
| Pause | 0 failures |
| Survival | 71 checks, 0 failures |
| Grill | 21 checks, 0 failures |
| Paradise journey | 493 checks, 0 failures |
| Voyage saves | 15 checks, 0 failures |
| Sail rotation | 6 checks passed |
| Menu flow after stale prop-selection fix | 62 checks, 0 failures |
| Three-client local co-op after island-count assertion fix | Host 28, Alpha 16, Beta 11 checks; all 0 failures. Local ENet, not deployed browser relay |
| Harbor degradation crew-menu test | PASS; displays error, clears busy state, remains offline |
| Harbor production-handler dependency test | 1 passing test |
| Same test with recovery removed in memory | Exit 1: injected dependency exception escaped; recovery restored gives exit 0 |
| Harbor TypeScript static check | `npm --prefix online-service run check`, exit 0 |
| Live synthetic discovery SLO | [20/20 good](harbor-slo.json); proposed target met for this short sample only |
| Traceability checker | Local files/headings resolve; 48 cited use-case IDs represented |
| Git whitespace check | `git diff --check`, passed |
| Browser and Windows export | Existing release preparation script completed successfully; [artifact hashes](build-manifest.json) identify the local candidate |
| Harbor deployment dry run | Wrangler completed with exit 0; no deployment performed |

Packaged startup and graceful Quit passed with exit 0 and no script/runtime errors, using the matching Godot console runtime with `--main-pack builds/holy-ship-harbor-windows/HolyShip.pck --script tools/export_smoke.gd -- --settings-test`. This replaces an abrupt `--quit-after` experiment that retained menu-audio resources at forced shutdown. The exported executable still needs the normal interactive rehearsal; neither the build nor its pack has been published or tagged as v0.2.0.

## Repaired regressions and coverage limits

All four previously failing suites now pass locally:

| Suite | Current result | Repair |
|---|---|---|
| Sailing integration | 18 checks, 0 failures | Load gameplay after autoloads; exercise current sail/helm/anchor interactions instead of obsolete cooking/rowing assumptions |
| Wind integration | 0 failures | Load suite after autoloads; use the current TextureRect wind indicator through its Control base |
| Station camera | 0 failures | Check shared grill panel behavior instead of the removed exclusive cooking-station API |
| Island minigames | 0 failures | Stabilize guard-facing setup during detection; include four in-world quest islands and verify each original challenge remains |
| Swimming transitions | 47 checks, 0 failures | Existing dedicated test passed; covers plank/ladder travel replacing the old rowboat integration assertions |

The changed tests retain failure assertions rather than bypassing them. The guard test still checks detection, return to dock and time penalty. Shared grill coverage also remains in the separate 21-check grill suite. The old rowboat main-flow specification remains historical and unresolved for full use-case verification; passing the current demo behavior does not verify retired rowboat extensions.

The repaired suites, swimming regression and three-client co-op regression are included in the blocking Godot CI job. Local results do not claim a completed GitHub run or exhaustive use-case extension coverage. Two earlier fixes also remain passing: the menu selects actual SharkVisual children; co-op includes the four quest islands. The three-client local run requires normal local-network access.

## Reproduction

From the repository root, use the installed Godot console executable in place of `godot`:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/pause_game.gd -- --settings-test
godot --headless --path . --script res://tests/harbor_degradation.gd -- --settings-test
node --test online-service/test/degradation.test.mjs
npm --prefix online-service run check
node tools/check-traceability.mjs
```

The Godot CI job lists the remaining selected suite launchers. Existing full-suite runtime failures must be resolved or explicitly presented as gaps; they are not invalidated by a green selected-subset job.
