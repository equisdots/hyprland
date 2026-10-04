#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · wallpapers-x — X collection shortcut.
#
# Thin wrapper over wallpapers.sh with the pack pre-selected: downloads and
# installs the X collection (equisdots/background v1.0.0, background.zip).
# All wallpapers.sh options are forwarded (--list, --dir, -h, ...).
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/wallpapers.sh" --pack v1.0.0 "$@"
