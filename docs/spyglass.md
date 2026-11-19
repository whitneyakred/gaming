# Spyglass

Each new voyage grants a fishing rod and one spyglass (normally hotbar slots 1
and 2). Select the spyglass with **2**, the mouse wheel, or its hotbar slot.
Hold **left mouse button** over the world to smoothly zoom out; move the mouse
toward an edge to scout that direction. Release to restore the regular camera.
The HUD remains the same size. Opening a chest, map, pause, switching tools,
using a station, swimming, or losing window focus cancels scouting.

The spyglass is a normal inventory item: it can be stored, dropped, and picked
up. It is not re-granted on an island visit or after storage/drop. Starting a
new voyage resets the starter grant. The same controller works on islands.

In Godot open `scenes/inventory/inventory_system.tscn` and select **Spyglass**.
The Inspector exposes **Zoom Multiplier** (default 0.6, about 1.67 times the
normal visible width) **Mouse Sensitivity** (default 3x), **Zoom Seconds** (default 0.65), and **Max Pan Distance** (default 450 world pixels from
the player, bounded radially even at corners). The controller uses a temporary
Camera2D; normal ship/station tracking keeps its own camera and is restored on
release. Mouse direction is measured from the viewport center to avoid feedback
from camera motion.

The brass pixel icon extends the existing SVG item-icon style.

Validation:

```
godot --headless --path . res://tests/spyglass_test.tscn -- --settings-test
godot --path . res://tests/spyglass_test.tscn -- --settings-test --capture
```

The optional capture is saved to `.godot/spyglass-view.png`.
