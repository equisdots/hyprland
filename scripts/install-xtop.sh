#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · xtop — build the latest main from source into ~/.local/bin.
#
# xtop publishes no releases, so the script clones (or updates) xtop-cli/xtop
# and builds with cargo. The build cache lives outside the checkout so updates
# stay incremental. It also creates ~/.config/xtop so theme-sync can apply the
# palette to its themes.
#
# Env overrides: XTOP_REPO, XTOP_REF (default main), XTOP_DEST.
# Usage: install-xtop.sh
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="${XTOP_REPO:-xtop-cli/xtop}"
REF="${XTOP_REF:-main}"
DEST="${XTOP_DEST:-$HOME/.local/bin}"
SRC="${XDG_CACHE_HOME:-$HOME/.cache}/equisdots/xtop-src"
BUILD="${XDG_CACHE_HOME:-$HOME/.cache}/equisdots/xtop-build"

msg()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m error:\033[0m %s\n' "$*" >&2; exit 1; }

for c in git cargo; do
    command -v "$c" >/dev/null 2>&1 || die "$c is required (rust provides cargo)"
done

if [ -d "$SRC/.git" ]; then
    msg "Updating xtop checkout ($REF)..."
    git -C "$SRC" fetch --depth 1 origin "$REF" --quiet
    git -C "$SRC" reset --hard FETCH_HEAD --quiet
else
    msg "Cloning xtop ($REF)..."
    mkdir -p "$(dirname "$SRC")"
    git clone --depth 1 --branch "$REF" "https://github.com/$REPO" "$SRC" --quiet
fi

msg "Building xtop (cargo, release)..."
mkdir -p "$BUILD"
if CARGO_TARGET_DIR="$BUILD" cargo build --release --locked --manifest-path "$SRC/Cargo.toml"; then
    :
else
    warn "--locked build failed; retrying without the lockfile"
    CARGO_TARGET_DIR="$BUILD" cargo build --release --manifest-path "$SRC/Cargo.toml" \
        || die "cargo build failed"
fi

BIN="$BUILD/release/xtop"
[ -x "$BIN" ] || die "the build did not produce $BIN"
mkdir -p "$DEST"
install -Dm755 "$BIN" "$DEST/xtop"
mkdir -p "$HOME/.config/xtop"
ok "xtop -> $DEST/xtop (config dir ready for theme-sync)"
