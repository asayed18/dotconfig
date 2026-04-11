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
    openbox obconf lxappearance nitrogen feh \
    lxpolkit udiskie dunst picom sxhkd \
    xfce4-power-manager network-manager-gnome \
    pulseaudio-utils xclip xdotool ddcutil flameshot \
    lsblk pciutils coreutils grep sed awk

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
    python3-pip imagemagick bc

# Modular theme choices
install_if_requested "theme" "papirus-icon-theme" # Only if theme module is selected

# 4. Third-Party / Script-based Installs
# Oh-My-Zsh (non-interactive)
if [[ "$MODULES_LIST" == *"zsh"* ]] && [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Betterlockscreen
if ! command -v betterlockscreen &> /dev/null; then
    echo "Installing betterlockscreen..."
    sudo apt install $APT_FLAGS i3lock imagemagick bc
    sudo curl -fsSL "https://github.com/betterlockscreen/betterlockscreen/releases/latest/download/betterlockscreen-linux-x86_64" -o /usr/local/bin/betterlockscreen
    sudo chmod +x /usr/local/bin/betterlockscreen
fi

# Nerd Font fallback
if ! fc-list | grep -qi "CodeNewRoman"; then
    echo "Installing CodeNewRoman Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts"
    curl -fsSL -L "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CodeNewRoman.zip" -o /tmp/font.zip
    unzip -qo /tmp/font.zip -d "$HOME/.local/share/fonts"
    rm /tmp/font.zip
    fc-cache -fv "$HOME/.local/share/fonts"
fi

echo ""
echo "✅ Lean Ubuntu setup sequence completed successfully!"
