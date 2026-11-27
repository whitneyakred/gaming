# Walking presentation and island camera follow

November 27, 2026, `systems-revamp`.

Local crew and private minigame avatars now interpolate the last two confirmed physics positions for rendering. Collision movement and host authority still run at the fixed physics rate. Remote crew retain the existing network smoothing; they are not interpolated twice. Replay corrections shift both walking samples together, so even zero-error acknowledgements do not restart the walking phase. Teleports, boarding, respawns and station control reset/skip walking interpolation.

Guest ship/remote-crew snapshot playback now advances once per rendered frame instead of once per physics tick. Rendering runs in a defined order: snapshot playback, player presentation, shore/challenge target, camera. The camera explicitly updates its scroll after the final target. Island challenges use the same exponential follow response as ordinary walking ashore instead of hard-locking to the avatar every frame; station focus and vignette are cleared while in the challenge.

## Checks

- Godot 4.7.2 editor import/parser and Web release export.
- Walking sampler: 30, 60, 120 and 144 FPS, constant 60 Hz physics. Maximum steady-state displacement error below 0.00011 px. Tests cover replay phase continuity, collision independence, teleport/boarding resets, rotating decks and co-op private avatars.
- Existing network smoothing and station-camera integration: zero failures.
- Network responsiveness: 86 checks; character animation: 33 checks; island totems: 370 checks; all passed.
- Three actual ENet peers: host 33, Alpha 23, Beta 20 checks, all passed.
- Actual island host/guest: 12 host and 8 guest checks, all passed.
- Godot Web transport in Chrome against a local Harbor: direct WebRTC, mobile host/guest emulation, mixed relay crew, mid-session fallback, blocked path and silent path loss all passed without runtime errors.
- Backend TypeScript check passed; no backend code or session protocol change.

## Render measurement

`tests/render_performance.gd` measures wall-clock gaps with `Time.get_ticks_usec()`, not Godot's smoothed simulation delta. Five seconds per case after a one-second warmup, 1280 x 720, Compatibility/OpenGL, NVIDIA RTX 4060 Laptop GPU, native Godot capped at 144 FPS.

| Case | Average frame ms | p95 ms | Maximum ms |
| --- | ---: | ---: | ---: |
| Deck walking | 6.944 | 7.511 | 7.958 |
| Shore walking | 6.944 | 7.593 | 7.925 |
| Island minigame | 6.944 | 7.608 | 8.626 |

The extra walking sampler measured about 0.75 microseconds per call in a 100,000-call microbenchmark. These are local machine samples, not guarantees for mobile hardware, browser rendering or arbitrary internet latency. Network interruption remains bounded by the existing snapshot buffer; it cannot make missing packets arrive sooner.

Run the suites with `Godot --headless --path . --script res://tests/walking_render.gd -- --settings-test` and the corresponding existing test runners. The rendered measurement requires a graphical run: `Godot --path . --script res://tests/render_performance.gd --max-fps 144 -- --settings-test`. Reports/screenshots are written under `output/` and excluded from game exports.
