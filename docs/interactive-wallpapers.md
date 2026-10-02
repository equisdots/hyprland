# Interactive wallpapers (xwww scenes)

The desktop can run interactive wallpapers ("scenes") rendered by the `xwww`
scene engine. Selection and lifecycle live in `davincix` and the Quickshell
picker; this repository only restores the last scene at session start.

## Session start

`autostart.lua` starts `xwww-daemon` and then `scripts/init.sh`. `init.sh`
checks the davincix state file:

```
$XDG_STATE_HOME/quickshell/wallpaper_picker/current_scene
```

If it points to a directory with `scene.js`, the scene is re-applied with a
random entry transition and the script exits; otherwise the previous behaviour
(first-boot random wallpaper) applies. Applying an image or a video removes the
state file, so a scene is never restored over a static wallpaper.

## Usage

- Picker: `SUPER + W`, then choose a card with the `JS` badge
  (`astro-palette`, `astro-ascii`, `ascii-astro`).
- CLI:

  ```sh
  davincix set ~/.config/hypr/wallpapers/astro-palette --transition decrypt
  ```

Scenes follow the active palette (`settings.json` -> `bar.palette`) within
about a second, including their background color and swatch cards.

## Related documentation

- `equisdots/davincix` - `docs/interactive-scenes.md`
- `equisdots/background` - `docs/interactive-scenes.md`
- `equisdots/shell` - `docs/davincix-scenes.md`
