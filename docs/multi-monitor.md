# Multi-Monitor & Saved Layout

Hyprland 0.57+ (Lua era). The saved layout is stored in
`~/.config/hypr/display-config` and read by `config/hypr/monitors.lua` while the
config loads; the rules are registered with `hl.monitor()` and Hyprland applies
them when each output connects (boot, hotplug/re-dock) and whenever the config is
reloaded. There is no "apply N seconds after login" step.

## Startup modes

Settings → Monitors → **Saved layout** → *At startup* (also stored in
`settings.json → monitorsMode`):

| Mode | Value | Behavior |
|---|---|---|
| **Saved** (default) | `"static"` | `monitors.lua` registers `display-config` as `hl.monitor()` rules: boot, reload and hotplug. No polling. |
| **Reconciler** | `"reconciler"` | Same static rules plus `restore-monitors.sh` re-checking every ~2 s and re-applying drift. Use only when a dock enumerates late or firmware silently drops a mode. |
| **Auto** | `"off"` | `display-config` is ignored; the wildcard (`highrr` + auto position/scale) arranges screens. |

The mode is honored by `monitors.lua` and by `restore-monitors.sh`
(`--mode` prints the effective value, `--once` forces the static verification
pass, `--daemon` forces the reconciler).

## `display-config` format

```
# desc|x|y|scale|mode|transform|vrr|bitdepth|cm|mirror|disabled
AU Optronics B156HAN15.H|0|0|0.75|1920x1080@144.06Hz|0|0|8|srgb||0
```

- `desc` — `hyprctl monitors all` **description** (EDID model + serial). It
  survives connector renames (`DP-5` → `DP-3`); `desc:` matching is a prefix
  match.
- `x`, `y` — logical position (can be negative).
- `scale` — fractional scale; must produce whole logical pixels.
- `mode` — exact mode string from `availableModes` (e.g. `1920x1080@144.06Hz`);
  empty = highest refresh rate.
- Extended fields are optional (old 5-field files keep working):
  `transform` 0–7, `vrr` -1–3, `bitdepth` 8/10, `cm` preset, `mirror`
  (description of the mirrored screen), `disabled` 0/1.

Screens not present in the file fall back to the wildcard rule
(`output = ""`, `highrr`, `auto`), placed to the right of the saved ones.

## Applying, saving and resetting

- `SUPER + ALT + M` — rofi monitor manager (position, mirror, primary/external,
  refresh rate, info).
- Settings → Monitors — resolution, refresh rate, scale, rotation, VRR,
  bit-depth, color management, mirroring and the position canvas.
- **Apply & save permanently** writes the canvas layout to `display-config`
  (atomic write + `.bak`) and applies it live.
- **Reset to auto** deletes `display-config`/`.bak`, reloads and applies the
  wildcard rule.
- Scale menu / `scale-menu.sh` and `monitor-manager.sh` also persist
  `display-config`, so the static rules and the modes agree.

## Manual layout

You can edit `display-config` by hand (one line per screen) and run
`hyprctl reload`. Static rules are also allowed directly in
`config/hypr/monitors.lua`:

```lua
hl.monitor({ output = "desc:YOUR MONITOR DESCRIPTION", mode = "1920x1080@144",
             position = "0x0", scale = 1 })
```

Prefer `desc:` over connector names so the rule follows the physical screen.

## Troubleshooting

```bash
hyprctl monitors all            # names, descriptions, modes, live x/y/scale
hyprctl configerrors            # invalid rules/values after a reload
hyprctl deprecated-config       # deprecated options still in use
restore-monitors.sh --mode      # static | reconciler | off
cat ~/.config/hypr/display-config
```

- An old `~/.config/hypr/hyprland.conf` is ignored by 0.57+; remove it if it is
  still lying around (the installer cleans it up).
- If a screen is missing or mis-placed: check `display-config` and
  `hyprctl monitors all`, then `hyprctl reload`. Static rules are re-read on
  every reload.
- If a dock keeps losing its layout, switch *At startup* to **Reconciler**; the
  mode can be changed live from Settings.
- Multi-monitor keybinds: `SUPER+ALT+I/U` focus, `SUPER+ALT+SHIFT+I/U` move,
  `SUPER+ALT+O` swap workspaces, `SUPER+ALT+P` move workspace.
