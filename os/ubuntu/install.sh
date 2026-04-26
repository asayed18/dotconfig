#!/bin/bash
# os/ubuntu/install.sh
# Modular & Strict Ubuntu package resolver for dotfiles

set -e

# Configuration
APT_FLAGS="-y --no-install-recommends"
MODULES_LIST="$@"

echo "🛠️ Starting LEAN installation for Ubuntu..."
echo "Modules selected: $MODULES_LIST"

# 1. Base Foundations
echo "📝 Assembling Package Queue..."
PKG_QUEUE="lxappearance nitrogen feh lxpolkit udiskie dunst picom sxhkd xss-lock \
    xfce4-power-manager network-manager-gnome pulseaudio-utils xclip build-essential \
    curl wget git gawk util-linux wmctrl xdotool inotify-tools i3lock dmenu \
    brightnessctl redshift fonts-noto-color-emoji fonts-font-awesome arc-theme \
    python3-pip python3-venv pipx imagemagick bc vim glow screenkey \
    alsa-utils libnotify-bin ydotool"

DO_NVIDIA_FIX=false
# 1a. NVIDIA Check
if lspci | grep -qi "NVIDIA"; then
    echo "🏎️ NVIDIA GPU detected. Queueing recovery optimizations..."
    DO_NVIDIA_FIX=true
fi

# 2. Selectively Install Apps based on arguments
add_to_queue() {
    local mod_name=$1
    shift
    local pkg_name="$@"
    if [[ "$MODULES_LIST" == *"$mod_name"* ]]; then
        echo "📦 Adding module to queue: $mod_name..."
        PKG_QUEUE+=" $pkg_name"
    fi
}

# --- Terminals ---
add_to_queue "alacritty" "alacritty"
add_to_queue "kitty" "kitty"

# --- Window Managers ---
add_to_queue "openbox" "openbox obconf"
add_to_queue "bspwm" "bspwm sxhkd"
add_to_queue "i3" "i3-wm i3status i3lock"

# --- Shells ---
add_to_queue "zsh" "zsh"
add_to_queue "fish" "fish"

# --- File Managers ---
add_to_queue "thunar" "thunar"
add_to_queue "pcmanfm" "pcmanfm"

# --- Browsers ---
add_to_queue "qutebrowser" "qutebrowser"
add_to_queue "firefox" "firefox"

# --- System Components (Polybar / Rofi) ---
add_to_queue "polybar" "polybar"
add_to_queue "rofi" "rofi"

# --- Media ---
add_to_queue "mpv" "mpv"
add_to_queue "mpd" "mpd"
add_to_queue "ncmpcpp" "ncmpcpp"

# --- VCS ---
add_to_queue "git" "git"

# --- Services ---
add_to_queue "redshift" "redshift"

# --- Tools ---
add_to_queue "voice" "ffmpeg"

# --- Themes ---
add_to_queue "theme" "papirus-icon-theme"

# 🚀 Execute Master Batch
echo "🔥 Executing Master Batch Installation..."
sudo apt update
sudo apt install $APT_FLAGS $PKG_QUEUE

# ⚙️ Post-Install Configurations
if [ "$DO_NVIDIA_FIX" = true ]; then
    echo "⚙️ Applying NVIDIA Power Management configuration..."
    echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp" | sudo tee /etc/modprobe.d/nvidia-power-management.conf
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service || true
fi

install_if_requested() { :; } # No-op for compatibility with remaining logic
install_if_requested "wpg" ""

# WPGTK & Pywal installation (requires pipx)
if [[ "$MODULES_LIST" == *"wpg"* ]]; then
    pipx install wpgtk --force
    pipx inject wpgtk haishoku  # Add better color extraction backend
    touch "$HOME/.Xresources"   # Prevent xrdb errors
    export PATH="$HOME/.local/bin:$PATH"
fi

if [[ "$MODULES_LIST" == *"voice"* ]]; then
    python3 -m pip install --user --upgrade faster-whisper
fi

# 4. Third-Party / Script-based Installs
# SF Pro / SF UI Font (required for Openbox Raven-Crimson theme)
if ! fc-list | grep -qi "SF Pro" && ! fc-list | grep -qi "SF UI"; then
    echo "Installing SF Pro fonts..."
    mkdir -p "$HOME/.local/share/fonts/SFPro"
    curl -fsSL -L "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/refs/heads/master.zip" -o /tmp/sfpro.zip
    unzip -qo /tmp/sfpro.zip -d /tmp/sfpro_extracted
    cp /tmp/sfpro_extracted/San-Francisco-Pro-Fonts-master/*.otf "$HOME/.local/share/fonts/SFPro/"
    rm -rf /tmp/sfpro.zip /tmp/sfpro_extracted
    fc-cache -f "$HOME/.local/share/fonts/SFPro"
fi

# Oh-My-Zsh (non-interactive)
if [[ "$MODULES_LIST" == *"zsh"* ]] && [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Betterlockscreen
if ! command -v betterlockscreen &> /dev/null; then
    echo "Installing betterlockscreen..."
    sudo apt install $APT_FLAGS i3lock imagemagick bc
    sudo curl -fsSL "https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/betterlockscreen" -o /usr/local/bin/betterlockscreen
    sudo chmod +x /usr/local/bin/betterlockscreen
fi

# --- Fonts ---
# CodeNewRoman Nerd Font (used in Polybar, Rofi, Kitty)
if ! fc-list | grep -qi "CodeNewRoman"; then
    echo "Installing CodeNewRoman Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts/CodeNewRoman"
    curl -fsSL -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CodeNewRoman.zip" -o /tmp/font.zip
    unzip -qo /tmp/font.zip -d "$HOME/.local/share/fonts/CodeNewRoman"
    rm /tmp/font.zip
fi

# JetBrainsMono Nerd Font (used in Alacritty)
if ! fc-list | grep -qi "JetBrainsMono"; then
    echo "Installing JetBrainsMono Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
    curl -fsSL -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o /tmp/font.zip
    unzip -qo /tmp/font.zip -d "$HOME/.local/share/fonts/JetBrainsMono"
    rm /tmp/font.zip
fi

# Symbols Nerd Font (The 'Gold Standard' for icons)
if ! fc-list | grep -qi "Symbols Nerd Font"; then
    echo "Installing Symbols Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts/SymbolsNerdFont"
    curl -fsSL -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip" -o /tmp/font.zip
    unzip -qo /tmp/font.zip -d "$HOME/.local/share/fonts/SymbolsNerdFont"
    rm /tmp/font.zip
fi

fc-cache -f "$HOME/.local/share/fonts"

# Ensure default wallpaper exists for priming
mkdir -p "$HOME/Pictures"
if [ ! -f "$HOME/Pictures/desktop.png" ]; then
    echo "🖼️ No desktop.png found. Creating a placeholder..."
    # Copy a system wallpaper if available, otherwise just warn
    [ -f "/usr/share/backgrounds/warty-final-ubuntu.png" ] && cp "/usr/share/backgrounds/warty-final-ubuntu.png" "$HOME/Pictures/desktop.png"
fi

echo ""
echo "✅ Lean Ubuntu setup sequence completed successfully!"
