# Durable project instructions

- This is **Holy Ship**, a top-down 2D Godot 4 sailing/survival game with solo and co-op play. Co-op was confirmed for the December 4, 2026 MVP demo on November 19.
- Use GDScript, not C#. Keep the Compatibility renderer and HTML5/Web export compatibility.
- Preserve solo play while maintaining the existing co-op architecture; additional networking scope still requires a request.
- Keep each commit/pull request focused on one feature.
- Treat the boat as a shared moving home and keep crew responsibilities separated into reusable station-oriented systems.
- Favor reusable scenes, signals, typed GDScript, and Inspector-configurable exported properties.
- The ocean must support indefinite travel in any horizontal direction through deterministic/recycled chunks; do not build one enormous water mesh.
- Use lightweight placeholder assets until the core game is fun and keep them easy to replace.
- Preserve a narrow playable milestone and resist large inventory, crafting, or progression systems unless requested.
- Validate changes with a Godot command-line parser/startup run whenever an executable is available.
- Explain manual Godot editor steps using exact menu and button names for a beginner.
- Validate untrusted network messages as objects with the expected field types before reading properties; malformed traffic must not break other players' sessions. Source: [VoyageRoom review](docs/room-error-review.md). This review-derived rule still requires a reviewed, merged PR for Checkpoint 3 evidence.
- Never remove a `Co-Authored-By` trailer. Do not add dependencies without explaining their purpose, license, maintenance and existing alternatives in the PR.
