#!/usr/bin/env bash
# Local checks for the hyprland config repo (no CI):
#   - Lua syntax for every config module with luac -p.
#   - Bash syntax for the installer/scripts with bash -n.
#   - shellcheck (advisory) when available.
#
# Usage: scripts/check.sh
set -u
cd "$(dirname "$0")/.." || exit 1

fail=0

if ! command -v luac >/dev/null 2>&1; then
    echo "error: luac not found (install the Lua compiler)" >&2
    exit 2
fi

lua_total=0
while IFS= read -r f; do
    lua_total=$((lua_total + 1))
    if ! luac -p "$f" >/dev/null 2>&1; then
        echo "luac FAIL: $f"
        fail=1
    fi
done < <(find config -name '*.lua' -not -path '*/.git/*' | sort)
echo "luac: $lua_total Lua modules checked"

sh_total=0
while IFS= read -r f; do
    sh_total=$((sh_total + 1))
    if ! bash -n "$f" 2>/dev/null; then
        echo "bash -n FAIL: $f"
        fail=1
    fi
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck -S warning "$f" >/dev/null 2>&1 || echo "shellcheck note: $f (advisory)"
    fi
done < <(find . -name '*.sh' -not -path './.git/*' | sort)
echo "bash -n: $sh_total scripts checked"

if [ "$fail" -eq 0 ]; then
    echo "hyprland: checks OK"
fi
exit "$fail"
