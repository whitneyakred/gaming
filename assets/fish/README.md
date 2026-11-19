# Ocean fish art

`fish_swim.png` contains six species with four swimming poses each: silver sardine,
amber reef fish, blue mackerel, violet flatfish, coral fish and olive needlefish.
Generated using the built-in image-generation tool, then refined with the edit
prompt below. Original generated pixels and alpha are preserved.

The source is approximately a 4-column, 6-row atlas, not a mechanically uniform
grid. `scripts/visuals/fish_atlas.gd` records each nose and safe crop row;
`shaders/fish_water.gdshader` registers poses into a virtual 320-pixel cell,
removes the very faint background alpha, and applies the submerged appearance.
Do not replace it with simple equal-cell slicing: the bottom two rows straddle
the nominal cell boundaries. Update registration when replacing this artwork.

Generation prompt:

> Create a production pixel-art sprite atlas for a top-down 2D sailing game Holy Ship. Transparent background. Exactly 4 columns and 6 rows, evenly spaced identical square cells, no labels no grid no water no shadows. Each ROW is one fish species and its four swimming frames left-to-right: tail left, neutral, tail right, neutral. All fish seen strictly from directly ABOVE, head pointing UP, body centered identically in every cell; entire animal fits with generous 20% transparent margin. Six distinct species: row1 slender silver sardine with dark teal back; row2 golden amber reef fish with short rounded body; row3 blue turquoise striped mackerel; row4 dark violet broad diamond-shaped flat fish; row5 slender coral-red fish with forked tail; row6 olive green long needlefish. Crisp chunky pixel-art with dark navy outline, restrained 4-tone shading per fish, readable silhouettes at 20-45 pixels in game. No side views, no cartoon faces, no fins breaking water. Subdued colors suitable for a dark blue sea with underwater tint applied by game shader. Animation must change tail and pectoral fins but keep head and torso registration consistent. Deliver a single sprite sheet, 4 columns x 6 rows. Prefer 1024x1536 canvas.

Refinement prompt:

> Edit this fish sprite atlas for actual game use. Preserve exactly the 24 fish sprites and pixel artwork. REMOVE ALL background, colored halos, glows, shadows: pixels outside fish must be truly alpha=0, including gaps inside fins, no opaque dark backdrop. Exactly 4 columns x6 rows on1024x1536 transparent canvas, each cell256x256. Align each fish head at cell-local(128,40), body centered x128 and complete tail ends by y220. Keep the same 4 swimming poses each row. No text, no grid. Flat crisp sprite pixels with actual transparent surroundings, no effects.
