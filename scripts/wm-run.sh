#!/usr/bin/env bash
# scripts/wm-run.sh
# Universal WM wrapper that detects bspwm vs other (Openbox/i3)

if pgrep -x bspwm > /dev/null; then
    exec bspc "$@"
else
    exec "$HOME/projects/dotconfig/scripts/obpc.sh" "$@"
fi
