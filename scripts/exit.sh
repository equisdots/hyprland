#!/usr/bin/env bash
# Best-effort session exit: reach the compositor even if a target is inactive.
set -uo pipefail

systemctl --user stop graphical-session.target || true
systemctl --user stop graphical-session-pre.target || true

sleep 0.5

hyprctl eval 'hl.dispatch(hl.dsp.exit())' || true

