# Display, title screen and settings

Press **F5** (**Debug > Run Project**) to start at the title screen. **Play** starts
an empty new voyage. **Settings** and **How to play** are available before sailing.
In game, **P** pauses; **Esc** closes the current panel first, then pauses if no
panel handles it. Pause offers Resume, Settings and Return to title. Returning
asks for confirmation because voyage progress is not saved to disk.

## Consistent display

The project uses a 1280 × 720 design canvas, `canvas_items` scaling and `keep`
aspect ratio. World and HUD scale together, keeping the same camera coverage and
composition in 16:9 windows. Other aspect ratios get letterboxing/pillarboxing.
Artwork uses nearest filtering where appropriate; fractional scaling fits normal
laptop screens, so individual pixel widths can vary at non-integer scales.

Fullscreen is the desktop default. **F11** and Settings switch between fullscreen
and windowed mode. Window choices are 960 × 540, 1280 × 720 and 1600 × 900, clamped
to the display's available space. Resizing is supported with an 800 × 450 minimum.
Fullscreen uses the display's native resolution, not a forced monitor mode.
The Compatibility renderer remains enabled.

On Web, Play requests fullscreen during the user gesture when the preference is
on. Audio begins with a user click. Quit and desktop-only window controls are
hidden or disabled; browser refresh controls VSync. Browser policy can decline a
fullscreen request, and the game remains playable in its canvas.

## Preferences

`GameWindow` stores preferences in `user://settings.cfg` using ConfigFile. Invalid
values fall back to defaults or are clamped. Volume changes save after a short
debounce; leaving settings and quitting also save.

- Fullscreen, windowed size and VSync.
- Master, Music and Effects volume. The original synthesized eight-note menu
  motif uses Music; the short hover, click and back tones use Effects. Music
  runs on the title/pause menus, not continuously during gameplay.
- Mute when unfocused, auto-pause when unfocused, and reduced menu motion.
- Restore defaults and a keyboard/mouse controls reference.

Auto-pause never auto-resumes on focus regain. Reduced motion disables decorative
wave/logo motion and button scaling. Keyboard focus wraps within modal settings.
The controls are implemented once in `SettingsPanel`, reused by title and pause.
The window settings and preferences intentionally do not save voyage progress.

## Editing the menus in Godot

1. In the **FileSystem** dock, open `scenes/menus/title_screen.tscn` and select
   the **2D** workspace. The title now contains real, editable scene nodes.
2. In the **Scene** dock, select `Tagline`, `Footer`, `Hint`, or a Label/Button
   under `MenuCard > Rows`. Change **Text** in the **Inspector**.
3. Move `MenuCard`, `Wordmark`, `LogoShip`, or `Tagline` in the 2D viewport,
   or edit **Layout > Transform > Position / Size** in the Inspector.
   Buttons inside `Rows` are arranged by the VBoxContainer: reorder its children
   or change **Theme Overrides > Constants > Separation** on `Rows` for spacing.
   Keep node names intact; the title script uses them to wire button actions.
4. Select `TitleScreen` to adjust **Ship Bob Height** and **Ship Bob Speed**.
   The ship's edited position becomes its animation rest position. Reduced menu
   motion disables bobbing; the wordmark stays stationary in both modes.
5. **Ctrl+S** saves. **F6** (**Debug > Run Current Scene**) previews the title;
   **F5** (**Debug > Run Project**) tests the complete game. The ocean, panel
   theme, and button styling are applied at runtime, so use F6 for final styling.

The shared settings panel is still generated in `scripts/menus/settings_panel.gd`,
not an editable settings scene. Open that script from **FileSystem**, use
**Ctrl+F** to find wording, and edit the quoted display text. For example,
`_toggle(display, "Fullscreen", "fullscreen")` can become
`_toggle(display, "Play in fullscreen", "fullscreen")`. Change the second
argument (the label), keeping the final `fullscreen` preference key unchanged.
`_page("Display")` names a tab; `HarborTheme.label(...)` supplies descriptions.
Changes affect settings from both title and pause menus. Save and use F5 to test.

Voyage water colors are exported by `scripts/ocean.gd`; select an Ocean node
in a gameplay scene to override **Water Color**, **Wave Color**, and **Foam Color**.
The default base is `#142f40`, matching `scripts/menus/menu_ocean.gd`.

## Implementation and validation

- `scenes/menus/title_screen.tscn` and `scripts/menus/title_screen.gd`: title flow.
- `scripts/menus/`: shared theme, animated buttons, settings and ocean background.
- `scripts/game_window.gd`: persistence, window mode, focus behavior and audio.
- `scripts/pause_menu.gd`: pause/settings and confirmed return to title.
- `assets/menus/holy_ship_wordmark.png` and `holy_ship_boat.png`: separate
  stationary lettering and animated ship. The original combined logo is retained.

```
godot --headless --path . --script res://tests/menu_flow.gd -- --settings-test
godot --path . --script res://tests/menu_flow.gd -- --settings-test --capture
godot --headless --path . --script res://tests/pause_game.gd -- --settings-test
godot --headless --path . res://tests/inventory_integration.tscn -- --settings-test
```

`--settings-test` writes preferences into `.godot/menu-test-settings.cfg`, leaving
real player preferences untouched. Rendered captures in `.godot/` check title
and gameplay layouts at 960×540, 1280×720, 1440×900 and 1920×1080. Tests cover
preference round-trips, invalid values, audio bus volume, modal focus, new-voyage
reset, pause/settings/resume, confirmation and focus loss. Native macOS and browser
runtime testing still requires those platforms/export templates.
