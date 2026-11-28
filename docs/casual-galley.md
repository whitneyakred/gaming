# Casual galley and shared crafting

The galley now prepares one caught fish as a fish kabob: three downward slices, four pieces into the pot, move the heat slider into its green zone, then move four cooked pieces onto the skewer. There is no recipe deadline, rating, potato, precision-drop reward, or burned-result penalty. Cooking needs eight seconds in the green heat range; moving outside it pauses progress without burning food. Collecting the kabob closes the Cooking Station and restores player movement. Cancelling, closing, disconnecting, or restoring an unfinished saved attempt retains the existing ingredient refund/recovery behavior. The host owns the ingredient and completion token; repeated completion cannot duplicate food.

The `dried_fish` save/network item ID is retained for compatibility. Its display name is Fish Kabob and its icon matches the final meal. Raw and cooked pieces use dedicated complete sprites, rather than clipped sections of the fish or kabob. Four 44-by-32 pieces fit inside the pot rim. The knife tip tracks the pointer and its handle trails the cutting direction. The ship's cooking station and activity share the new iron pot. The UI uses the same Rye font and parchment/driftwood palette as the game menus.

Workbench crafting consumes bag materials first, then starboard and port chest materials. It prepares copies of all three inventories and commits only when every ingredient and output space is available. The host performs the transaction without yielding. Recipe availability updates from both chests, including guest snapshots.

Validation: `tests/casual_cooking.gd` (20 checks), existing grill escrow/recovery suite (20 checks), crafting/durability suite, and host plus two guests (76 checks). Captures live under ignored `.godot/cooking-validation/`.

## Generated art

Built-in image generation created `assets/cooking/pot_pixel.png`, `knife_pixel.png`, `kabob_pixel.png`, `raw_piece_pixel.png`, and `cooked_piece_pixel.png`. Adjacent AtlasTextures crop transparent padding without modifying the source images. The kabob received a follow-up transparency edit to remove surrounding haze while retaining its four-piece silhouette. Originals are retained in the generator's output directory.

## Prompts

### pot

A squat open gray iron cooking pot on a small square charcoal burner, slightly overhead view so dark interior is broad and visible for dropping food into it. Two short side handles, simple warm gray rim and dark indigo metal. No food, no steam, no flames; those animate separately. Readable at 48 pixels on deck and 240 pixels in preparation UI. Create a single isolated game sprite on transparent background. Muted nautical pixel art for Holy Ship: crisp visible square pixel clusters, dark taupe outlines, weathered beige wood, gray iron, limited colors. Match the reference item atlas style, not a painting or vector. No text, no decorative background. Leave transparent padding.

### kabob

A single fish kabob, one thin wooden skewer diagonal from bottom left to upper right bearing exactly four chunky pieces of cooked fish. Golden beige flaky fish with a little dark teal skin edge and simple brown sear stripes; NO vegetables, NO whole fish, NO plate. Strong clear silhouette readable at 32px inventory size. Create a single isolated game sprite on transparent background. Muted nautical pixel art for Holy Ship: crisp visible square pixel clusters, dark taupe outlines, weathered beige wood, gray iron, limited colors. Match the reference item atlas style, not a painting or vector. No text, no decorative background. Leave transparent padding.

### knife

One small kitchen knife diagonally upright, broad simple gray iron blade and weathered brown wooden handle. Low-detail pixel sprite readable at 32pixels, for fish cutting minigame. Create a single isolated game sprite on transparent background. Muted nautical pixel art for Holy Ship: crisp visible square pixel clusters, dark taupe outlines, weathered beige wood, gray iron, limited colors. Match the reference item atlas style, not a painting or vector. No text, no decorative background. Leave transparent padding.
