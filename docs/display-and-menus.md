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

## Files and checks

- `scenes/menus/title_screen.tscn` and `scripts/menus/title_screen.gd`: title flow.
- `scripts/menus/`: shared theme, animated buttons, settings and ocean background.
- `scripts/game_window.gd`: persistence, window mode, focus behavior and audio.
- `scripts/pause_menu.gd`: pause/settings and confirmed return to title.
- `assets/menus/holy_ship_logo.png`: generated transparent title artwork.

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
