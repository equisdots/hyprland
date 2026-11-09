#!/usr/bin/env bash
# restore-monitors.sh --mode: settings.json → monitorsMode gating.
# No hyprctl and no sleeps are involved (--mode exits before the applies).
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)" || exit 2
SCRIPT="$ROOT/scripts/restore-monitors.sh"
fail=0
count=0

mode_of() { # $1 = settings content or "__missing__"
    local tmp
    tmp="$(mktemp -d)"
    export HOME="$tmp"
    if [ "$1" != "__missing__" ]; then
        mkdir -p "$tmp/.config/hypr"
        printf '%s\n' "$1" > "$tmp/.config/hypr/settings.json"
    fi
    shift
    bash "$SCRIPT" "$@"
    local rc=$?
    rm -rf "$tmp"
    return $rc
}

check() { # $1 = expected, $2 = label, rest = args to mode_of
    local want="$1" label="$2"
    shift 2
    local got
    got="$(mode_of "$@")"
    count=$((count + 1))
    if [ "$got" = "$want" ]; then
        printf ' ok  %s\n' "$label"
    else
        printf 'FAIL %s (got %s, want %s)\n' "$label" "$got" "$want"
        fail=1
    fi
}

check "static"     "no settings file"        "__missing__" --mode
check "static"     "no monitorsMode key"     "{}" --mode
check "static"     "explicit static"         '{"monitorsMode":"static"}' --mode
check "off"        "explicit off"            '{"monitorsMode":"off"}' --mode
check "reconciler" "explicit reconciler"     '{"monitorsMode":"reconciler"}' --mode
check "reconciler" "pretty json + spaces"    '{
  "monitorsMode": "reconciler",
  "other": true
}' --mode
check "static"     "invalid value"           '{"monitorsMode":"bogus"}' --mode
check "reconciler" "--daemon overrides auto" '{"monitorsMode":"off"}' --daemon --mode
check "static"     "--once overrides"        '{"monitorsMode":"reconciler"}' --once --mode

if [ "$fail" -eq 0 ]; then
    printf 'restore-monitors mode: %d checks OK\n' "$count"
fi
exit "$fail"
