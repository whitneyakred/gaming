# Workbench and tool durability

Walk to the table at the front of the boat and press **E** or **Space**. Select a tool icon to preview its ingredient icons and quantities, then press **Craft**. Materials come from your four inventory slots. Close with **E**, **Esc**, or **Close**. Crafting never consumes ingredients if the finished tool cannot fit.

| Tool | Ingredients | Durability |
| --- | --- | --- |
| Fishing rod | 3 wood, 1 rope, 1 string | 20 completed attempts (catch or snapped line) |
| Pickaxe | 3 wood, 3 stone | 30 successful rock hits |
| Axe | 3 wood, 2 stone | 30 successful tree hits |
| Spyglass | 2 wood, 2 stone, 1 rope | Unlimited; no durability bar |

The fishing rod, axe and pickaxe disappear at zero durability. The spyglass never breaks. Green/yellow/red bars appear beneath icons in both the hotbar and chests. Transfers, swaps, drops, saves and co-op snapshots preserve remaining durability. Older tools without a durability field begin at full strength. Other item categories do not wear out.

The reusable scene is `scenes/inventory/crafting_station.tscn`; the boat places it at (3, -177). Interaction range is Inspector-configurable. Recipe quantities are in `CraftingStation.RECIPES`; tool limits are assigned in `items.gd` using the exported `ItemData.max_durability` property.

## Artwork

Built-in imagegen tool; transparent sprite saved to `assets/props/crafting_workbench.png`. Rendered with nearest-neighbor filtering. No new dependencies.

Final generation prompt (built-in imagegen, screenshot supplied as palette reference):

> Generate one isolated simple workbench game sprite on transparent background. Use the attached screenshot ONLY as palette and pixel-style reference: match its muted gray-beige weathered boat planks and tan chests, dark desaturated brown outlines. Do not reproduce the boat. Strict directly overhead top-down view, horizontal rectangular tabletop, about 5 broad pale driftwood planks, two small dark iron corner braces and a single small gray hammer resting in one corner. Almost entirely bare tabletop. Simple readable coarse pixel art intended for 52x30 game pixels, flat limited palette, hard pixel edges. Colors beige #b7a38b, light tan #cebaa0, wood shadow #8b7762, outline #51483e, iron #686563. No orange, no saturated yellow, no gold, no chests, no rope, no scrolls, no scattered clutter, no perspective, no glow, no ground shadow. Centered full object with minimal transparent padding.

## Validation

- Godot 4.7.2 headless editor import/parser and game scene startup.
- `tests/crafting_durability.tscn`: all recipes, missing ingredients, full-bag rollback, stale revision, breakage, chest transfers, dropped-tool pickup and malformed durability validation.
- `tests/chest_multiplayer_suite.gd`: real host/guest crafting, authoritative ingredient consumption and durability replication, alongside independent chest and save/reload regression checks.
- Rendered screenshot checked at 1280 x 720 (`--preview-crafting` test argument).

The sandbox prevented Godot's normal user log/editor-settings writes; workspace test logs were readable. The older standalone `independent_chests.gd` assumes an empty persisted second chest and failed that fixture assertion; the isolated two-peer suite cleared its fixtures and passed both chest save/reload checks.
