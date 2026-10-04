#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · wallpapers — download and install a wallpaper pack.
#
# Packs live in the equisdots/background repo, one per release (background.zip
# for the X collection, Wallpapers-Avex-X-*.zip for the Avex collaboration).
# The list is resolved from the GitHub API so new releases show up
# automatically; the current releases are pinned as fallback for offline runs.
#
# The archive is unpacked into the wallpaper directory: macOS __MACOSX trees
# and .DS_Store files are not installed, and a single top-level folder is
# flattened so images/videos land directly in the collection directory.
#
# The installer (install.sh) calls this script during setup; install_dotfiles
# also deploys it to ~/.config/hypr/scripts/wallpapers.sh, so packs can be
# listed, added or changed later without rerunning the whole installer.
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

WALLPAPER_RELEASES_API="https://api.github.com/repos/equisdots/background/releases?per_page=20"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpapers"
PACK="${WALLPAPERS_PACK:-}"
LIST=0

msg()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m error:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
wallpapers.sh — download and install an equisdots wallpaper pack

Usage:
  wallpapers.sh [--list] [--pack <tag|none>] [--dir <path>]

Options:
  --list        list the available packs and exit
  --pack TAG    download that release without prompting (none = skip)
  --dir PATH    destination directory (default: ~/.config/hypr/wallpapers)
  -h, --help    show this help

Environment:
  WALLPAPERS_PACK   same as --pack (the flag wins)
  ASSUME_YES=1      non-interactive: skip unless a pack was requested
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --list)   LIST=1 ;;
        --pack)   shift; [ $# -gt 0 ] || die "--pack needs a value"; PACK="$1" ;;
        --pack=*) PACK="${1#*=}" ;;
        --dir)    shift; [ $# -gt 0 ] || die "--dir needs a value"; DEST="$1" ;;
        --dir=*)  DEST="${1#*=}" ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
done

# ── resolve the available packs (newest release first) ─────────────────────
TAGS=()
LABELS=()
URLS=()
if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    while IFS=$'\t' read -r tag label url size; do
        [ -n "$url" ] || continue
        TAGS+=("$tag")
        LABELS+=("$label (${size:-0} MB)")
        URLS+=("$url")
    done < <(curl -fsSL "$WALLPAPER_RELEASES_API" 2>/dev/null | jq -r '
        .[] | select((.assets // []) | length > 0)
        | [.tag_name, .assets[0].name, .assets[0].browser_download_url,
           ((.assets[0].size / 1048576) | floor | tostring)] | @tsv' 2>/dev/null)
fi
if [ "${#URLS[@]}" -eq 0 ]; then
    TAGS=(v1.1.0 v1.0.0)
    LABELS=("Wallpapers-Avex-X-v1.1.0.zip" "background.zip")
    URLS=(
        "https://github.com/equisdots/background/releases/download/v1.1.0/Wallpapers-Avex-X-v1.1.0.zip"
        "https://github.com/equisdots/background/releases/download/v1.0.0/background.zip"
    )
fi

if [ "$LIST" -eq 1 ]; then
    for i in "${!URLS[@]}"; do
        printf '%s\t%s\t%s\n' "${TAGS[$i]}" "${LABELS[$i]}" "${URLS[$i]}"
    done
    exit 0
fi

# ── pick the pack (flag/env, non-interactive skip, or menu) ────────────────
sel=""
if [ -n "$PACK" ]; then
    if [ "$PACK" = "none" ]; then
        msg "Skipping wallpaper download (none requested)."
        exit 0
    fi
    for i in "${!TAGS[@]}"; do
        if [ "$PACK" = "${TAGS[$i]}" ]; then sel="$i"; fi
    done
    [ -n "$sel" ] || die "unknown pack '$PACK' (see: $0 --list)"
elif [ "${ASSUME_YES:-0}" = "1" ]; then
    msg "Wallpapers skipped (-y; set WALLPAPERS_PACK=<tag> to install one)"
    exit 0
else
    echo ""
    msg "Wallpaper collections available (equisdots/background):"
    for i in "${!URLS[@]}"; do
        printf '  %d) %s  [%s]\n' "$((i + 1))" "${LABELS[$i]}" "${TAGS[$i]}"
    done
    printf '  N) skip\n'
    printf 'Choose a pack [1-%d/N]: ' "${#URLS[@]}"
    read -r choice || choice=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#URLS[@]}" ]; then
        sel=$((choice - 1))
    else
        msg "Skipping wallpaper download (you can drop your own files in $DEST)."
        exit 0
    fi
fi

tag="${TAGS[$sel]}"
label="${LABELS[$sel]}"
url="${URLS[$sel]}"

command -v unzip >/dev/null 2>&1 || die "unzip is required to install wallpaper packs"
TMP_ZIP="$(mktemp --suffix=.zip)"
TMP_EXTRACT="$(mktemp -d)"
trap 'rm -f "$TMP_ZIP"; rm -rf "$TMP_EXTRACT"' EXIT

msg "Downloading wallpaper pack $tag ($label)..."
if command -v wget >/dev/null 2>&1; then
    wget --progress=bar:force -O "$TMP_ZIP" "$url" || die "failed to download pack $tag"
elif command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "$TMP_ZIP" "$url" || die "failed to download pack $tag"
else
    die "wget or curl is required to download wallpaper packs"
fi

msg "Extracting wallpapers..."
unzip -qo "$TMP_ZIP" -d "$TMP_EXTRACT" || die "failed to extract the wallpaper pack"

# macOS zips (like the Avex pack) carry a __MACOSX metadata tree and
# .DS_Store files: never install those.
find "$TMP_EXTRACT" -name '__MACOSX' -type d -prune -exec rm -rf {} + 2>/dev/null || true
find "$TMP_EXTRACT" -name '.DS_Store' -delete 2>/dev/null || true

mkdir -p "$DEST"
INNER_DIR=$(find "$TMP_EXTRACT" -mindepth 1 -maxdepth 1 -type d -print -quit)
if [ -n "$INNER_DIR" ] && [ "$(find "$TMP_EXTRACT" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]; then
    # Single top-level folder inside the zip: flatten it.
    cp -r "$INNER_DIR/"* "$DEST/"
else
    cp -r "$TMP_EXTRACT/"* "$DEST/"
fi

ok "Wallpapers installed to $DEST ($(find "$DEST" -type f | wc -l) files in total)"
