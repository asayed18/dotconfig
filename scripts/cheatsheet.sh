#!/bin/bash

# Define potential sxhkdrc paths
USER_SXHKDRC="$HOME/.config/sxhkd/sxhkdrc"
REPO_SXHKDRC="$(dirname "$(readlink -f "$0")")/../modules/system/sxhkd/.config/sxhkd/sxhkdrc"

# Determine which one to use
if [[ -f "$USER_SXHKDRC" ]]; then
    SXHKDRC="$USER_SXHKDRC"
elif [[ -f "$REPO_SXHKDRC" ]]; then
    SXHKDRC="$REPO_SXHKDRC"
else
    echo "Error: sxhkdrc not found!"
    exit 1
fi

# Parse logic
parse_cheatsheet() {
    awk '/^#/{desc=$0} /^[A-Za-z0-9]/{if(desc) print desc " -> " $0; desc=""}' "$SXHKDRC" | \
        sed 's/^# //g' | \
        sed 's/^#//g'
}

# If run with --list or as a Rofi mode (stdout)
if [[ "$1" == "--list" ]]; then
    parse_cheatsheet
    exit 0
fi

# Default behavior: Show in Rofi
parse_cheatsheet | rofi -dmenu -i -p "Keybindings" -theme-str 'window {width: 50%;}'

