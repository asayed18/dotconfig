#!/usr/bin/env bash
# Unified Master Autostart Script (v2: Reliable Edition)

# 1. Environment & Logging
export PATH="$HOME/.local/bin:$PATH"
LOG_DIR="$HOME/.cache/dotconfig"
LOG_FILE="$LOG_DIR/autostart.log"

mkdir -p "$LOG_DIR"
exec > >(tee -i "$LOG_FILE") 2>&1

echo "--- Start: $(date) ---"
echo "🖥️ Current Display: $DISPLAY"

# Load Selections
STATE_FILE="$HOME/.config/dotconfig/state.sh"
if [ -f "$STATE_FILE" ]; then
    . "$STATE_FILE"
    echo "✅ Loaded system state ($SELECTED_OS / $SELECTED_WM)"
else
    echo "⚠️ Warning: System state not found at $STATE_FILE"
fi

# Helper functions
module_enabled() {
    [[ "$SELECTED_MODULES" == *"$1"* ]] && return 0
    return 1
}

run() {
    local cmd=$1
    shift
    if command -v "$cmd" &> /dev/null; then
        if ! pgrep -f "$cmd" > /dev/null; then
            echo "🚀 Launching: $cmd $@"
            "$cmd" "$@" &
        fi
    else
        echo "❌ Error: Command not found - $cmd"
    fi
}

# 2. Base Services (Always needed)
echo "🔧 Initializing core services..."

# GPU & Display Resync (Essential for NVIDIA Resume)
echo "🔄 Resetting GPU synchronization..."
xset dpms force on
xrandr --auto
sleep 0.5 

# Polkit Authentication Agent
POLKIT_PATHS=(
    "/usr/bin/lxpolkit"
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    "/usr/libexec/xfce-polkit"
    "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)

for p in "${POLKIT_PATHS[@]}"; do
    if [ -f "$p" ]; then
        echo "🛡️ Starting Polkit: $p"
        "$p" &
        break
    fi
done

run nm-applet
run xfce4-power-manager --daemon
run udiskie -t
# Automatic lock on sleep/idle
run xss-lock --transfer-sleep-lock -- betterlockscreen -l dimblur

# 3. Modular App Services (Conditional)
module_enabled "sxhkd" && run sxhkd -c "$HOME/.config/sxhkd/sxhkdrc"
module_enabled "dunst" && run dunst
module_enabled "picom" && run picom -b
module_enabled "mpd"   && run mpd

# 4. Bar & Interface
if module_enabled "polybar"; then
    LAUNCH_SCRIPT="$HOME/.config/polybar/launch.sh"
    if [ -f "$LAUNCH_SCRIPT" ]; then
        echo "📊 Launching Polybar via script..."
        bash "$LAUNCH_SCRIPT" &
    else
        run polybar example
    fi
fi

# 5. Robust Theme & Wallpaper Logic
apply_wallpaper() {
    echo "🎨 Applying background..."
    
    # Try wpgtk first if enabled
    if module_enabled "theme/wpg" && command -v wpg &>/dev/null; then
        if [ -n "$(wpg -l 2>/dev/null)" ] && [ -f "$HOME/.config/wpg/.current" ]; then
            echo "✨ Restoring wpgtk theme..."
            wpg -r &
        fi
    fi

    # Fallback to feh if wpg fails or is disabled
    # We always run this as a secondary safety to ensure no black screen
    if command -v feh &> /dev/null; then
        local WP_PATH="$HOME/Pictures/desktop.png"
        if [ -f "$WP_PATH" ]; then
            echo "🖼️ Falling back to feh for $WP_PATH"
            feh --bg-fill "$WP_PATH" &
        fi
    fi
}

apply_wallpaper

# 6. Local Overrides
[ -f "$HOME/.config/dotconfig/autostart.local" ] && . "$HOME/.config/dotconfig/autostart.local"

echo "--- Finished: $(date) ---"
