#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · scenes — download and install the interactive wallpapers.
#
# Scenes are dynamic wallpapers rendered by the xwww scene engine (a directory
# with scene.js plus its assets). They live in the equisdots/background repo
# under scenes/ and are installed as directories inside the wallpaper
# collection (~/.config/hypr/wallpapers/), where davincix lists them next to
# images and videos and the Quickshell picker (SUPER + W) shows them.
#
# Usage:
#   scenes.sh [--yes|--no] [--dir <path>] [--source <url|path>]
#
#   --yes         install without asking
#   --no          skip without asking
#   --dir PATH    destination (default: ~/.config/hypr/wallpapers)
#   --source X    override the source: a repo checkout/directory or a
#                 .tar.gz archive (default: the equisdots/background tarball)
#   -h, --help    show this help
#
# Environment:
#   WALLPAPER_SCENES=1|0   force install/skip without prompting
#   ASSUME_YES=1           non-interactive: skip unless WALLPAPER_SCENES=1
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

SOURCE_DEFAULT="https://github.com/equisdots/background/archive/refs/heads/main.tar.gz"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpapers"
SOURCE="$SOURCE_DEFAULT"
MODE=""

msg()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m error:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
scenes.sh — download and install the equisdots interactive scenes

Usage:
  scenes.sh [--yes|--no] [--dir <path>] [--source <url|path>]

Options:
  --yes         install without asking
  --no          skip without asking
  --dir PATH    destination (default: ~/.config/hypr/wallpapers)
  --source X    source override: a repo checkout/directory or a .tar.gz
                archive (default: the equisdots/background tarball)
  -h, --help    show this help

Environment:
  WALLPAPER_SCENES=1|0   force install/skip without prompting
  ASSUME_YES=1           non-interactive: skip unless WALLPAPER_SCENES=1
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y) MODE=yes ;;
        --no|-n)  MODE=no ;;
        --dir)    shift; [ $# -gt 0 ] || die "--dir needs a value"; DEST="$1" ;;
        --dir=*)  DEST="${1#*=}" ;;
        --source) shift; [ $# -gt 0 ] || die "--source needs a value"; SOURCE="$1" ;;
        --source=*) SOURCE="${1#*=}" ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
done

# Decision order: flags > WALLPAPER_SCENES > -y (skip) > prompt.
if [ -z "$MODE" ] && [ -n "${WALLPAPER_SCENES:-}" ]; then
    case "$WALLPAPER_SCENES" in
        1|yes|true)  MODE=yes ;;
        0|no|false)  MODE=no ;;
        *) die "WALLPAPER_SCENES must be 1 or 0" ;;
    esac
fi
if [ -z "$MODE" ] && [ "${ASSUME_YES:-0}" = "1" ]; then
    MODE=no
fi
if [ -z "$MODE" ]; then
    printf 'Download the interactive scenes (dynamic xwww wallpapers)? [y/N] '
    read -r answer || answer=""
    case "$answer" in
        [Yy]*) MODE=yes ;;
        *)     MODE=no ;;
    esac
fi
if [ "$MODE" = "no" ]; then
    msg "Skipping interactive scenes (run '$(basename "$0")' later to add them)."
    exit 0
fi

TMP_DIR=""
cleanup() { if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi; }
trap cleanup EXIT

# ── fetch the source (URL tarball, local archive or directory) ─────────────
ROOT=""
case "$SOURCE" in
    http://*|https://*)
        command -v tar >/dev/null 2>&1 || die "tar is required to unpack the scenes"
        TMP_DIR="$(mktemp -d)"
        archive="$TMP_DIR/scenes.tar.gz"
        msg "Downloading interactive scenes..."
        if command -v wget >/dev/null 2>&1; then
            wget --progress=bar:force -O "$archive" "$SOURCE" || die "failed to download the scenes"
        elif command -v curl >/dev/null 2>&1; then
            curl -fL --progress-bar -o "$archive" "$SOURCE" || die "failed to download the scenes"
        else
            die "wget or curl is required to download the scenes"
        fi
        tar -xzf "$archive" -C "$TMP_DIR" || die "failed to extract the scenes archive"
        ROOT="$TMP_DIR"
        ;;
    *.tar.gz|*.tgz)
        [ -f "$SOURCE" ] || die "source archive not found: $SOURCE"
        command -v tar >/dev/null 2>&1 || die "tar is required to unpack the scenes"
        TMP_DIR="$(mktemp -d)"
        tar -xzf "$SOURCE" -C "$TMP_DIR" || die "failed to extract $SOURCE"
        ROOT="$TMP_DIR"
        ;;
    *)
        [ -d "$SOURCE" ] || die "source directory not found: $SOURCE"
        ROOT="$SOURCE"
        ;;
esac

# ── locate the scenes root (scenes/, a bare set of scene dirs, or the
#    GitHub tarball layout background-main/scenes) ─────────────────────────
SCENES_ROOT=""
if [ -d "$ROOT/scenes" ]; then
    SCENES_ROOT="$ROOT/scenes"
else
    for d in "$ROOT"/*/; do
        if [ -f "$d/scene.js" ]; then SCENES_ROOT="$ROOT"; break; fi
    done
    if [ -z "$SCENES_ROOT" ]; then
        found="$(find "$ROOT" -mindepth 2 -maxdepth 2 -type d -name scenes -print -quit 2>/dev/null || true)"
        if [ -n "$found" ]; then SCENES_ROOT="$found"; fi
    fi
fi
[ -n "$SCENES_ROOT" ] || die "no scenes found in the source ($SOURCE)"

# ── install one directory per scene, replacing the previous copy ───────────
mkdir -p "$DEST"
count=0
names=""
for d in "$SCENES_ROOT"/*/; do
    [ -f "$d/scene.js" ] || continue
    name="$(basename "$d")"
    rm -rf "$DEST/$name"
    cp -r "$d" "$DEST/$name"
    count=$((count + 1))
    names="$names $name"
done
[ "$count" -gt 0 ] || die "no scene directories (scene.js) found in the source"

ok "Scenes installed to $DEST:$names"
msg "Apply one from the picker (SUPER + W) or: davincix set $DEST/<scene>"
