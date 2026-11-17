# November 2026 title artwork

The reference screenshot is inspiration only; it is not shipped or displayed.
Six separate assets were generated with OpenAI image generation, with the reference
provided for composition, palette and pixel-art direction. Original PNGs are kept
intact; AtlasTexture regions remove transparent padding at runtime.

| File | Generation brief |
| --- | --- |
| title_wordmark.png | Transparent standalone two-line Holy Ship! lettering: ivory and ice-blue Holy, coral-pink Ship!, dark plum pixel outline and dimensional shadow. No ship or scenery. |
| title_wreck.png | Transparent top-down vertical wooden ship wreck, pointed bow, planked tan deck, ladder and hatch, broken flooded starboard/stern with pixel foam; no lettering or background. |
| menu_plank.png | Transparent long horizontal weathered wooden button plank with blank ivory parchment inset, coral stitch border and dark pixel shadow; no baked-in text. |
| title_ocean.png | Full-frame indigo/periwinkle pixel ocean with subtle cyan marks and dithered wave texture; no ship, text, buttons or creatures. |
| title_shark.png | Transparent standalone top-down dark indigo shark with angular fins and pale highlights; readable small pixel sprite. |
| title_props.png | Transparent evenly separated 2-by-2 atlas: life ring, barrel, crate, driftwood plank; consistent top-down pixel art and plum outlines. |

Common direction: match the supplied reference's restrained indigo, tan, ivory and
coral palette, deliberate pixel clusters, clean silhouette and no photorealism.
Transparent generation was enabled for everything except the ocean. Each element
is separately positioned and animated in title_screen.gd; button text is live UI.
The old menu art is retained for team history and reuse.

Pixelify Sans is from Google Fonts (ofl/pixelifysans); its SIL Open Font License is
included in assets/fonts/OFL.txt and shipped with the website font.

The title supports proportional resizing and reduced motion. Settings, profile,
crew browser, pause, and fishing panel use the matching parchment/plum theme.
Hover/press feedback uses short synthesized wood-and-water sounds at the existing
UI volume; no downloaded sound recording is required.

## Living water and wreck revision

Generated with the built-in image tool, using the supplied full-boat and shark
screenshots only as references. Saved assets:
- `title_wreck_wood.png`: transparent wood-only wreck, broken deck, exposed beams,
  detached stern. No painted water. The shader softens only faint alpha halos.
- `shark_swim.png`: six frames in a regular 3-by-2 atlas; nose up, successive
  left/center/right tail bends, consistent top-down indigo pixel styling.

Wreck prompt: Standalone top-down pixel-art wreck inspired by the reference boat;
tall narrow pointed bow, pale tan planks, plum outlines, port ladder and hatch.
Split diagonally across the lower middle into jagged wood, missing lower starboard
deck, exposed beams, detached slightly turned stern. Transparent gaps; no water,
foam, blue paint, text or background. Entire wreck visible with modest padding.

Shark prompt: Exactly six equal frames in a regular three-column/two-row transparent
sheet. Same indigo top-down pixel shark, all noses up, tail left/slightly-left/
center/right/slightly-right/center. Consistent head size and centers, small fin
changes, slate highlights, crisp plum outlines, transparent gutters. No water,
foam, wakes, text or drawn grid. Each shark contained within its cell.

`sea_surface.gdshaderinc` is shared between the title, waterline, and gameplay.
The hull stays fixed. Animated foam and water tint reveal submerged wood; the
same water samples continue across the cutout gaps. Five sharks have different
patrol radii, rates, phases and tail cadence; wakes follow their fin positions.
Reduced motion freezes the surface and shark animation. Gameplay samples the
surface in world coordinates on a camera-sized rectangle with mirrored repeating
texture coordinates, retaining unlimited travel without a huge ocean mesh.

## Fin, fishing, and sailing polish

Built-in image generation added two separate transparent assets:
- `shark_swim_fins.png`: twelve evenly spaced swim poses in a four-column,
  three-row sheet. Each has an explicit raised triangular dorsal fin on its back,
  slate highlights and a plum shadow, separate from its side fins. Prompt asked
  for stable nose-up bodies, gentle left/center/right intermediate tail poses,
  crisp indigo pixel art, equal cells and no water, wakes, labels or grid lines.
  Playback is approximately 2.4–2.7 seconds per complete swim cycle.
- `fishing_panel.png`: blank wide wooden instrument plaque, cream parchment,
  brass rivets, rope corners, small fish/reel border carvings. Prompt specified
  a 3:1 nautical pixel-art HUD with muted tan/ivory/coral, clear central space,
  transparency and no baked-in words, meters, numbers or needles.

Title wreck dimensions are 20% smaller, with smaller floating props and sharks;
the logo and buttons retain their previous sizes. Fishing live indicators are
rendered separately over the panel; only HOLD/EASE remain during reeling.
Ship wake uses at most 80 world-space samples, expires after five seconds, and
clears across teleports. Map heading comes from the actual ship transform.

Validation: 61 menu checks, 84 fishing checks, and 10 presentation checks including
world-space wake persistence/expiry, four map headings and contact with a
procedurally generated coast without the removed grounding banner. The older
island_collision.gd harness predates the generated layout (including SkullRock
and fixed launch offsets); it needs a separate migration before it can validate
all current island layouts reliably.

Obsolete title assets remain in source control but are excluded from release
exports; the final Web pack is about 19.8 MiB, below the 25 MiB hosting limit.

## Upright fins, smooth wake, and stack splitting

`shark_swim_upright.png` was generated with the built-in image tool from the user's
original shark reference. Prompt: twelve aligned top-down indigo pixel shark poses
in a 4-by-3 transparent grid, nose up, gentle intermediate tail bends, a narrow
upright swept-back dorsal fin centered on the spine (no sideways-flopped triangle),
slate leading edge and plum shadows. No painted foam, water, text or grid.
`SharkVisual` shares the generated frames and continuously animated fin bubbles
between title and gameplay; gameplay targeting and damage are unchanged.

The fishing fight panel no longer draws Hold/Ease controls, the target fish, or
the red dot above the tension needle. Boat foam samples now have stable IDs,
smooth subpixel strokes, smoothed intensity, and a live connection to the stern.
Right-click picks one item onto the cursor; Shift-right-click picks half rounded
up. Left-click places it; dropping onto panel padding cancels without mutation.
Ground pickups play a short chime only after a successful collection, with an
authoritative event counter for the collecting online player.

Partial transfers carry an explicit amount and existing revision/proximity checks.
The coordinated game/Harbor protocol is now `holy-ship-coop-11`, so older hosts
cannot accidentally interpret partial-stack requests as whole-stack operations.
