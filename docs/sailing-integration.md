# Manual sailing and the island trip

The single-player ship uses the pixel-art ship, ocean, island, rowboat, and cooking
station from `main`. Travel is now controlled by the sail and helm. Cooking and
the island game remain part of the same playable loop.

## Play in Godot

1. Open `project.godot`, then click the **Run Project** button (the play triangle
   at the top right) or press **F5**. F6 runs only the currently open scene.
2. Walk with **WASD** or the arrow keys. Approach the sail across the center of
   the deck and press **E** to use it.
3. Press **W** or **S** to cycle through stowed, one-third, two-thirds, and full
   sail. Hold **A/D** to trim. The arrow at the top right shows where the wind
   blows; wind pushing the sail forward provides speed. Press **E** to leave.
4. Approach the wheel near the stern and press **E**. Hold **A/D** to steer,
   then press **E** to leave. The rudder keeps its setting unless centered.
5. After sailing 660 pixels, an island appears ahead. Sail into the yellow
   docking circle. The ship aligns beside the island, stows the sail, and anchors.
6. Walk to the stern and press **E** to play the rowboat cutscene. Collect the
   coconuts in the island game and return to its rowboat before time expires.
7. After the return cutscene, raise the sail again to depart. The ship waits
   for your input; it no longer leaves automatically.

The kitchen still opens with **E** nearby. Completing or cancelling cooking
releases the player so they can walk and operate the sailing stations again.
Only one station can control the player at a time.

## Validation

Using your Godot executable in place of `godot`:

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/sailing_integration.gd
```

The integration test exercises station input, sail propulsion, helm turning,
cooking ownership/cancellation/completion/collection, stationary world-space
land, docking, stern interaction, outbound rowing, island completion, return
rowing, the return camera, and manual departure. It accelerates time and the
encounter distances to keep the run short. It does not replace a human playtest
of steering feel or the mouse-driven cooking minigame.
