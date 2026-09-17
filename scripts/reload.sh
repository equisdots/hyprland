#!/usr/bin/env bash
# Reload QuickShell (full QML reload)
QS=""; command -v quickshell >/dev/null 2>&1 && QS=quickshell || command -v qs >/dev/null 2>&1 && QS=qs
if [ -n "$QS" ]; then
    $QS -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call topbar forceReload 2>/dev/null || true
fi

# Sync kitty + nvim themes to the active palette.
bash "$(dirname "${BASH_SOURCE[0]}")/theme-sync.sh" 2>/dev/null || true
