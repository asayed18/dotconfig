# .zshrc
# ZSH Modular Configuration Profile

# --- Environment Variables ---
# Only set TERM if not already set (avoids breaking SSH sessions)
[ -z "$TERM" ] && export TERM="xterm-256color"
export EDITOR="editor"
export VISUAL="editor"
export TERMINAL="terminal"
export BROWSER="browser"

# --- ZSH Core Variables ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# --- Source Oh-My-Zsh (Silenced fallback if missing) ---
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    echo "Oh-My-Zsh not found at $ZSH. Fallback minimal shell prompt enabled."
    PROMPT="%n@%m %~ %# "
fi

# --- Unified Aliases ---
alias ll="ls -lah --color=auto"
alias ls="ls --color=auto"
alias c="clear"
alias update="sudo apt update && sudo apt upgrade -y"
alias reloadz="source ~/.zshrc"

# --- User Paths ---
export PATH="$HOME/.local/bin:$PATH"

# --- Theme/Color Integration ---
# (wpgtk / pywal hooks usually live here, safe to leave commented until needed)
# (cat ~/.config/wpg/sequences &) 
