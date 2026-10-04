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
| `icon` | Optional `Texture2D` for a future inventory UI. |

## Adding an item

Add the definition inside `Items._ready()` in `items.gd`, using the existing
`make_item` helper. For example:

```gdscript
ItemDatabase.register_item(make_item(
	&"wood_plank",
	"Wood Plank",
	"Useful lumber for repairs.",
	20
))
```

The database asserts if an ID is empty or duplicated. Keep all gameplay item
definitions in `Items._ready()` so that every system uses the same metadata
object, instead of constructing duplicate `ItemData` objects in stations.

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

## Configuring station loot

Station scripts should expose item IDs for designers, as `FishingStation`
does with `loot_ids`. In the Godot editor, select the station instance, then
in the **Inspector** expand its script properties and edit **Loot Ids**.
Only use IDs registered by `Items`; an invalid ID is rejected at runtime with
a warning.

## Current definitions

| ID | Name | Stack limit | Current use |
| --- | --- | ---: | --- |
| `fish_cod` | Cod | 10 | Fishing reward |
| `rope` | Rope | 25 | Fishing reward; future repair material |
| `fishing_rod` | Fishing Rod | 1 | Required to begin fishing; starter player item |

## Scope and future work

Keep this system as item definitions only. Item removal, recipes, world
pickups, saving, and item UI belong in their own focused changes. When adding
an icon, assign it through an item-definition workflow rather than loading a
texture ad hoc from each UI or station script.
