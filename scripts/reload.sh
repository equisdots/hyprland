#!/usr/bin/env bash
# Reload QuickShell (full QML reload)
QS=""; command -v quickshell >/dev/null 2>&1 && QS=quickshell || command -v qs >/dev/null 2>&1 && QS=qs
if [ -n "$QS" ]; then
    $QS -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call topbar forceReload 2>/dev/null || true
fi

# Sync kitty + nvim themes to the active palette. The engine lives in its own
# repo (equisdots/theme-sync), installed by `dots` under ~/.local/share/equisdots.
ENGINE="${XDG_DATA_HOME:-$HOME/.local/share}/equisdots/theme-sync/theme-sync.sh"
[ -x "$ENGINE" ] || ENGINE="$HOME/.local/bin/theme-sync"
bash "$ENGINE" 2>/dev/null || true
