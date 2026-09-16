#!/usr/bin/env bash

# Source and initialize quickshell dynamic caching
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "lock"

BIN=""
command -v quickshell >/dev/null 2>&1 && BIN=quickshell || \
    command -v qs >/dev/null 2>&1 && BIN=qs
exec "${BIN:-quickshell}" -p ~/.config/hypr/scripts/quickshell/Lock.qml
