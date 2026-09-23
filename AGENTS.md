# Durable project instructions

- This is **Man the Ship**, a top-down 2D Godot 4 cooperative sailing/survival game currently prototyped as single-player.
- Use GDScript, not C#. Keep the Compatibility renderer and HTML5/Web export compatibility.
- Architect gameplay for eventual four-player multiplayer, but do not add networking until the local boat/station loop is stable.
- Treat the boat as a shared moving home and keep crew responsibilities separated into reusable station-oriented systems.
- Favor reusable scenes, signals, typed GDScript, and Inspector-configurable exported properties.
- The ocean must support indefinite travel in any horizontal direction through deterministic/recycled chunks; do not build one enormous water mesh.
- Use lightweight placeholder assets until the core game is fun and keep them easy to replace.
- Preserve a narrow playable milestone and resist large inventory, crafting, or progression systems unless requested.
- Validate changes with a Godot command-line parser/startup run whenever an executable is available.
- Explain manual Godot editor steps using exact menu and button names for a beginner.
