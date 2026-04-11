#!/usr/bin/env bash
WALLPAPER="$(cat "$HOME/.config/wpg/.current" 2>/dev/null)"
[ -n "$WALLPAPER" ] && wpg -rs "$WALLPAPER"