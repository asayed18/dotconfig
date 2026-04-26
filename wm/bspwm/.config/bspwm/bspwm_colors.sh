#!/usr/bin/env bash

if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    . "$HOME/.cache/wal/colors.sh"
    bspc config focused_border_color "$color2"
    bspc config normal_border_color  "$color0"
else
    bspc config focused_border_color "#8f5d62"
    bspc config normal_border_color  "#624043"
fi
