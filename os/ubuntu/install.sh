#!/bin/bash
# os/ubuntu/install.sh
# Modular & Strict Ubuntu package resolver for dotfiles

set -e

# Configuration
APT_FLAGS="-y --no-install-recommends"
MODULES_LIST="$@"

echo "🛠️ Starting LEAN installation for Ubuntu..."
echo "Modules selected: $MODULES_LIST"

# 1. Base Foundations (Minimal requirements for the DE to even start)
echo "Installing Core Foundations..."
sudo apt update
sudo apt install $APT_FLAGS \
    lxappearance nitrogen feh \
    lxpolkit udiskie dunst picom sxhkd xss-lock \
    xfce4-power-manager network-manager-gnome \
    pulseaudio-utils    xclip build-essential curl wget git \
    gawk util-linux wmctrl xdotool inotify-tools \
    feh i3lock sxhkd dmenu brightnessctl fonts-noto-color-emoji

# 1a. NVIDIA Optimizations (Fix black screen on resume)
if lspci | grep -qi "NVIDIA"; then
    echo "🏎️ NVIDIA GPU detected. Applying Suspend/Resume optimizations..."
    echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp" | sudo tee /etc/modprobe.d/nvidia-power-management.conf
    # Ensure NVIDIA services are enabled
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service || true
fi

# 2. Selectively Install Apps based on arguments
install_if_requested() {
    local mod_name=$1
    shift
    local pkg_name="$@"
    if [[ "$MODULES_LIST" == *"$mod_name"* ]]; then
        echo "📦 Installing selected module: $mod_name..."
        sudo apt install $APT_FLAGS $pkg_name
    fi
}

# --- Terminals ---
install_if_requested "alacritty" "alacritty"
install_if_requested "kitty" "kitty"

# --- Window Managers ---
install_if_requested "openbox" "openbox obconf"
install_if_requested "bspwm" "bspwm sxhkd"
install_if_requested "i3" "i3-wm i3status i3lock"

# --- Shells ---
install_if_requested "zsh" "zsh"
install_if_requested "fish" "fish"

# --- File Managers ---
install_if_requested "thunar" "thunar"
install_if_requested "pcmanfm" "pcmanfm"

# --- Browsers ---
install_if_requested "qutebrowser" "qutebrowser"
install_if_requested "firefox" "firefox"

# --- System Components (Polybar / Rofi) ---
install_if_requested "polybar" "polybar"
install_if_requested "rofi" "rofi"

# --- Media ---
install_if_requested "mpv" "mpv"
install_if_requested "mpd" "mpd"
install_if_requested "ncmpcpp" "ncmpcpp"

# --- VCS ---
install_if_requested "git" "git"

# 3. Themes & Fonts (Required for the design but handled carefully)
echo "Installing Themes & Fonts..."
sudo apt install $APT_FLAGS \
    fonts-font-awesome fonts-noto-color-emoji \
    arc-theme \
    python3-pip pipx imagemagick bc

# Modular theme choices
install_if_requested "theme" "papirus-icon-theme" # Only if theme module is selected
install_if_requested "wpg" ""

# WPGTK & Pywal installation (requires pipx)
if [[ "$MODULES_LIST" == *"wpg"* ]]; then
    pipx install wpgtk --force
    pipx inject wpgtk haishoku  # Add better color extraction backend
    touch "$HOME/.Xresources"   # Prevent xrdb errors
    export PATH="$HOME/.local/bin:$PATH"
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
