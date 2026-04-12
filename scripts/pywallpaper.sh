#!/usr/bin/env bash
# scripts/pywallpaper.sh
# Dynamic, Module-Aware Wallpaper & Theme Engine

# Load Selections & Environment
STATE_FILE="$HOME/.config/dotconfig/state.sh"
if [ -f "$STATE_FILE" ]; then
    . "$STATE_FILE"
else
    echo "⚠️ Warning: System state not found at $STATE_FILE. Running in generic mode."
fi

# Helper to check if a module is enabled
module_enabled() {
    local mod=$1
    [[ "$SELECTED_MODULES" == *"$mod"* ]] && return 0
    return 1
}

if [ -z "$1" ]; then
    SELECTION=$(find "$HOME/Pictures" -type f | rofi -dmenu -p 'Select Wallpaper')
    if [ -z "$SELECTION" ]; then
        exit 0
    fi
    IMG_PATH=$(realpath "$SELECTION")
else
    IMG_PATH=$(realpath "$1")
fi

if [ ! -f "$IMG_PATH" ]; then
    echo "Error: Image not found at $IMG_PATH"
    exit 1
fi

echo "🎨 Extracting colors and applying theme from: $(basename "$IMG_PATH")"

# 1. Add and Set the wallpaper in wpgtk
# This generates the output files in ~/.config/wpg/templates/
wpg -a "$IMG_PATH"
wpg -s "$(basename "$IMG_PATH")"

# 2. Dynamic Manual Symlinks
echo "🔗 Linking theme files for active modules..."

# Polybar
if module_enabled "polybar"; then
    mkdir -p "$HOME/.config/polybar"
    ln -sf "$HOME/.config/wpg/templates/polybar" "$HOME/.config/polybar/colors.ini"
fi

# Alacritty
if module_enabled "alacritty"; then
    mkdir -p "$HOME/.config/alacritty"
    ln -sf "$HOME/.config/wpg/templates/alacritty" "$HOME/.config/alacritty/colors.toml"
fi

# Rofi
if module_enabled "rofi"; then
    mkdir -p "$HOME/.config/rofi"
    ln -sf "$HOME/.config/wpg/templates/rofi" "$HOME/.config/rofi/colors.rasi"
fi

# Qutebrowser
if module_enabled "qutebrowser"; then
    mkdir -p "$HOME/.config/qutebrowser"
    ln -sf "$HOME/.config/wpg/templates/qutebrowser" "$HOME/.config/qutebrowser/colors.py"
fi



# Firefox
if module_enabled "firefox"; then
    FF_PROFILE=$(find "$HOME/.mozilla/firefox" "$HOME/snap/firefox/common/.mozilla/firefox" -maxdepth 2 -type d -name "*.default-release" 2>/dev/null | head -n 1)
    if [ -n "$FF_PROFILE" ]; then
        mkdir -p "$FF_PROFILE/chrome"
        ln -sf "$HOME/.config/wpg/templates/userChrome.css" "$FF_PROFILE/chrome/userChrome.css"
    fi
fi

# 3. Component-Specific Reloads
echo "🔥 Triggering Hot Reload..."

# Refresh GTK theme
gsettings set org.gnome.desktop.interface gtk-theme "FlatColor" 2>/dev/null
ln -sf "$HOME/.config/wpg/templates/gtk2" "$HOME/.gtkrc-2.0"
mkdir -p "$HOME/.config/gtk-3.0"
ln -sf "$HOME/.config/wpg/templates/gtk3.0" "$HOME/.config/gtk-3.0/gtk.css"

# Hot-reload keybindings
module_enabled "sxhkd" && pkill -USR1 -x sxhkd

# Reload Window Manager
case "$SELECTED_WM" in
    openbox) openbox --reconfigure ;;
    i3)      i3-msg reload ;;
    bspwm)   bspc wm -r ;;
esac

# Relaunch Bar
if module_enabled "polybar"; then
    if [ -f "$HOME/.config/polybar/launch.sh" ]; then
        bash "$HOME/.config/polybar/launch.sh" &
    else
        pkill polybar
        polybar example &
    fi
fi

echo "✅ Theme applied successfully!"
