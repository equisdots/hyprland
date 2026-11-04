#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# init.sh — primera ejecución: elige un wallpaper al azar y lo aplica.
#
# Aplicar (y cachear la imagen para lock/SDDM) vive en la capa kernel de
# davinci (repo aparte); aquí solo se decide CUÁL aplicar. El flag de estado
# evita repetir la elección en cada arranque.
#
# Strict mode: this is a one-shot startup action, so failing fast is safe.
# A failed `davinci set` aborts before the flag is written, which means the
# next session retries instead of silently keeping a broken wallpaper. The
# two best-effort lookups below (state file read and random file scan) are
# explicitly guarded with `|| true` because a missing/unreadable file or an
# empty wallpaper directory is not an error.
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Kernel paths (davinci repo; dots installs it under ~/.local/share/equisdots).
KERNEL_DIR="${DAVINCI_KERNEL_DIR:-$HOME/.local/share/equisdots/davinci}"
if [ -f "$KERNEL_DIR/paths.sh" ]; then
    # shellcheck disable=SC1091
    . "$KERNEL_DIR/paths.sh"
fi

# Defaults mirrored from the kernel so the state flag keeps working without it.
DAVINCI_WALLPAPER_DIR="${DAVINCI_WALLPAPER_DIR:-${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}}"
DAVINCI_STATE_DIR="${DAVINCI_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/wallpaper_picker}"

# CLI: env override, PATH, then the dots wrapper.
DAVINCI_CLI="${DAVINCI_CLI:-$(command -v davinci 2>/dev/null || true)}"
[ -x "$DAVINCI_CLI" ] || DAVINCI_CLI="$HOME/.local/bin/davinci"
if [ ! -x "$DAVINCI_CLI" ]; then
    echo "init.sh: davinci CLI not found; skipping wallpaper init" >&2
    exit 0
fi

FLAG="$DAVINCI_STATE_DIR/wallpaper_initialized"

# Sesión anterior con una escena interactiva activa: re-aplícala. El estado
# persiste entre reinicios y la escena se re-lanza tal cual, con su paleta.
scene_state="$DAVINCI_STATE_DIR/current_scene"
if [ -f "$scene_state" ]; then
    # Best-effort read: the state file may disappear between the test and the
    # read, which must not abort the startup path.
    scene_dir="$(cat "$scene_state" 2>/dev/null || true)"
    if [ -n "$scene_dir" ] && [ -f "$scene_dir/scene.js" ]; then
        sleep 0.5
        "$DAVINCI_CLI" set "$scene_dir"
        exit 0
    fi
    rm -f "$scene_state"
fi

# Si el flag existe, el wallpaper ya se aplicó; nada que hacer.
if [ -f "$FLAG" ]; then
    exit 0
fi

sleep 0.5

# Un archivo al azar del directorio de wallpapers.
# `|| true`: a missing directory (find) or a missing shuf must not abort the
# startup script; the empty result is handled by the check below.
file=$(find "$DAVINCI_WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null \
    | shuf -n 1 || true)

if [ -n "$file" ]; then
    "$DAVINCI_CLI" set "$file" --transition any
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
