#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# equisdots · wallpapers-avex — Avex collection shortcut.
#
# Thin wrapper over wallpapers.sh with the pack pre-selected: downloads and
# installs the Avex collaboration (equisdots/background v1.1.0,
# Wallpapers-Avex-X-v1.1.0.zip).
# All wallpapers.sh options are forwarded (--list, --dir, -h, ...).
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/wallpapers.sh" --pack v1.1.0 "$@"
