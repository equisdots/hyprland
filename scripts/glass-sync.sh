#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · glass-sync — keep the liquid-glass wallpaper snapshot current.
#
# LiquidGlass samples a single PNG from the Quickshell cache. davincix writes
# that file when it applies a wallpaper, but a direct `xwww img/set` call does
# not. This daemon follows `xwww query` and rewrites the snapshot when the
# active still image changes. Scenes, videos and missing files are ignored:
# the last still image stays as the lens source.
#
# Usage:
#   glass-sync.sh [--once]
#
#   --once   reconcile once and exit (useful for tests and hooks)
#
# Environment:
#   XDG_CACHE_HOME / XDG_STATE_HOME   standard XDG roots
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper_picker"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
SNAPSHOT="$CACHE_DIR/current_wallpaper.png"
LAST="$STATE_DIR/glass-sync.last"
RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell"
LOCK="$RUN_DIR/glass-sync.lock"

mkdir -p "$CACHE_DIR" "$STATE_DIR" "$RUN_DIR"

# One daemon per session; a second invocation exits quietly.
exec 9>"$LOCK"
if ! command -v flock >/dev/null 2>&1 || ! flock -n 9; then
    exit 0
fi

current_image() {
    command -v xwww >/dev/null 2>&1 || return 1
    # xwww query prints one block per output; the first still image is shared
    # by the shell's glass texture.
    xwww query 2>/dev/null \
        | sed -n 's/.*currently displaying: image: //p' \
        | head -n 1
}

reconcile() {
    local src tmp
    src="$(current_image)" || return 0
    src="${src#file://}"
    [ -n "$src" ] && [ -f "$src" ] || return 0
    [ -f "$SNAPSHOT" ] && [ "$(cat "$LAST" 2>/dev/null || true)" = "$src" ] && return 0

    tmp="$(mktemp "$SNAPSHOT.tmp.XXXXXX")" || return 1
    if command -v magick >/dev/null 2>&1; then
        # Force PNG: mktemp has no image extension, so ImageMagick would
        # otherwise keep the source encoding (e.g. JPEG) under a .png name.
        magick "$src" "PNG:$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
    else
        cp "$src" "$tmp" || { rm -f "$tmp"; return 1; }
    fi
    # SDDM and the lock screen read this file as another user.
    chmod 644 "$tmp"
    mv "$tmp" "$SNAPSHOT"
    printf '%s\n' "$src" > "$LAST"
}

reconcile || true

if [ "${1:-}" = "--once" ]; then
    exit 0
fi

while sleep 2; do
    reconcile || true
done
