# config.fish
# FISH Modular Configuration Profile

# --- Environment Variables ---
set -xg TERM "alacritty"
set -xg EDITOR "editor"
set -xg VISUAL "editor"
set -xg TERMINAL "terminal"
set -xg BROWSER "browser"

# --- User Paths ---
set -xg PATH $HOME/.local/bin $PATH

# --- Interactive Session Rules ---
if status is-interactive
    # Suppress the default fish greeting
    set -g fish_greeting ""

    # Universal Aliases (Matching ZSH structure)
    alias ll="ls -lah --color=auto"
    alias ls="ls --color=auto"
    alias c="clear"
    alias update="sudo apt update && sudo apt upgrade -y"
    alias reloadfish="source ~/.config/fish/config.fish"

    # Theme/Color Integration
    # (Optional wpgtk hook for fish can go here)
end
