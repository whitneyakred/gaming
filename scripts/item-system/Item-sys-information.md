# Item system

This folder defines the shared metadata for every item in the game. It does
not track who owns an item or how many exist in a player's inventory; that is
the responsibility of `scripts/inventory-system`.

## Runtime pieces

| File | Responsibility |
| --- | --- |
| `item_data.gd` | `ItemData`, the Resource that describes one kind of item. |
| `item_database.gd` | `ItemDatabase`, the lookup registry keyed by item ID. It is an autoload. |
| `items.gd` | `Items`, the startup autoload that creates and registers the current item definitions. |

`project.godot` registers `ItemDatabase` and `Items` as autoloads. The
database is therefore ready before gameplay scenes such as stations and
players are created. Do not add another `ItemDatabase` node to a scene.

## ItemData fields

Every item needs a stable, unique `StringName` ID. IDs are code-facing keys;
use lowercase snake_case such as `&"wood_plank"`. Changing an existing ID
breaks inventory lookups and configured station loot, so treat it as a stable
identifier once merged.

| Field | Use |
| --- | --- |
| `id` | Unique code ID used by inventories and stations. |
| `display_name` | Human-readable UI text. |
| `description` | Player-facing description for future UI. |
| `max_stack` | Maximum count of this item in a single inventory item type. Use at least `1`. |
| `icon` | Optional `Texture2D` displayed by the inventory hotbar. When it is empty, the hotbar displays the item's name instead. |
| `category` | Catalog category used by future systems to filter item definitions. Current categories are `FOOD`, `MATERIAL`, and `TOOL`. |
| `draw_weight` | Positive relative weight for a future item-pool draw. The current definitions use the neutral value `1.0` until loot tuning is approved. |
| `sell_value` | Nonnegative future merchant value. The current definitions use `0` until economy values are approved. |

## Creating an item

Add the definition inside `Items._ready()` in `items.gd`, using the existing
`make_item` helper. Its optional icon parameter comes immediately after the
category parameter:

```gdscript
ItemDatabase.register_item(make_item(
	&"wood_plank",
	"Wood Plank",
	"Useful lumber for repairs.",
	20,
	ItemData.Category.MATERIAL,
	WOOD_PLANK_ICON
))
```

`make_item` accepts values in this order: ID, display name, description, stack
limit, category, icon, draw weight, and sell value. Pass `null` as the icon if
an item has no artwork but needs a later optional value, such as a custom draw
weight.

The database asserts if an item is null, an ID is empty or duplicated, its
stack limit is below `1`, its draw weight is not positive, or its sell value is
negative. Keep all gameplay item
definitions in `Items._ready()` so that every system uses the same metadata
object, instead of constructing duplicate `ItemData` objects in stations.

## Adding an item PNG

Store item artwork under `assets/items/`, then assign it once in `items.gd`.
The item catalog owns that mapping; hotbar and inventory scripts must not load
textures by item ID themselves.

1. In the Godot editor's **FileSystem** dock, select the `assets/items` folder,
   right-click it, and choose **Open in File Manager**. Copy the PNG into that
   folder, then return to Godot and wait for its import scan to finish.
2. Near the top of `items.gd`, add a named preload using the resource path:

   ```gdscript
   const WOOD_PLANK_ICON := preload("res://assets/items/wood_plank.png")
   ```

3. Pass that constant as the sixth `make_item` argument, after
   `ItemData.Category` as shown in the creation example above.
4. Save `items.gd`. On the next run, any owned item with that icon appears as
   the PNG in the hotbar; its quantity label still appears for stacks above
   one.

PNG files are automatically imported by Godot. If a new preload reports that
its PNG has no resource loader, open the project once in the editor and let the
import scan complete before running the game or tests again.

## Looking up items in gameplay code

Stations and other systems store IDs, then resolve the metadata just before
they need it:

```gdscript
var item: ItemData = ItemDatabase.get_item(&"wood_plank")
if item == null:
	push_warning("Missing item definition: wood_plank")
	return
```

Always handle a `null` lookup. It usually means an ID was misspelled or the
definition was not registered.

Systems that need to examine the catalog without granting ownership can use
`ItemDatabase.get_all_items()`. It returns the registered shared definitions;
future item-pool code is responsible for filtering categories and applying
draw weights.

## Configuring station loot

Station scripts should expose item IDs for designers, as `FishingStation`
does with `loot_ids`. In the Godot editor, select the station instance, then
in the **Inspector** expand its script properties and edit **Loot Ids**.
Only use IDs registered by `Items`; an invalid ID is rejected at runtime with
a warning.

## Current definitions

| ID | Name | Stack limit | Icon | Current use |
| --- | --- | ---: | --- | --- |
| `fish_cod` | Sea Bass | 10 | `assets/items/seabass_alive.png` | Fishing reward |
| `rope` | Rope | 25 | `assets/items/rope_var1.png` | Fishing reward; general shipboard material |
| `fishing_rod` | Fishing Rod | 1 | None | Required to begin fishing; starter player item |
| `coconut` | Coconut | 20 | None | Registered fruit definition; placed challenge pickups do not yet grant it to inventory |

## Scope and future work

These are prototype per-item limits, distinct from the planned 30-item slot
stacks in `BR-inventory-slots`. `BR-repair-cost` requires wood; the `wood_plank`
snippet above is an example, not a registered item or an approved repair ID.

Keep this system as item definitions only. Item removal, recipes, world
pickups, saving, and item UI belong in their own focused changes. When adding
an icon, assign it through an item-definition workflow rather than loading a
texture ad hoc from each UI or station script.
