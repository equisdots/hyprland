#!/usr/bin/env bash
# run.sh — all local tests for the hyprland repo (no CI).
#
# Usage: tests/run.sh
# Exit: 0 pass · 1 failure · 2 skipped (a test reported environment missing)

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

fail=0
skipped=0

run() {
    echo "== $*"
    "$@"
    local rc=$?
    if [ "$rc" -eq 2 ]; then
        echo "   SKIP (exit 2: environment missing)"
        skipped=$((skipped + 1))
    elif [ "$rc" -ne 0 ]; then
        echo "   FAIL (exit $rc)"
        fail=1
    fi
}

LUA=""
if command -v lua5.5 >/dev/null 2>&1; then
    LUA=lua5.5
elif command -v lua >/dev/null 2>&1; then
    LUA=lua
fi
if [ -n "$LUA" ]; then
    run "$LUA" tests/settings_version_gate_test.lua
    run "$LUA" tests/workspaces_created_handler_test.lua
else
    echo "== lua tests: SKIP (no lua interpreter)"
    skipped=$((skipped + 1))
fi

run bash tests/check_sh_test.sh

if command -v jq >/dev/null 2>&1; then
    run bash tests/plugins_loader_test.sh
else
    echo "== plugins loader: SKIP (no jq)"
    skipped=$((skipped + 1))
fi

if [ "$fail" -eq 0 ]; then
    if [ "$skipped" -gt 0 ]; then
        echo "TESTS: OK ($skipped skipped)"
    else
        echo "TESTS: OK"
    fi
else
    echo "TESTS: FAIL"
fi
exit "$fail"
