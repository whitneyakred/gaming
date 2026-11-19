# Approved blonde Viking

The only character design in `assets/player/characters/` is the user's selected curly-blonde Viking, matching their six-column reference. Earlier sailor and alternate Viking sheets were removed from the project.

- Walking: `assets/player/characters/viking/walk.png`
- Swimming: `assets/player/characters/viking/swim.png`
- Configuration: `assets/player/characters/viking/appearance.tres`

Both atlases are 1536x1024 with six columns and four rows (down, left, right, up). Walking plays all six frames at 8 fps and rests on column 5 (the flat-footed neutral pose). Swimming plays six gentle stroke poses at 5 fps, with slower stationary treading. Per-column source offsets keep the head centered without modifying the generated PNG. Right-facing runtime frames mirror the left row. Nearest filtering preserves crisp pixels. Water and wake are drawn locally by the game, not baked into the image.

The saved player scene and menu portrait use the approved walking atlas. Godot animation regression suite: 29 checks passed; live deck/swim captures inspected.

## Generation provenance

Built-in imagegen was used. Walking uses the selected six-column character from the previous generation, with alpha background removal (`exec-14389b59-7e77-42be-9bee-a797e3c7edc2.png`). A further background-only attempt was not needed and is not referenced by the project. Some image previews display RGB background colors even where PNG alpha is zero; verify actual alpha and Godot rendering before regenerating a design.

Swim source: `exec-147d3945-b90a-44a5-b76e-5a4149c0087c.png`.

Swim prompt: Create ONLY a swimming sprite sheet matching this EXACT approved character identity and pixel style. Do not redesign him: small cute black eyes with white glint, curly short golden blonde hair, no mouth, no hat, blue tunic brown diagonal leather strap cream fur collar, same small head and body proportions and muted palette. Transparent alpha background, no scenery/background/shadow/water. Canvas 1536x1024, exact 6 columns x 4 rows of equally sized 256x256 cells. Row 1 front/down, row 2 facing left, row 3 facing right, row 4 back/up. Six sequential restrained gentle breaststroke swimming poses across each row: hands near chest, halfway extending forward, reaching forward, gently sweeping outward with bent elbows, returning halfway, near chest. Keep head position IDENTICAL all six frames, same face hair and scale. Head approx 120 pixels wide, positioned centered at x128 y105 in EVERY cell, bottom waterline at y220. Only head shoulders blue sleeves and hands visible; legs and lower torso submerged so not painted. Small gradual arm changes, smooth looping cycle. Coarse blocky pixel sprites matching reference exactly, crisp hard edges. Preserve character, do not substitute a larger-headed different blonde.

`CharacterAppearance.swim_bob_height` controls a visual-only sinusoidal rise/dip (1.4 world pixels), synchronized to each swim stroke. Stationary treading naturally bobs more slowly. Landing restores the fixed standing height; collision and wake positions are unaffected.

## Cannonball and ladder actions

`assets/player/characters/viking/actions.png` is the project-local action atlas,
created with the built-in imagegen tool using the approved walking sheet as its
identity/style reference. The delivered PNG is 1774x887, arranged as four jump
poses above four back-facing climb poses. Explicit source regions and bottom
anchors in `appearance.tres` keep the frames aligned without modifying the PNG.
The walking/swimming sheets remain unchanged. Other appearances can omit action
art and use the existing walk-frame fallback.

The plank sequence is a crouch/takeoff and cannonball (0.55 seconds), splash on
impact, blue translucent underwater dip (0.24 seconds), and resurfacing into the
swimming sheet (0.24 seconds). The dip stays at the world-space impact location
when the ship moves away. Splash art remains a bounded, short-lived draw node.

Ladder traversal aligns to the bottom (0.16 seconds), climbs straight up along
the ship-local ladder centerline (0.8 seconds), then walks sideways onto the
deck (0.3 seconds). Only the last phase restores deck collision and manual input.
The ladder endpoints follow the ship when it rotates or sails. Death cancels the
transition; forced boarding/respawn also clears its state.

In Godot, open `scenes/ship.tscn`, select **SwimAccess** in the **Scene** dock,
and adjust **Jump Seconds**, **Dunk Seconds**, **Surface Seconds**, **Align Seconds**,
**Climb Seconds**, or **Step Seconds** in the **Inspector** to tune pacing.
The player **Character Appearance** resource contains the optional action atlas,
source rectangles, anchors and pixel scale.

Validation: `tests/swim_transition_test.gd` checks the action phases, registered
frames, straight climb/sideways step on rotated boats, death/boarding cancellation,
large frame deltas, splash cleanup, and return to normal atlas/tint. Actual
Compatibility-renderer screenshots were inspected in `output/cannonball-air.png`,
`output/cannonball-dip.png`, `output/ladder-climb.png`, and `output/ladder-step.png`.

### Action-sheet generation prompt

Use case: stylized-concept. Asset: production pixel-art animation atlas for Holy Ship. Reference image is the exact approved curly blonde Viking character and pixel art style; preserve identity, small black eyes white glints, NO beard or hat, blue tunic, cream fur collar, brown belt and diagonal strap, brown boots, proportions and coarse crisp pixel clusters. Create a NEW matching action sheet, transparent background. EXACT 4 columns x 2 rows in a 1024x512 canvas, equal 256x256 cells, NO labels/grid/scenery/ladder/water/shadow. ONE character per cell. Consistent head width approximately 125 source pixels and head registration centered at x128 in each cell. Row 1: LEFT-facing cannonball jumping sequence: cell1 bent-knee crouched anticipation with arms forward; cell2 airborne starting to tuck knees toward chest and wrap hands around shins; cell3 fully tucked round cannonball pose, BOTH knees pulled up tight against chest, BOTH arms visibly hugging shins, boots off ground, chin near knees; cell4 same tightly tucked cannonball angled slightly downward ready for water entry. Row 1 sprites centered with their lowest pixels at y225; do NOT paint water or splash, game handles those. Row 2: BACK-facing vertical ladder climb cycle, back of blonde head visible, no face. Full body with hands raised gripping invisible rungs, alternating arms and bent knees: cell1 left hand high/right knee raised, cell2 pulling body upward right hand reaching, cell3 right hand high/left knee raised, cell4 pulling up left hand reaching. Feet baseline y225, head top about y20. Keep full figures within their own cells and enough transparent padding. Hands must be raised above shoulders, visibly climbing, NOT walking arms by sides. Pixel-game ready, same outfit and hair as reference. True transparent alpha. No background colors, no drop shadows, no extra objects.

## Current appearance

The Viking uses his original artwork for every animation. Color customization
and whole-player multiplayer tints are disabled. The Character menu keeps the
centered preview and player-name field. Saved color preferences are ignored.
Climbing still rotates with the boat, and climb phase/progress remain replicated.
Protocol 15 requires matching builds; existing version 13 and 14 voyage saves load.
