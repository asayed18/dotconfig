#!/usr/bin/env bash
# Unified Master Autostart Script

# 1. Load Selections & Environment
STATE_FILE="$HOME/.config/dotconfig/state.sh"
[ -f "$STATE_FILE" ] && . "$STATE_FILE"

# Helper to check if a module is enabled
module_enabled() {
    local mod=$1
    [[ "$SELECTED_MODULES" == *"$mod"* ]] && return 0
    return 1
}

# Helper to run a tool only if it exists and isn't already running
run() {
    local cmd=$1
    shift
    if command -v "$cmd" &> /dev/null; then
        # Use -f (full command line) to avoid the 15-character name limit warning
        if ! pgrep -f "$cmd" > /dev/null; then
            "$cmd" "$@" &
        fi
    fi
}

# 2. System Services (OS-Aware)
echo "🚀 Starting Unified Autostart for $SELECTED_OS..."

# Polkit Authentication Agent
# Searches common paths for both Ubuntu/Debian and Arch
POLKIT_PATHS=(
    "/usr/bin/lxpolkit"                                     # Ubuntu/Debian
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" # Arch
    "/usr/libexec/xfce-polkit"                              # Fallback
    "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)

for p in "${POLKIT_PATHS[@]}"; do
    if [ -f "$p" ]; then
        "$p" &
        break
    fi
done

# Hardware & Connectivity
run nm-applet
run xfce4-power-manager --daemon
run udiskie -t

# 3. Modular App Services
module_enabled "sxhkd" && run sxhkd -c "$HOME/.config/sxhkd/sxhkdrc"
module_enabled "dunst" && run dunst
module_enabled "picom" && run picom -b
module_enabled "mpd"   && { mkdir -p "$HOME/.mpd/playlists"; touch "$HOME/.mpd/database1" "$HOME/.mpd/state"; run mpd; }

# 4. Bar & Appearance
# Note: Polybar usually needs its own launch script to handle multi-monitor
if module_enabled "polybar"; then
    if [ -f "$HOME/.config/polybar/launch.sh" ]; then
        bash "$HOME/.config/polybar/launch.sh" &
    else
        run polybar
    fi
fi

# Apply Theme / Wallpaper
if module_enabled "wpg"; then
    # Only restore if a theme has been set previously
    [ -f "$HOME/.config/wpg/.current" ] && wpg -rs &
elif command -v feh &> /dev/null; then
    # Fallback wallpaper if wpg isn't used
    feh --bg-fill "$HOME/Pictures/desktop.png" &
fi

# 5. User Overrides
[ -f "$HOME/.config/dotconfig/autostart.local" ] && bash "$HOME/.config/dotconfig/autostart.local"

# Wallpaper Auto-Hook Watcher
~/projects/dotconfig/scripts/wallpaper-watcher.sh &
