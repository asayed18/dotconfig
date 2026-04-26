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

apply_wallpaper() {
    echo "🎨 Applying background..."

    local restored=false
    local WP_PATH="$HOME/Pictures/desktop.png"

    if module_enabled "theme/wpg" && command -v wpg &>/dev/null; then
        if [ -n "$(wpg -l 2>/dev/null)" ] && [ -f "$HOME/.config/wpg/.current" ]; then
            echo "✨ Restoring wpgtk theme..."
            if wpg -r; then
                restored=true
            fi
        fi
    fi

    if [ "$restored" = false ] && command -v feh &> /dev/null && [ -f "$WP_PATH" ]; then
        echo "🖼️ Restoring wallpaper with feh: $WP_PATH"
        feh --bg-fill "$WP_PATH"
    fi
}

resync_settings() {
    echo "🔄 Resyncing display and keyboard settings..."
    xset dpms force on || true
    xrandr --auto || true
    sleep 1
    xset dpms force on || true
    setxkbmap -layout us,ara -option grp:alt_shift_toggle
    apply_wallpaper
    echo "✅ Resync complete."
}

# 2. Resume Listener (Watch for system wake-up)
start_resume_listener() {
    if pgrep -f "dbus-monitor.*PrepareForSleep" > /dev/null; then
        echo "📡 Resume listener already running."
        return
    fi

    echo "📡 Starting resume listener..."
    (
        # stdbuf -oL ensures line-buffering so grep catches signals immediately
        stdbuf -oL dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" | while read -r line; do
            if echo "$line" | grep -q "boolean false"; then
                echo "🌙 System resumed from standby. Triggering resync..."
                sleep 3 # Wait for hardware to initialize
                # Use absolute path to ensure accuracy
                bash "$HOME/.config/dotconfig/autostart.sh" --resync
            fi
        done
    ) &
}

# 3. Argument Parsing
if [[ "$1" == "--resync" ]]; then
    resync_settings
    exit 0
fi

# 4. Base Services (Always needed)
echo "🔧 Initializing core services..."

# Ensure Betterlockscreen cache is ready (Fixes "No login screen" issue)
if [ ! -d "$HOME/.cache/betterlockscreen" ] || [ -z "$(ls -A "$HOME/.cache/betterlockscreen" 2>/dev/null)" ]; then
    echo "🔒 Initializing lockscreen cache..."
    betterlockscreen -u "$HOME/Pictures/desktop.png" &
fi

# Initial Resync
resync_settings

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
# Automatic lock on sleep/idle (Corrected --nofork passing)
run xss-lock --transfer-sleep-lock -- betterlockscreen -l dimblur -- --nofork

# 5. Modular App Services (Conditional)
module_enabled "sxhkd" && run sxhkd -c "$HOME/.config/sxhkd/sxhkdrc"
module_enabled "dunst" && run dunst
module_enabled "picom" && run picom -b
module_enabled "mpd"   && run mpd
module_enabled "voice" && run ydotoold

# 6. Bar & Interface
if module_enabled "polybar"; then
    LAUNCH_SCRIPT="$HOME/.config/polybar/launch.sh"
    if [ -f "$LAUNCH_SCRIPT" ]; then
        echo "📊 Launching Polybar via script..."
        bash "$LAUNCH_SCRIPT" &
    else
        run polybar example
    fi
fi

# 7. Resume Listener (Watch for system wake-up)
start_resume_listener

# 8. Local Overrides
[ -f "$HOME/.config/dotconfig/autostart.local" ] && . "$HOME/.config/dotconfig/autostart.local"

echo "--- Finished: $(date) ---"