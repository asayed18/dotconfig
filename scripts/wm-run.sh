#!/usr/bin/env bash
# scripts/wm-run.sh
# Universal WM wrapper that detects bspwm vs other (Openbox/i3)

if pgrep -x bspwm > /dev/null; then
    exec bspc "$@"
elif pgrep -x i3 > /dev/null; then
    # Pass through or map to i3-msg
    exec i3-msg "$@"
else
    # Fallback to Openbox Power Control
    exec "$HOME/projects/dotconfig/scripts/obpc.sh" "$@"
fi
