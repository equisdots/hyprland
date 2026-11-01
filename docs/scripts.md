# Shell Scripts

All scripts reside in the repository root `scripts/` directory and are deployed to `~/.config/hypr/scripts/` by the installer.

## Core Infrastructure

| Script | Purpose |
|--------|---------|
| `caching.sh` | Dynamic caching framework. Exports `QS_CACHE_DIR`, `QS_STATE_DIR`, `QS_RUN_DIR`. Provides `qs_ensure_cache()` to create and export cache paths for any module by name. All QML and shell widgets use this for their runtime directories. |
| `init.sh` | Session wallpaper restore. Re-applies the active interactive scene when the davincix state file `current_scene` exists (see `docs/interactive-wallpapers.md`); otherwise first-run initialization picks a random wallpaper from the collection and applies it via `xwww` (through davincix), and later runs skip wallpaper selection since the wallpaper is already applied. |
| `qs_manager.sh` | Central IPC manager for QuickShell widgets. Routes workspace switching (fast path, no sourcing) and widget toggle/open/close commands. Also handles wallpaper thumbnail preparation (converts webp, generates video poster frames) and Bluetooth scan lifecycle. |
| `reload.sh` | Triggers a full QuickShell QML reload via IPC. |

## Theming

| Script / repo | Purpose |
|--------|---------|
| [`equisdots/theme-sync`](https://github.com/equisdots/theme-sync) | Modular theming engine (`themesync/` Python package: `core.py`, `runner.py`, `cli.py` + one module per application in `themesync/targets/`: `kitty`, `starship`, `xtop`, `vscode`, `nvim`, `browsers`, `opencode`, `rofi`, `cava`, `qt`, `gtk`, `xfetch`). Installed by `dots` under `~/.local/share/equisdots/theme-sync` with a `~/.local/bin/theme-sync` wrapper; called by the shell palette hook (`ui/bar/Colors.qml`) and `reload.sh`. |

## UI Scripts

| Script | Purpose |
|--------|---------|
| `brightness.sh` | Controls display brightness via `brightnessctl` (internal backlight) with fallback to `ddcutil` (external monitors via DDC/CI). Sends desktop notifications with percentage. |
| `volume.sh` | Controls audio volume via `pamixer`. Sends desktop notifications with percentage and mute state. |
| `volume_listener.sh` | Listens to PipeWire events via `pactl subscribe`. Triggers `swayosd-client` on volume changes without altering levels. Prevents duplicate popups from the same device. |
| `scale-menu.sh` | Rofi-based display scale selector (70%, 75%, 80%, 100%, 125%, 150%, 200%). Applies scale per-monitor through the Lua API (`hyprctl eval 'hl.monitor(...)'`) and records it in `settings.json`. |

## System Scripts

| Script | Purpose |
|--------|---------|
| `lock.sh` | Locks the session by launching the shell's alternate entry `~/.config/hypr/scripts/quickshell/Lock.qml` via QuickShell, which acquires a `WlSessionLock`. |
| `exit.sh` | Gracefully ends the Hyprland session by stopping user targets and dispatching `hyprctl dispatch exit`. |
| `gpu-mode.sh` | NVIDIA Optimus mode switcher wrapping `envycontrol`. Supports cycle (silent/hybrid/nvidia), Rofi menu selector, and Waybar status output. Requires passwordless sudo rule (set up by installer). |
| `monitor-manager.sh` | Rofi-based multi-monitor manager. Supports positioning (left/right/above/below/mirror), single display modes, and refresh rate changes per monitor. Applies changes through the Lua API (`hyprctl eval 'hl.monitor(...)'`). Displays monitor info via notification. |
| `screenshot.sh` (plugin) | Screenshot and recording with virtual audio. Ships as the `screenshots` plugin (`~/.config/hypr/plugins/screenshots/scripts/`, installed by default by dots): area selection, full screen, active window, edit mode (satty), recording (gpu-screen-recorder with virtual audio routing), QR scanning (zbarimg), multi-track audio with independent desktop/mic controls. |
| `update_notifier.sh` | Checks for updates every 10 minutes. Compares local version against remote, shows notification if newer version is available, and signals the bar to show an update icon. |
| `workspaces.sh` | Daemon that listens to Hyprland socket events and generates workspace state JSON (id, state: active/occupied/empty, tooltip, app classes). Uses 50ms debouncing to prevent CPU overload during rapid window events. Includes zombie cleanup of stale instances. |

## Strict mode policy

- **One-shot actions and installers** use `set -euo pipefail`: they must fail fast instead of continuing with a half-applied change.
- **Interactive menus** use `set -uo pipefail` without `-e`: dismissing the rofi picker or cancelling an action is a normal outcome, not a script error, and best-effort `hyprctl`/notification calls must not abort the menu. Positional arguments are read as `${1:-}` so a bare invocation still works under `set -u`.
- **Commands that must always reach a user-visible action** (session exit, IPC routing, network updater) use `-uo pipefail` without `-e` and handle failures explicitly.
- **Daemons and watchers** (`workspaces.sh`, `volume_listener.sh`, `update_notifier.sh`, `restore-monitors.sh`) keep all strict options off so one failed event does not kill the loop; use explicit error handling and supervision (systemd) instead.
- **Sourced libraries** (`caching.sh`, `ws-desktops-lib.sh`) must not set shell options; the caller owns the shell policy.
- **Test harnesses** (`tests/run.sh`, `tests/*.sh`) use `-u` (and sometimes `-o pipefail`) without `-e`: a failing assertion must be collected and reported, not abort the runner.

### Current audit (2026-11-01)

| Classification | Scripts | Notes |
|----------------|---------|-------|
| `set -euo pipefail` | `install-xfetch.sh`, `install-xtop.sh`, `scenes.sh`, `wallpapers*.sh`, `lock.sh`, `reload.sh`, `brightness.sh`, `volume.sh`, `idle-mode.sh`, `init.sh`, `persist-display-config.sh` | One-shot actions fail fast. `init.sh` guards the optional scene-state read and the wallpaper scan with `|| true`; a failed wallpaper apply aborts before the initialized flag is written, so the next session retries. `persist-display-config.sh` guards the optional `settings.json` read and fails fast on invalid `hyprctl` JSON, which its callers already wrap in `|| true`. |
| `set -uo pipefail` (no `-e`) | `exit.sh`, `qs_manager.sh`, `dotfiles-update.sh`, `monitor-manager.sh`, `scale-menu.sh`, `gpu-mode.sh` | `exit.sh`/`qs_manager.sh` must reach their action. `dotfiles-update.sh` treats network failures as reports, not fatal errors. `monitor-manager.sh`/`scale-menu.sh`/`gpu-mode.sh` are interactive menus: empty/cancelled selections exit cleanly, so `-e` is intentionally omitted. |
| No strict options | `workspaces.sh`, `volume_listener.sh`, `update_notifier.sh`, `restore-monitors.sh` | Long-running daemons; a single failed event must not terminate the loop. |
| Caller owns options | `caching.sh`, `ws-desktops-lib.sh` | Sourced libraries only. |
