# Ambient ocean fish

Six animated species inhabit deterministic 480-unit ocean cells. Every fish has
an independent seeded route, size, cruising speed and acceleration/gliding rhythm.
Routes are baked once and sampled by distance travelled, so tight bends do not
make fish tread water. There is no leader attraction or shared formation.
Ocean counts are 1–2 fish per cell, about half the previous population. The title
screen has 12 independently roaming fish: two of each species, distributed
across a loose 6x2 grid with small wandering areas to prevent color clumps.
The ray-like violet flatfish uses a 22-unit base length in both menu and gameplay.
Fish are decorative; they do not add new catches, hitboxes or gameplay rewards.

`OceanFish` keeps only a 5x5 cell window (125-instance gameplay budget, 225 in the menu). All fish
share one atlas, material and MultiMesh. Tail phase is integrated locally from
measured movement in body-lengths/second, capped at five frames/second, and freezes
when still. The shader selects the frame without restarting phase on speed changes;
there are no individual fish nodes, physics bodies, timers or particles.
Each cell's full roaming envelope, including 180 units of evasion, is checked against coastline polygons once
when a cell is loaded. It draws above the ocean and below islands and boats.
Schools fade in on local loading, slowly fade during shared dive cycles, and
fade outside the view before their cells are recycled. Cache size stays fixed
during indefinite travel. Very wide views deliberately fade beyond 780 units
plus a 130-unit margin to preserve the fixed budget.

Multiplayer reuses the existing world seed and snapshot `time` field. The same
seed, cell and time produce the same fish transforms, independent of frame rate
or which cells other peers visit. Clients initialize their clock on the first
snapshot and gently correct drift afterward. Normal network delay can create a
small positional lag; there are no fish RPCs or additional snapshot fields.
Fish smoothly evade nearby swimmers, the main boat and the visible rowboat using
their existing replicated transforms. Evasion retains displacement and velocity,
with acceleration limits. Fish hold their displacement while the return corridor
is blocked, wait three seconds after danger clears, then drift back at at most
12 units/second. Their render positions also have a speed cap. Escape state keeps
advancing through fade cycles, preventing reappearance from resetting the motion.
Network interpolation and local escape history can
cause small differences in transient escape motion, without persistent drift.
Tail frames, alpha and rendering are local. Reduced-motion preferences freeze
tail animation but do not change shared gameplay fish positions.

Inspector settings on `OceanFish`: `max_fish`, `arrival_seconds`, `menu_mode`,
`menu_center`, `menu_extent`. Species counts/sizes and cruising speeds live in `FishSchool`.
Underwater strength lives in `shaders/fish_water.gdshader`.

Validation: run Godot with `--headless --path . --script tests/ocean_fish.gd`.
For rendered title/ocean/species previews run
`--path . --script tools/preview_ocean_fish.gd`; files go to
`output/fish-preview/`. Network smoke tests also verify guest seed and clock.
For a focused network check, launch three processes running
`--headless --path . --script tests/network_smoke.gd -- --ambient-fish-test`
with `--test-host --crew-profile fish-host`, `--test-alpha --crew-profile fish-alpha`
and `--test-beta --crew-profile fish-beta`, respectively. They use localhost UDP
24678 and compare independently reconstructed transforms against a host sample.
