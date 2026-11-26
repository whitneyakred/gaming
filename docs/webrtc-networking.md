# Optional WebRTC fast path

Implemented on `codex/webrtc-fallback`, protocol `holy-ship-coop-17`. Source
`bc93e77` was deployed for playtesting on November 26, 2026; see
[release and rollback](networking-release-rollback.md). Deploy matching game and Worker builds together;
protocol 16 clients cannot join protocol 17 rooms. Existing protocol 16 saves
remain loadable.

## Architecture and cost

The existing authenticated Cloudflare WebSocket remains connected for membership,
signaling, reliable RPCs (including movement input batches, fishing and inventory),
and fallback. Browser builds attempt one WebRTC connection per host/guest pair.
Guests never connect to each other. Snapshots and other RPCs already marked
unreliable use an unordered, zero-retransmit data channel after a bidirectional
ping/pong succeeds. Reliable gameplay semantics are unchanged; this is not a
complete replacement of WebSocket or full-world rollback.

Only `stun:stun.cloudflare.com:3478` is configured. Cloudflare documents STUN as
[free and unlimited](https://developers.cloudflare.com/realtime/turn/faq/).
There is **no TURN**, SFU, paid subscription, credential, or additional dependency.
Existing Workers/Pages/Durable Objects free-tier limits still apply; this does not
promise unlimited free hosting. Signaling uses the existing identity-stamped binary
relay, so no new Worker service or message handler is needed. The protocol variable
changes only to prevent incompatible game builds from mixing.

WebRTC is built into Godot Web exports on computer and phone browsers. Native
desktop builds deliberately retain the relay: adding the native WebRTC extension
is separate work, unnecessary for this browser upgrade. See
[Godot WebRTC support](https://docs.godotengine.org/en/stable/tutorials/networking/webrtc.html).

## Fallback and safety

- Gameplay starts on the relay immediately; connection negotiation never blocks it.
- Negotiation gets 12 seconds. Direct-path ping/pong runs every 500 ms; 2 seconds
  without a reply, a disconnected/failed state, or a send failure closes that path.
  It stays on relay until rejoining, avoiding repeated negotiation storms.
- Missing browser support, disabled WebRTC, restrictive NAT/campus/cellular
  networks, and mixed browser/native crews retain relay connectivity.
- Oversize packets (over 16,000 bytes including headers) and direct-channel backlog
  use the relay. A direct recipient does not also receive the broadcast via relay.
  All-relay crews keep the existing single-upload snapshot broadcast optimization.
- A transport serial per sender and logical stream rejects stale/duplicate packets
  across path changes. Reliable messages are never sent over the unreliable lane.
- Membership and sender identity are derived from the authenticated relay/link.
  Signaling types, sizes and counts are bounded. SDP/candidates are not exported
  in diagnostics. Direct peers can learn network addresses as part of ICE; STUN
  is not an anonymizing relay.
- If the room WebSocket disconnects, the session still ends normally; WebRTC does
  not replace room membership or host availability.
- A silent outage can still cause a visible pause before the 2-second fallback
  deadline. A frozen/backgrounded phone host and weak cellular service remain
  limitations. This transport cannot guarantee smoothness on every connection.

## Diagnostics and disable switch

F3 shows `Motion transport` per peer, direct byte totals and fallback counts.
F6 / **Esc → Export network history** includes a `transport` object per sample,
with the same information but no SDP, ICE addresses, or credentials. RTT probes
already use unreliable RPCs, so after upgrade they measure the selected fast path;
they do not measure reliable-input WebSocket latency.

To disable the fast path for a build, set `network/webrtc_enabled=false` in
`project.godot` and export again. In the editor: **Project → Project Settings**,
enable **Advanced Settings**, search `webrtc_enabled`, and clear the setting.
No server change is needed for this switch within protocol 17.

## Validation and physical-device playtest

`tests/harbor_rtc.gd` checks malformed signaling, identity checks, duplicate/stale
packets across transports, reliable delivery and native fallback. Run it with
Godot `--headless --path . --script res://tests/harbor_rtc.gd -- --settings-test`.

Start the local Worker on port 8790, then run
`node tools/run-webrtc-browser.mjs GODOT_EXE`. This builds a tiny isolated Godot
Web project under `.godot/rtc-browser`, copies the actual production transport,
and tests real browser data channels through the local Worker. It covers direct
delivery, phone viewport/touch emulation, mixed crews, explicit interruption,
initially unusable direct connections, and silent loss after connection.
Results are saved to `.godot/rtc-browser/results.json`. It requires the project's
existing Playwright installation, Chrome and the existing Godot Web templates.

Run `tools/run-network-playtest.mjs` with `--relay-test --harbor-url
http://127.0.0.1:8790 --network-diagnostics` for the full three-player fallback
regression suite. Service tests use `HARBOR_TEST_URL=http://127.0.0.1:8790`.

Before promoting the branch, test physical devices: phone hosting on cellular,
computer joining on Wi-Fi, then reverse roles. Try movement, jumping/swimming,
ladders, fishing, hotbar, chest transfers and rejoining. Confirm `direct` or an
explicit fallback reason, then export diagnostics. Also test a restrictive
network, tab background/resume, and both iPhone/Safari and Android/Chrome where
available. Browser emulation does not establish real mobile/carrier compatibility.

### Local results — November 26, 2026

- Godot transport validation: 20 checks passed; responsiveness: 82 checks passed;
  smoothing suite passed; voyage saves: 15 checks passed.
- Three-player full-game relay regression: 68 checks passed, including rejoining
  and movement/fishing traffic; service tests: 19 passed; TypeScript check passed.
- Real Godot Web data channels passed direct/mixed-crew tests, mobile-emulated
  host and guest roles, explicit fallback, blocked initial delivery, and silent
  established-path loss. No browser/Godot runtime errors in the transport suite.
- Complete HTML5 export and headless startup passed. Local full-game browser
  checks exercised host/join, direct snapshots, movement, hotbar changes and
  fallback after closing the direct connection. Browser rendering used software
  WebGL; these results are correctness checks, not FPS or WAN latency benchmarks.
- Physical phone/cellular and Safari validation remain manual release checks.
