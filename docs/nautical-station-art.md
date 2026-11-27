# Nautical station art

Anchor, winch, narrow canvas sail and marked steering wheel were generated with the built-in image generator using the supplied boat screenshot as palette guidance. Original transparent PNGs are preserved in `assets/props/*_pixel.png`; adjacent AtlasTexture resources trim transparent padding without modifying the originals. Deck and HUD use the same wheel texture, with an ivory band on the top spoke.

The anchor follows the existing authoritative deployed flag, animates over the port rail, splashes once at water impact, and leaves a braided rope attached to the winch. Initial saved/joined states initialize silently. Reversing deployment retrieves the anchor without an extra impact.

The sail retains furled plus three existing speed settings. Sixteen cloth strips animate cosmetically with speed and wind; no physics bodies or network messages are added. Canvas fades to 40% over the local player's head, including when the ship or sail rotates. Sail width, reef heights and opacity are Inspector properties.

Taking the helm places the operator 40 pixels astern of the wheel, facing it. Existing authoritative crew snapshots carry the position. Interaction range includes the operating spot so releasing and retaking control remains possible. The workbench aligns with the station centerline.

Validation: Godot 4.7.2 Compatibility import/startup, 29 new station checks, station-camera and boat-art integration, 33 character-animation checks, movement smoothing, and a real host plus two guests (76 multiplayer checks). Native screenshots are temporary files under `.godot/nautical-validation/`. These checks do not establish production browser performance or a new deployment.

## Generation prompts

### anchor

One simple iron ship anchor sprite, directly overhead, ring at the very top, upright central shaft and two curved pointed flukes at bottom. Symmetrical shape, heavy dark gray iron with a few muted silver pixel highlights and dark brown-gray outlines. No attached rope: rope will animate separately. No chain, no wooden base, no decoration. Readable at 18x26 game pixels. Reference screenshot is style/palette guidance only. Match muted weathered beige driftwood, dark taupe outlines, gray iron and subdued tan rope. Crisp coarse pixel clusters as a low-resolution game sprite, no smooth gradients, no glow, no text, no decorative clutter. Fully transparent background. Single isolated object centered with generous clear separation from canvas edges.

### anchor_station

One top-down overhead nautical anchor winch station sprite for a 2D sailing game. Compact rectangular weathered light gray-beige wooden base with a horizontal spool wound in thick neatly braided beige rope, two iron brackets and a small wooden crank. The station is simple and legible at 26x24 game pixels. No anchor in this image: the anchor is a separate moving sprite. No loose rope leaving the object. Reference screenshot is style/palette guidance only. Match muted weathered beige driftwood, dark taupe outlines, gray iron and subdued tan rope. Crisp coarse pixel clusters as a low-resolution game sprite, no smooth gradients, no glow, no text, no decorative clutter. Fully transparent background. Single isolated object centered with generous clear separation from canvas edges.

### sail

One narrow horizontal ship sail game sprite seen from directly overhead, for a top-down 2D boat. Long rectangular strip of muted ivory canvas, around 5 times wider than tall, gently billowed bottom edge, only four broad fabric panels with restrained tan stitched seams and a few broad angular pale cloth folds. Top edge has one slender weathered beige wooden yard with simple dark rope lashings at each end. Cloth hangs down below the yard within the same narrow horizontal silhouette. No mast protruding, no boat, no ropes extending outside sprite, no perspective side view, no emblem. Readable at 112x25 game pixels. Reference screenshot is style/palette guidance only. Match muted weathered beige driftwood, dark taupe outlines, gray iron and subdued tan rope. Crisp coarse pixel clusters as a low-resolution game sprite, no smooth gradients, no glow, no text, no decorative clutter. Fully transparent background. Single isolated object centered with generous clear separation from canvas edges.

### wheel

One circular eight-spoke wooden ship steering wheel sprite, flat directly overhead/front-on rotationally symmetric view, for top-down pixel game and matching HUD icon. Broad simple weathered beige wooden rim, eight clearly spaced handles and spokes, small dark iron central hub. Muted light driftwood palette matching reference boat, not orange, no brass. At exactly twelve o'clock, wrap the outer handle and its spoke tip in a distinctly light ivory cloth band with one small dark central notch: this is the unique neutral-direction marker, no other spoke has that band. The wheel must be centered on its hub and remain a true circle, all handles visible, no stand or pedestal in image. Large simple pixel clusters, readable at 36x36 game pixels and 160x160 HUD size. Reference screenshot is style/palette guidance only. Match muted weathered beige driftwood, dark taupe outlines, gray iron and subdued tan rope. Crisp coarse pixel clusters as a low-resolution game sprite, no smooth gradients, no glow, no text, no decorative clutter. Fully transparent background. Single isolated object centered with generous clear separation from canvas edges.
