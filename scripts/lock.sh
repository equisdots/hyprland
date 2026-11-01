#!/usr/bin/env bash
set -euo pipefail

# Source and initialize quickshell dynamic caching
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "lock"

BIN=""
if command -v quickshell >/dev/null 2>&1; then
    BIN=quickshell
elif command -v qs >/dev/null 2>&1; then
    BIN=qs
fi
exec "${BIN:-quickshell}" -p ~/.config/hypr/scripts/quickshell/Lock.qml
