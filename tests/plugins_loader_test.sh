#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# plugins_loader_test.sh — local test for config/hypr/plugins.lua (no CI).
#
# Covers the id-integrity contract: a directory whose manifest id was already
# provided by another one is recorded as status "collision" in the report
# (never silent), while normal plugins load normally. Runs entirely in a
# temp tree via the loader's EQUISDOTS_* overrides.
#
# Usage: bash tests/plugins_loader_test.sh   (from the hyprland repo root)
# Exit: 0 pass · 1 failure · 2 environment missing (infra)
# ═══════════════════════════════════════════════════════════════════════════
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR="$HERE/../config/hypr"

for c in lua jq; do
    command -v "$c" >/dev/null 2>&1 || { echo "SKIP: $c missing"; exit 2; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
ok()  { printf '\033[32m ok \033[0m %s\n' "$*"; }
bad() { printf '\033[31mFAIL\033[0m %s\n' "$*"; fail=1; }
check() { if eval "$1"; then ok "$2"; else bad "$2"; fi; }

# ── fixtures ────────────────────────────────────────────────────────────────
mkdir -p "$TMP/managed/solo" "$TMP/managed/dup-a" "$TMP/managed/dup-b" \
         "$TMP/managed/wrongname" "$TMP/managed/off" "$TMP/user" "$TMP/cache"

manifest() { # <dir> <id> <name> [scope]
    cat > "$1/plugin.json" <<JSON
{ "id": "$2", "name": "$3", "version": "0.1.0", "author": "test", "description": "loader fixture", "type": "hypr", "scope": "$4", "defaultEnabled": true }
JSON
}

manifest "$TMP/managed/solo" "solo" "Solo" "solo"
cat > "$TMP/managed/solo/hypr.lua" <<'EOF'
local mod = ...
mod.bind("SUPER + T", mod.exec("true"), { label = "Solo: test" })
EOF

manifest "$TMP/managed/dup-a" "dup" "Dup A" "dupA"
cat > "$TMP/managed/dup-a/hypr.lua" <<'EOF'
local mod = ...
mod.bind("SUPER + A", mod.exec("true"), { label = "Dup A: test" })
EOF

manifest "$TMP/managed/dup-b" "dup" "Dup B" "dupB"
cat > "$TMP/managed/dup-b/hypr.lua" <<'EOF'
local mod = ...
mod.bind("SUPER + B", mod.exec("true"), { label = "Dup B: test" })
EOF

# folder name intentionally != manifest id (malformed install)
manifest "$TMP/managed/wrongname" "other" "Other" "other"

# disabled plugin: no fragment runs
manifest "$TMP/managed/off" "off" "Off" "off"
mkdir -p "$TMP/managed/off"
cat > "$TMP/managed/off/settings.json" <<'EOF'
{ "off": { "enabled": false } }
EOF

# ── run the loader ──────────────────────────────────────────────────────────
REPORT="$TMP/cache/plugins-report.json"
EQUISDOTS_PLUGINS_DIR="$TMP/managed" \
EQUISDOTS_PLUGINS_USER="$TMP/user" \
EQUISDOTS_SETTINGS="$TMP/settings.json" \
EQUISDOTS_PLUGINS_REPORT="$REPORT" \
EQUISDOTS_API_FILE="$TMP/no-api.json" \
lua -e '
package.path = "'"$HYPR"'/?.lua;" .. package.path
-- Stub Hyprland API: the loader injects it into fragments as mod.exec etc.
hl = {
    dsp = { exec_cmd = function(c) return { kind = "exec", cmd = c } end },
    bind = function() end,
}
local loader = require("plugins")
loader.load()
' || { bad "loader run failed"; exit 1; }

# ── assertions ──────────────────────────────────────────────────────────────
check "jq -e . \"$REPORT\" >/dev/null" "report is valid JSON"

check "jq -e '[.[] | select(.id == \"solo\") | .status] == [\"ok\"]' \"$REPORT\" >/dev/null" \
      "normal plugin loads ok"

check "jq -e '[.[] | select(.id == \"solo\") | .binds[0].label] == [\"Solo: test\"]' \"$REPORT\" >/dev/null" \
      "normal plugin binds are recorded"

check "[ \"\$(jq -r '[.[] | select(.id == \"dup\" and .status == \"ok\")] | length' \"$REPORT\")\" = 1 ]" \
      "first duplicate id wins (exactly one ok)"

check "[ \"\$(jq -r '[.[] | select(.id == \"dup\" and .status == \"collision\")] | length' \"$REPORT\")\" = 1 ]" \
      "second duplicate id is recorded as collision"

check "jq -e '[.[] | select(.status == \"collision\") | .error] | length == 1 and (.[0] | contains(\"already provided by\"))' \"$REPORT\" >/dev/null" \
      "collision entry names the winner directory"

check "jq -e '[.[] | select(.id == \"off\") | .status] == [\"disabled\"]' \"$REPORT\" >/dev/null" \
      "disabled plugin reported as disabled"

check "jq -e '[.[] | select(.id == \"other\") | .status] == [\"ok\"]' \"$REPORT\" >/dev/null" \
      "folder/id mismatch still loads (scan flags the mismatch, loader the id)"

[ "$fail" = 0 ] && printf 'LOADER TEST: OK\n' || printf 'LOADER TEST: FAILURES\n'
exit "$fail"
