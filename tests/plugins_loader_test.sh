#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# plugins_loader_test.sh — local test for config/hypr/plugins.lua (no CI).
#
# Covers the loader contracts:
#   · id integrity — a directory whose manifest id was already provided by
#     another one is recorded as status "collision" (never silent);
#   · bind overrides — the user's own key lives in the plugin's settings file
#     (<scope>.binds.<id> = "KEY" | false) and the loader applies it (the
#     plugin owns the action; the user owns the key);
#   · carry-over — a disabled plugin keeps its last known binds visible,
#     marked bindsCached (the keybinds editor shows what would come back).
#
# Runs entirely in a temp tree via the loader's EQUISDOTS_* overrides.
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
         "$TMP/managed/wrongname" "$TMP/managed/reb" "$TMP/managed/togg" \
         "$TMP/user" "$TMP/cache"

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

# bind overrides: one rebound, one disabled by the user
manifest "$TMP/managed/reb" "reb" "Reb" "reb"
cat > "$TMP/managed/reb/hypr.lua" <<'EOF'
local mod = ...
mod.bind("SUPER + R", mod.exec("true"), { label = "Reb: on",  id = "reb-on" })
mod.bind("SUPER + N", mod.exec("true"), { label = "Reb: off", id = "reb-off" })
EOF
cat > "$TMP/managed/reb/settings.json" <<'EOF'
{ "reb": { "binds": { "reb-on": "SUPER + SHIFT + T", "reb-off": false } } }
EOF

# carry-over fixture: starts enabled, gets disabled between runs
manifest "$TMP/managed/togg" "togg" "Togg" "togg"
cat > "$TMP/managed/togg/hypr.lua" <<'EOF'
local mod = ...
mod.bind("SUPER + G", mod.exec("true"), { label = "Togg: toggle" })
EOF

# ── the loader (invoked once per phase) ─────────────────────────────────────
REPORT="$TMP/cache/plugins-report.json"
run_loader() {
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
    '
}

# ── phase 1: load ───────────────────────────────────────────────────────────
run_loader || { bad "loader run failed"; exit 1; }

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

check "jq -e '[.[] | select(.id == \"other\") | .status] == [\"ok\"]' \"$REPORT\" >/dev/null" \
      "folder/id mismatch still loads (scan flags the mismatch, loader the id)"

# bind overrides
check "jq -e '[.[] | select(.id == \"reb\") | .binds[] | select(.id == \"reb-on\") | .key] == [\"SUPER + SHIFT + T\"]' \"$REPORT\" >/dev/null" \
      "override rebinds the key"

check "jq -e '[.[] | select(.id == \"reb\") | .binds[] | select(.id == \"reb-on\") | .overridden] == [true]' \"$REPORT\" >/dev/null" \
      "override is marked on the report"

check "jq -e '[.[] | select(.id == \"reb\") | .binds[] | select(.id == \"reb-on\") | .defaultKey] == [\"SUPER + R\"]' \"$REPORT\" >/dev/null" \
      "override keeps the default key for reset"

check "jq -e '[.[] | select(.id == \"reb\") | .binds[] | select(.id == \"reb-off\") | .disabled] == [true]' \"$REPORT\" >/dev/null" \
      "false override disables that single bind"

check "jq -e '[.[] | select(.id == \"reb\") | .scope] == [\"reb\"]' \"$REPORT\" >/dev/null" \
      "report entry carries the settings scope"

# ── phase 2: carry-over (disable togg between runs) ─────────────────────────
check "jq -e '[.[] | select(.id == \"togg\") | .binds[0].label] == [\"Togg: toggle\"]' \"$REPORT\" >/dev/null" \
      "togg loads with its bind (before disabling)"

cat > "$TMP/managed/togg/settings.json" <<'EOF'
{ "togg": { "enabled": false } }
EOF
run_loader || { bad "loader re-run failed"; exit 1; }

check "jq -e '[.[] | select(.id == \"togg\") | .status] == [\"disabled\"]' \"$REPORT\" >/dev/null" \
      "disabled plugin reported as disabled"

check "jq -e '[.[] | select(.id == \"togg\") | .bindsCached] == [true]' \"$REPORT\" >/dev/null" \
      "disabled plugin carries last known binds (cached)"

check "jq -e '[.[] | select(.id == \"togg\") | .binds[0].label] == [\"Togg: toggle\"]' \"$REPORT\" >/dev/null" \
      "cached binds keep their labels"

[ "$fail" = 0 ] && printf 'LOADER TEST: OK\n' || printf 'LOADER TEST: FAILURES\n'
exit "$fail"
