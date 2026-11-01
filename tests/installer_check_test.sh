#!/usr/bin/env bash
# installer_check_test.sh — safe sandbox test for `install.sh --dotfiles-only`.
#
# What this covers:
#   - the dotfiles deployment (copy of config/hypr and scripts/)
#   - the deployed local config self-check (scripts/check.sh), including the
#     "Config self-check passed" message printed by run_config_check()
#
# What this intentionally does NOT cover:
#   - the package installation, NVIDIA driver and PAM system paths. They call
#     pacman/sudo/systemctl against the real machine and cannot be exercised
#     safely in a temporary HOME. Keep them out of this sandbox test.
#
# The sandbox:
#   - temp HOME and XDG directories (nothing touches the real user config);
#   - a fake Shell.qml so install_user_payload() does not call `dots install`;
#   - stubs for git/wget/curl/sudo/chsh/systemctl/loginctl/notify-send, so the
#     run never reaches the network or mutates the system.
#
# Exit codes: 0 pass, 1 failure, 2 skip (missing environment, e.g. luac).

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)" || { echo "installer check test: mktemp failed" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

fail=0
ok()  { printf ' ok   %s\n' "$*"; }
bad() { printf ' FAIL %s\n' "$*"; fail=1; }

# The deployed check.sh requires luac for the Lua syntax pass. Without it the
# self-check warns instead of passing, so report the test as skipped.
if ! command -v luac >/dev/null 2>&1; then
    echo "installer check test: SKIP (luac not found)"
    exit 2
fi

# ── sandbox layout ──────────────────────────────────────────────────────────
SB_HOME="$TMP/home"
mkdir -p "$SB_HOME/.config" "$SB_HOME/.local/state" \
         "$SB_HOME/.local/share" "$SB_HOME/.cache" \
         "$SB_HOME/.config/hypr/scripts/quickshell"

# Pretend the Quickshell payload is already installed. install_user_payload()
# returns early on this file, so `dots install` is never reached.
printf '// sandbox marker: payload already placed\n' \
    > "$SB_HOME/.config/hypr/scripts/quickshell/Shell.qml"

# ── command stubs ───────────────────────────────────────────────────────────
BIN="$TMP/bin"
mkdir -p "$BIN"

# git/wget/curl: never touch the network. Returning success makes the optional
# installers report "installer not found"/skip instead of failing the run.
for cmd in git wget curl chsh systemctl loginctl notify-send; do
    cat > "$BIN/$cmd" <<'FAKE'
#!/usr/bin/env bash
# Sandbox stub: succeed without touching the system.
exit 0
FAKE
    chmod +x "$BIN/$cmd"
done

# sudo: never escalate in the sandbox. A no-op is safer than executing the
# wrapped command (e.g. `sudo pacman -S ...` from the kitty shader step).
cat > "$BIN/sudo" <<'FAKE'
#!/usr/bin/env bash
# Sandbox stub: do not run privileged commands.
exit 0
FAKE
chmod +x "$BIN/sudo"

# ── run the installer ───────────────────────────────────────────────────────
out="$TMP/install.out"
(
    cd "$ROOT" || exit 1
    HOME="$SB_HOME" \
    XDG_CONFIG_HOME="$SB_HOME/.config" \
    XDG_STATE_HOME="$SB_HOME/.local/state" \
    XDG_DATA_HOME="$SB_HOME/.local/share" \
    XDG_CACHE_HOME="$SB_HOME/.cache" \
    PATH="$BIN:$PATH" \
    SET_ZSH_DEFAULT=n \
    bash install.sh --dotfiles-only
) >"$out" 2>&1
rc=$?

# ── assertions ──────────────────────────────────────────────────────────────
if [ "$rc" -eq 0 ]; then
    ok "install.sh --dotfiles-only exits 0"
else
    bad "install.sh --dotfiles-only exit $rc"
    sed 's/^/      /' "$out"
fi

if grep -q 'Config self-check passed' "$out"; then
    ok "deployed self-check reports success"
else
    bad "missing 'Config self-check passed' in the installer output"
    tail -20 "$out" | sed 's/^/      /'
fi

if [ -f "$SB_HOME/.config/hypr/hyprland.lua" ]; then
    ok "hyprland.lua deployed"
else
    bad "$SB_HOME/.config/hypr/hyprland.lua missing"
fi

if [ -f "$SB_HOME/.config/hypr/scripts/check.sh" ]; then
    ok "scripts/check.sh deployed"
else
    bad "$SB_HOME/.config/hypr/scripts/check.sh missing"
fi

# The payload guard must have been honoured: no dots/theme-sync directory was
# created by this run.
if [ ! -e "$SB_HOME/.local/share/equisdots/dots" ]; then
    ok "dots install skipped (Shell.qml guard)"
else
    bad "dots install was attempted despite the Shell.qml guard"
fi

[ "$fail" -eq 0 ] && echo "INSTALLER CHECK TEST: OK"
exit "$fail"
