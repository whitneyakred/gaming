# First sailor character

The first character is a fictional sailor: brown curls, cream cap with teal band,
teal jacket, coral neckerchief, navy trousers and brown boots. It is not yet based
on a teammate's likeness. The existing menu profile portrait and gameplay player
use this sailor. The six-character chooser and other five designs are future work.

## Assets and animation

- `assets/player/characters/sailor/walk.png`: generated transparent 4-by-4 atlas.
- `assets/player/characters/sailor/swim.png`: matching cleaned swimming atlas.
- `assets/player/characters/sailor/appearance.tres`: replaceable appearance resource.

Both atlases have rows down, left, right, up. Each row has four poses. Walking
holds column zero when stopped; swimming uses a slower tread cycle when stopped.
Animation uses movement relative to the deck and converts direction to world
space, so sailing alone does not play walking and turning the ship does not
reverse the character's facing. Swimming replaces the old cropped portrait.
Held items follow facing on land and are hidden while swimming so arms can paddle.
Fishing retains its existing gameplay and held-rod presentation; tool swings and
dedicated fishing character frames have not been added.

In the Godot **FileSystem** dock, open `scenes/player.tscn`, select **Player** in
the **Scene** dock, and expand **Character Appearance** in the **Inspector**.
The resource controls atlases, animation rates, world size and foot/water anchors.
Create a separate resource with the same atlas layout for each later character.

Validation: `tests/character_animation.gd` checks direction, animation cycles,
stationary tread, rotated decks, shore/boarding transitions and fishing coexistence.
Run with `--capture` without `--headless` for in-game deck/swim screenshots.

## Generation prompts

Created with the built-in image_gen tool, not the CLI. The ship and old player
art were inspected before generation. Original generated files remain in Codex's
generated_images folder; the two selected PNGs above are project-local copies.

### Walking sheet

Production game sprite sheet, one cute adult sailor character for Holy Ship,
cozy top-down 2D pixel-art nautical survival game. EXACT 4 columns by 4 rows
evenly spaced identical square cells, 1024x1024 square canvas transparent
background. Each of the 16 cells is 256x256. Character same size in EVERY cell,
feet anchored at 80% height, centered at 50% cell width, no overlapping cells.
Character occupies about 65% cell height. Simple chunky authentic 32px pixel-art
sprite design enlarged crisply, dark charcoal outlines, limited muted palette,
no smooth rendering. Cute big head small sturdy body, warm tan skin, fluffy dark
brown hair, small cream sailor cap with teal band, teal sea-green jacket over
ivory shirt, short coral neckerchief, dark navy trousers and small brown boots.
Friendly two dark dot eyes, tiny nose, no beard. Empty hands. Match warm weathered
beige wood ship and chunky pixel inventory art. High slightly overhead RPG camera
(see top of cap). ROW 1 faces DOWN toward viewer. ROW 2 faces LEFT. ROW 3 faces
RIGHT. ROW 4 faces UP away from viewer, back of head no face. Each row: COLUMN 1
stationary idle both feet together, COLUMN 2 walk left-foot-forward
right-arm-forward, COLUMN 3 passing pose feet near center slight body rise,
COLUMN 4 walk right-foot-forward left-arm-forward. Four distinct anatomically
consistent animation poses per row, never multiple characters per cell. Fixed
head size, clothes and registration throughout. No grid lines, text, numbers,
shadows on floor, scenery, weapons, accessories in hands or watermark. True
transparency between sprites. This is ONE usable sprite atlas not a character
illustration.

### Swimming sheet (walking atlas as reference)

Create the matching SWIMMING animation sprite atlas for EXACTLY the sailor in
the previous walking sheet. Same face, brown curls, cream cap teal band, coral
neckerchief teal jacket, same chunky pixel clusters, dark outlines and palette.
Single transparent square canvas with EXACT 4 columns and 4 rows equal square
cells. Same head scale as walking sheet, consistent registration within all
cells. Only head, shoulders and arms visible above water; NO legs, boots or
entire torso. Each sprite centered horizontally and in its cell, shoulders at
about 65% cell height. ROW1 swimming DOWN toward viewer. ROW2 swimming LEFT.
ROW3 swimming RIGHT. ROW4 swimming UP away, back of cap and hair visible no
face. Four sequential looping breaststroke frames in each row: arms reaching
ahead, arms spreading outward, arms sweeping back, arms returning close. Pose
differences must be visible yet silhouette and head remain registered. Include
a few chunky pale turquoise foam pixels around shoulders and hands, small
transparent elliptical ripple broken into pixel segments, no opaque water tile,
no background. Cute calm determined expression. Match previous sprite sheet art
exactly. No labels, letters, grid lines, scenery, weapons, or extra characters.
This is a game-ready 4x4 swimming sprite sheet not concept art.

### Swimming cleanup

Clean the immediately preceding swimming sprite sheet. Keep the exact 4x4
layout, character identity, scale, poses and registration unchanged. Remove ALL
stray detached speckles, streaks and wispy pixels below and between the 16
swimmers. Remove the messy splash shadows beneath each swimmer. Each swimmer
should have only one small crisp contiguous pixel-art turquoise ripple
immediately around shoulders and arms, not detached particles. Everything else
must be fully transparent. Crisp binary-alpha edges, no semitransparent haze or
antialiasing. Preserve the 16 cute sailor swimming poses exactly, one in each
equal grid cell, no text or grid.
