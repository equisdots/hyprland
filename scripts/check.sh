#!/usr/bin/env bash
# Local checks for the hyprland config repo (no CI):
#   - Lua syntax for every config module with luac -p.
#   - Bash syntax for the installer/scripts with bash -n.
#   - shellcheck (advisory) when available.
#   - Static Hyprland config gate with `Hyprland --verify-config` when the
#     binary is installed (0.57 also validates option ranges).
#
# Usage: scripts/check.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)" || exit 1
cd "$ROOT" || exit 1

# The same script runs from the repo checkout (config/hypr/hyprland.lua) and
# from the deployed tree (~/.config/hypr/hyprland.lua). Detect the layout once
# so both the Lua scan and the Hyprland gate point at the right files.
if [ -f "$ROOT/hyprland.lua" ]; then
    # Deployed tree (~/.config/hypr): modules at the root, user overrides in
    # config/ (which may itself contain a config/hypr/hyprland.lua override).
    CONFIG_FILE="$ROOT/hyprland.lua"
else
    # Repo checkout: the whole config lives under config/hypr/.
    CONFIG_FILE="$ROOT/config/hypr/hyprland.lua"
fi

lua_files() {
    if [ -f "$ROOT/hyprland.lua" ]; then
        find "$ROOT" -maxdepth 1 -name '*.lua' -not -path '*/.git/*'
        find "$ROOT/config" -name '*.lua' -not -path '*/.git/*' 2>/dev/null
    else
        find "$ROOT/config" -name '*.lua' -not -path '*/.git/*'
    fi | sort
}

fail=0

if ! command -v luac >/dev/null 2>&1; then
    echo "error: luac not found (install the Lua compiler)" >&2
    exit 2
fi

lua_total=0
while IFS= read -r f; do
    lua_total=$((lua_total + 1))
    if ! luac -p "$f" >/dev/null 2>&1; then
        echo "luac FAIL: $f"
        fail=1
    fi
done < <(lua_files)
echo "luac: $lua_total Lua modules checked"

sh_total=0
while IFS= read -r f; do
    sh_total=$((sh_total + 1))
    if ! bash -n "$f" 2>/dev/null; then
        echo "bash -n FAIL: $f"
        fail=1
    fi
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck -S warning "$f" >/dev/null 2>&1 || echo "shellcheck note: $f (advisory)"
    fi
done < <(find . -name '*.sh' -not -path './.git/*' | sort)
echo "bash -n: $sh_total scripts checked"

if command -v Hyprland >/dev/null 2>&1 && [ -f "$CONFIG_FILE" ]; then
    verify_args=(--verify-config)
    [ "$(id -u)" -eq 0 ] && verify_args=(--i-am-really-stupid "${verify_args[@]}")
    verify_out="$(mktemp)"
    if HYPRLAND_CONFIG="$CONFIG_FILE" Hyprland "${verify_args[@]}" >"$verify_out" 2>&1; then
        echo "Hyprland: config OK"
    else
        echo "Hyprland --verify-config FAIL:"
        sed 's/^/  /' "$verify_out"
        fail=1
    fi
    rm -f "$verify_out"
else
    echo "Hyprland: SKIP (binary not found; install hyprland for the config gate)"
fi

if [ "$fail" -eq 0 ]; then
    echo "hyprland: checks OK"
fi
exit "$fail"
