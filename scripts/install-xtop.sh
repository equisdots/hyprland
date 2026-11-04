#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · xtop — install the latest release into ~/.local/bin.
#
# xtop publishes prebuilt release binaries, so this mirrors install-xfetch.sh:
# resolve the newest GitHub release, download the asset for this architecture,
# verify it against the release SHA256SUMS, and install the binary. No Rust or
# cargo toolchain is required at install time. If xtop is already present it is
# skipped (XTOP_FORCE=1 updates it).
#
# Env overrides: XTOP_REPO, XTOP_DEST, XTOP_TARGET (e.g. an explicit
# x86_64-unknown-linux-musl asset when the host is musl), XTOP_FORCE
# (1 = reinstall/update even when xtop is already present).
# Usage: install-xtop.sh
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="${XTOP_REPO:-xtop-cli/xtop}"
DEST="${XTOP_DEST:-$HOME/.local/bin}"
TARGET="${XTOP_TARGET:-}"

msg()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m error:\033[0m %s\n' "$*" >&2; exit 1; }

# Find an installed copy without relying on PATH alone (TTY installs where
# ~/.local/bin or ~/.cargo/bin is not exported yet).
find_tool() {
    local tool="$1" candidate
    for candidate in "$DEST/$tool" "$HOME/.local/bin/$tool" "$HOME/.cargo/bin/$tool"; do
        if [ -x "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    candidate="$(command -v "$tool" 2>/dev/null || true)"
    if [ -n "$candidate" ]; then
        printf '%s' "$candidate"
        return 0
    fi
    return 1
}

# Package-managed installs (AUR xfetch-bin/xfetch-git, xtop-bin/xtop-git, or a
# distro package) must never be shadowed by a ~/.local/bin copy. Returns the
# owning package name, or fails when the tool is not package-managed.
package_managed() {
    local found="$1" tool="$2" pkg
    if command -v pacman >/dev/null 2>&1; then
        if [ -n "$found" ] && pkg="$(pacman -Qoq "$found" 2>/dev/null)"; then
            printf '%s' "$pkg"
            return 0
        fi
        for pkg in "$tool-bin" "$tool-git" "$tool"; do
            if pacman -Qq "$pkg" >/dev/null 2>&1; then
                printf '%s' "$pkg"
                return 0
            fi
        done
    fi
    return 1
}

FOUND="$(find_tool xtop || true)"
# Check package ownership even when the binary is not on PATH (a TTY install
# may not export /usr/bin or ~/.local/bin yet).
if PKG="$(package_managed "$FOUND" xtop)"; then
    mkdir -p "$HOME/.config/xtop/themes"
    ok "xtop is managed by $PKG${FOUND:+ ($FOUND)}; skipping (update it with your package manager)"
    exit 0
fi
if [ -n "$FOUND" ] && [[ "${XTOP_FORCE:-0}" != "1" ]]; then
    mkdir -p "$HOME/.config/xtop/themes"
    ok "xtop is already installed ($FOUND); skipping"
    exit 0
fi

if [ -z "$TARGET" ]; then
    case "$(uname -m)" in
        x86_64)        TARGET="x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) TARGET="aarch64-unknown-linux-gnu" ;;
        *) die "unsupported architecture: $(uname -m) (set XTOP_TARGET to a release asset target)" ;;
    esac
fi

for c in curl jq tar sha256sum; do
    command -v "$c" >/dev/null 2>&1 || die "$c is required"
done

API="https://api.github.com/repos/$REPO/releases/latest"
msg "Resolving the latest xtop release..."
RELEASE_JSON="$(curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 --retry-delay 1 "$API")" || die "could not reach the GitHub API"
TAG="$(printf '%s' "$RELEASE_JSON" | jq -r '.tag_name // empty')"
[ -n "$TAG" ] || die "could not read the latest release tag"
VERSION="${TAG#v}"

ASSET="$(printf '%s' "$RELEASE_JSON" | jq -r --arg a "$TARGET" \
    '.assets[].name | select(contains($a)) | select(endswith(".tar.gz"))' | head -1)"
[ -n "$ASSET" ] || die "no release asset for $TARGET"
URL="$(printf '%s' "$RELEASE_JSON" | jq -r --arg n "$ASSET" \
    '.assets[] | select(.name == $n) | .browser_download_url')"
SUMS_URL="$(printf '%s' "$RELEASE_JSON" | jq -r \
    '.assets[] | select(.name == "SHA256SUMS") | .browser_download_url')"
[ -n "$SUMS_URL" ] || warn "the release has no SHA256SUMS; continuing without verification"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

msg "Downloading $ASSET..."
curl -fsSL --connect-timeout 10 --max-time 300 --retry 2 --retry-delay 1 "$URL" -o "$TMP/$ASSET" || die "download failed"

if [ -n "$SUMS_URL" ]; then
    curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 --retry-delay 1 "$SUMS_URL" -o "$TMP/SHA256SUMS" || die "could not download SHA256SUMS"
    EXPECTED="$(grep " $ASSET\$" "$TMP/SHA256SUMS" | awk '{print $1}' | head -1 || true)"
    ACTUAL="$(sha256sum "$TMP/$ASSET" | awk '{print $1}')"
    if [ -z "$EXPECTED" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
        die "checksum mismatch for $ASSET"
    fi
    ok "checksum verified"
fi

msg "Installing..."
tar -xzf "$TMP/$ASSET" -C "$TMP"
BIN="$(find "$TMP" -type f -name xtop -perm -u+x | head -1)"
[ -n "$BIN" ] || BIN="$(find "$TMP" -type f -name xtop | head -1)"
[ -n "$BIN" ] || die "xtop binary not found in the archive"
mkdir -p "$DEST"
install -Dm755 "$BIN" "$DEST/xtop"
mkdir -p "$HOME/.config/xtop/themes"
ok "xtop $VERSION -> $DEST/xtop (config dir ready for theme-sync)"
