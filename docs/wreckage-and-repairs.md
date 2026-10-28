# Floating wood and ship repairs

Walk off the existing left plank and swim close to floating wood to collect it
automatically. Use the existing ladder to return aboard. The HUD counts collected
wood separately from inventory. Planks are lightweight drawn placeholders.

The first hole appears after 40 seconds on the sailing map. Further attempts occur
every 35–60 seconds, with at most three holes. Walk near a hole on deck: its outline
lights up, and E or Space repairs it immediately. Repairs currently use unlimited
wood, even with zero pickups, and do not reduce the collection tally. Holes do not
yet cause flooding, sinking, or speed loss. Damage generation stops during rowboat
travel and island scenes.

`FloatingWreckage` generates a bounded grid around the camera. Cell coordinates
determine plank positions; land, shoreline margins, and the current hull are
excluded. Collected cells, the tally, holes, and damage countdown live in
`VoyageState`, so visiting islands does not reset them. Restarting the game or
resetting the voyage does. There is no disk save added here.

Tune spacing/pickup radius on Ship/FloatingWreckage and damage intervals, maximum
holes, repair distance, and deck positions on Ship/ShipRepairs in the Inspector.
This branch also includes the existing swimming implementation because its
better-interactions base predates swimming.

Validation: run `tests/wreckage_repairs.gd` and `tests/swimming_integration.gd`
with Godot's headless script runner. For a visual playtest, press F5, lower the
anchor, swim to wood, return at the ladder, wait for a hole, then press E or Space
beside it. Check that station interaction still works away from holes.
