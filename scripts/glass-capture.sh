#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · glass-capture — shell-free desktop capture for Aurora glass.
#
# Aurora needs the real screen (windows included), but a normal screencopy
# would also capture the shell itself and feed the glass back into itself.
# The QML Backdrop service raises `Theme.captureFreeze` (unmapping the master
# window, bar and overlays) before launching this script. The short delay lets
# the compositor commit those unmaps, then grim captures the focused output.
#
# Only the focused output is captured. Other outputs keep the wallpaper
# fallback; this avoids hanging grim on disconnected/disabled outputs while
# still giving the active screen a real desktop frame.
#
# Stdout: the captured output name (one line), consumed by GlassBackdrop.
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper_picker"
OUT_DIR="$CACHE_DIR/aurora"
mkdir -p "$OUT_DIR"

# Give the compositor time to unmap the shell surfaces before capturing.
sleep "${GLASS_CAPTURE_DELAY:-0.18}"

command -v grim >/dev/null 2>&1 || exit 1
command -v hyprctl >/dev/null 2>&1 || exit 1
command -v jq >/dev/null 2>&1 || exit 1

output="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -n 1)"
[ -n "$output" ] || exit 1

safe="$(printf '%s' "$output" | sed 's/[^A-Za-z0-9_-]/_/g')"
tmp="$OUT_DIR/.${safe}.$$.png"

if timeout "${GLASS_CAPTURE_TIMEOUT:-3}" grim -s "${GLASS_CAPTURE_SCALE:-0.5}" -o "$output" -t png "$tmp" 2>/dev/null; then
    mv -f "$tmp" "$OUT_DIR/$safe.png"
    printf '%s\n' "$output"
else
    rm -f "$tmp"
    exit 1
fi
