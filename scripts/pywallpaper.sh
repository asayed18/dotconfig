#!/usr/bin/env bash
# scripts/pywallpaper.sh
# Dynamic Wallpaper & Theme Engine

if [ -z "$1" ]; then
    echo "Usage: pywallpaper <image_path>"
    exit 1
fi

IMG_PATH=$(realpath "$1")

if [ ! -f "$IMG_PATH" ]; then
    echo "Error: Image not found at $IMG_PATH"
    exit 1
fi

echo "🎨 Extracting colors and applying theme from: $(basename "$IMG_PATH")"

# 1. Add and Set the wallpaper in wpgtk
# -a adds it to the library, -s sets it as the active theme
wpg -a "$IMG_PATH"
wpg -s "$(basename "$IMG_PATH")"

# 2. Map templates to their actual config locations (if not already mapped)
wpg -m polybar.base "$HOME/.config/polybar/colors.ini"
wpg -m alacritty.base "$HOME/.config/alacritty/colors.toml"
wpg -m rofi.base "$HOME/.config/rofi/colors.rasi"
wpg -m qutebrowser.base "$HOME/.config/qutebrowser/colors.py"

# Firefox: Find the default-release profile (handling both standard and Snap paths)
FF_PROFILE=$(find "$HOME/.mozilla/firefox" "$HOME/snap/firefox/common/.mozilla/firefox" -maxdepth 2 -type d -name "*.default-release" 2>/dev/null | head -n 1)
if [ -n "$FF_PROFILE" ]; then
    mkdir -p "$FF_PROFILE/chrome"
    wpg -m userChrome.css.base "$FF_PROFILE/chrome/userChrome.css"
fi

# 3. Reload the Desktop Environment and GTK settings
echo "🔥 Triggering Hot Reload..."
# Refresh GTK theme (wpgtk usually handles this, but we force it)
gsettings set org.gnome.desktop.interface gtk-theme "FlatColor" 2>/dev/null
pkill -USR1 -x sxhkd
~/projects/dotconfig/modules/system/autostart/.config/dotconfig/autostart.sh
openbox --reconfigure

echo "✅ Theme applied successfully!"
