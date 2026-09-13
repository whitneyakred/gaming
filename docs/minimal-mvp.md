# Minimal game starting point

Open project.godot in Godot 4.7.2 and press F5. Move with WASD or arrow keys.
The ship stays centered. The player moves around the deck and cannot cross its outer boundary.

## Three scenes, one script

- scenes/main.tscn: ship instance and fixed camera. The project background color supplies the blue ocean.
- scenes/ship.tscn: one ship Sprite2D, a deck boundary collider, and an instance of the player scene.
- scenes/player.tscn: a CharacterBody2D, a static Viking Sprite2D, and a circular feet collider.
- scripts/player.gd: the only gameplay script. It reads input, sets velocity, and calls move_and_slide().
- assets/ship.png and assets/player_viking.png: transparent PNG artwork. No shaders or animation are needed.

The wheel, lanterns, and grates are painted into the ship image; they are not interactive nodes.

## Inspect it in Godot

1. In the FileSystem dock, double-click scenes/main.tscn to see the assembled game.
2. Double-click scenes/ship.tscn to inspect the ship artwork, DeckBoundary, and Player instance in the Scene dock.
3. Double-click scenes/player.tscn and select Player. Change Walk Speed in the Inspector to adjust movement speed.
4. Open scripts/player.gd to read the movement code. Input.get_vector reads the four movement actions; velocity sets speed; move_and_slide handles movement and collision.
5. To see the key bindings, choose Project > Project Settings, then the Input Map tab.
6. To edit the walkable boundary, open scenes/ship.tscn and select DeckBoundary/CollisionPolygon2D. Edit its vertices in the 2D viewport. Keep Build Mode set to Segments so only the perimeter blocks movement.

Press F8 to stop and F5 to run again.

No sailing, stations, survival, swimming, procedural ocean, HUD, or networking is included.
Use separate feature branches and follow docs/team-contract.md for review requirements.

## What each file is for

| File | Purpose |
| --- | --- |
| project.godot | Godot project settings: starting scene, controls, window size, and renderer. Open this to import the project. |
| scenes/main.tscn | Assembles the ship and camera. This is the scene that runs with F5. |
| scenes/ship.tscn | Ship artwork, deck boundary collision, and player instance. |
| scenes/player.tscn | Static player sprite and circular collider, with the movement script attached. |
| scripts/player.gd | The only gameplay script: input, movement speed, and collision-aware movement. |
| scripts/player.gd.uid | Godot-generated stable script identifier. Keep and commit it; do not edit it manually. |
| assets/ship.png | Transparent ship artwork. |
| assets/player_viking.png | Transparent, static player artwork. |
| assets/*.png.import | Godot's import settings and resource identities for the images. Keep and commit these alongside the PNGs. |
| icon.svg | Project icon referenced by project.godot. |
| icon.svg.import | Godot's import settings for the project icon. |
| docs/minimal-mvp.md | This guide: how to run, understand, and edit the MVP. |
| docs/team-contract.md | Existing team agreement and pull-request workflow. Not gameplay code. |
| README.md | Existing repository title and team identification, displayed on GitHub. |
| AGENTS.md | Instructions for coding assistants working in this repository. Not loaded by the game. |
| .gitignore | Keeps generated caches, builds, and local editor files out of Git. |
| .gitattributes | Normalizes text-file line endings across teammates' computers. |
| .editorconfig | Shared text-editor formatting settings. |

Godot also creates a hidden .godot folder for imported caches and local editor state.
It is ignored by Git and regenerated when needed; leave it alone during normal work.
The hidden .git folder holds repository history and the GitHub connection. Do not delete it.

The art-generation prompts and optional Web export preset have been removed.
There are no animation or shader files. The Compatibility renderer remains enabled;
a Web export preset can be added later through Project > Export.
