#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# init.sh — primera ejecución: elige un wallpaper al azar y lo aplica.
#
# Aplicar (y cachear la imagen para lock/SDDM) vive en la capa kernel de
# davincix (repo aparte); aquí solo se decide CUÁL aplicar. El flag de estado
# evita repetir la elección en cada arranque.
# ═══════════════════════════════════════════════════════════════════════════

# Kernel paths (davincix repo; dots installs it under ~/.local/share/equisdots).
KERNEL_DIR="${DAVINCIX_KERNEL_DIR:-$HOME/.local/share/equisdots/davincix}"
if [ -f "$KERNEL_DIR/paths.sh" ]; then
    # shellcheck disable=SC1091
    . "$KERNEL_DIR/paths.sh"
fi

# Defaults mirrored from the kernel so the state flag keeps working without it.
DAVINCIX_WALLPAPER_DIR="${DAVINCIX_WALLPAPER_DIR:-${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}}"
DAVINCIX_STATE_DIR="${DAVINCIX_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/wallpaper_picker}"

# CLI: env override, PATH, then the dots wrapper.
DAVINCIX_CLI="${DAVINCIX_CLI:-$(command -v davincix 2>/dev/null || true)}"
[ -x "$DAVINCIX_CLI" ] || DAVINCIX_CLI="$HOME/.local/bin/davincix"
if [ ! -x "$DAVINCIX_CLI" ]; then
    echo "init.sh: davincix CLI not found; skipping wallpaper init" >&2
    exit 0
fi

FLAG="$DAVINCIX_STATE_DIR/wallpaper_initialized"

# Si el flag existe, el wallpaper ya se aplicó; nada que hacer.
if [ -f "$FLAG" ]; then
    exit 0
fi

sleep 0.5

# Un archivo al azar del directorio de wallpapers.
file=$(find "$DAVINCIX_WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | shuf -n 1)

if [ -n "$file" ]; then
    "$DAVINCIX_CLI" set "$file" --transition any
fi

mkdir -p "$(dirname "$FLAG")"
touch "$FLAG"
