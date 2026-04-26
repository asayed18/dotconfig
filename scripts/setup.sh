#!/usr/bin/env bash
# Dotfiles Setup Interactive Toolkit - Professional Edition

# 0. Environment Setup
export TERM=xterm-256color # Enable mouse support features in many terminals

# 1. High-Contrast Theming
export NEWT_COLORS='root=white,black:window=white,black:border=cyan,black:shadow=black,black:title=magenta,black:button=white,black:actbutton=black,cyan:compactbutton=white,black:checkbox=white,black:actcheckbox=black,cyan:entry=black,white:disentry=white,black:label=white,black:listbox=white,black:actlistbox=black,cyan:sellistbox=white,black:actsellistbox=black,cyan:textbox=white,black:acttextbox=black,cyan:helpline=white,black:roottext=white,black'

# Ensure whiptail is available
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail is required for the interactive setup."
    exit 1
fi

DOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOT_DIR" || exit 1

# 2. Distro Detection
DETECTED_OS="ubuntu"
[ -f /etc/os-release ] && . /etc/os-release && DETECTED_OS=$ID

# 3. Helper: Get Module Data
get_about() {
    local mod_path=$1
    if [ -f "$mod_path/about.txt" ]; then
        cat "$mod_path/about.txt" | tr -d '"'
    else
        echo "Configuration module for $(basename "$mod_path")"
    fi
}

# 4. State Machine Variables
STEP=1
SELECTED_OS="$DETECTED_OS"
DO_INSTALL=false
SELECTED_WM="openbox"
FINAL_MODULES=""
SELECTED_PARTITIONS=""

# Persistence across category steps
# We store category selections in an associative array (if bash 4+) or just variables
declare -A CATEGORY_SELECTIONS

while [ "$STEP" -gt 0 ]; do
    # Shared Whiptail Args
    BACK_LABEL="Back"
    [ "$STEP" -eq 1 ] && BACK_LABEL="Exit"
    
    case $STEP in
        1) # OS Selection
            RESULT=$(whiptail --title "System Layer (Step 1)" --radiolist --cancel-button "$BACK_LABEL" \
            "Select your Operating System (Detected: $DETECTED_OS):" 15 60 4 \
            "ubuntu" "Ubuntu / Debian based" $([ "$SELECTED_OS" == "ubuntu" ] && echo ON || echo OFF) \
            "arch" "Arch Linux based" $([ "$SELECTED_OS" == "arch" ] && echo ON || echo OFF) \
            3>&1 1>&2 2>&3)
            
            if [ $? -eq 0 ]; then
                SELECTED_OS="$RESULT"
                STEP=2
            else
                exit 0
            fi
            ;;
            
        2) # Package Install Prompt
            INSTALL_SCRIPT="$DOT_DIR/os/$SELECTED_OS/install.sh"
            if [ -f "$INSTALL_SCRIPT" ]; then
                whiptail --title "Package Installation (Step 2)" --yesno --cancel-button "$BACK_LABEL" \
"Install required packages for '$SELECTED_OS'?

This will run: os/$SELECTED_OS/install.sh
Requires sudo access. Skip if packages are already installed." 15 65
                
                RET=$?
                if [ $RET -eq 0 ]; then
                    DO_INSTALL=true; STEP=3
                elif [ $RET -eq 1 ]; then
                    DO_INSTALL=false; STEP=3
                else
                    STEP=1 # Back
                fi
            else
                STEP=3 # Skip to WM if no installer
            fi
            ;;
            
        3) # WM Selection
            RESULT=$(whiptail --title "Desktop Layer (Step 3)" --radiolist --cancel-button "$BACK_LABEL" \
            "Select Window Manager / Session:" 15 60 4 \
            "openbox" "Openbox (Minimal Stacking)" $([ "$SELECTED_WM" == "openbox" ] && echo ON || echo OFF) \
            "i3" "i3wm (Tiling)" $([ "$SELECTED_WM" == "i3" ] && echo ON || echo OFF) \
            "bspwm" "BSPWM (Binary Space Partition)" $([ "$SELECTED_WM" == "bspwm" ] && echo ON || echo OFF) \
            3>&1 1>&2 2>&3)
            
            if [ $? -eq 0 ]; then
                SELECTED_WM="$RESULT"
                STEP=4 # Start category loop
            else
                STEP=2
            fi
            ;;

        4) # Exclusive Categories (Radiolists)
            # We combine radio categories here to stay in one loop
            RADIOS=("terminal" "shell" "files" "browser")
            SUCCESS=true
            for cat in "${RADIOS[@]}"; do
                OPTIONS=()
                # Find subdirs of modules/$cat
                if [ ! -d "modules/$cat" ]; then
                    continue
                fi

                for mod_dir in modules/"$cat"/*; do
                    [ -d "$mod_dir" ] || continue
                    name=$(basename "$mod_dir")
                    about=$(get_about "$mod_dir")
                    status="OFF"
                    # Restore previous selection or use defaults
                    [ -n "${CATEGORY_SELECTIONS[$cat]}" ] && [ "$name" == "${CATEGORY_SELECTIONS[$cat]}" ] && status="ON"
                    [ -z "${CATEGORY_SELECTIONS[$cat]}" ] && [ "$name" == "alacritty" ] && status="ON"
                    [ -z "${CATEGORY_SELECTIONS[$cat]}" ] && [ "$name" == "zsh" ] && status="ON"
                    [ -z "${CATEGORY_SELECTIONS[$cat]}" ] && [ "$name" == "thunar" ] && status="ON"
                    [ -z "${CATEGORY_SELECTIONS[$cat]}" ] && [ "$name" == "qutebrowser" ] && status="ON"
                    OPTIONS+=("$name" "$about" "$status")
                done

                SEL=$(whiptail --title "Select $cat (Step 4)" --radiolist --cancel-button "$BACK_LABEL" \
                "Choose your preferred $(echo "$cat" | sed 's/./\U&/'):" 20 75 10 \
                "${OPTIONS[@]}" 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ]; then
                    CATEGORY_SELECTIONS[$cat]="$SEL"
                else
                    SUCCESS=false; break
                fi
            done
            
            if [ "$SUCCESS" = true ]; then STEP=5; else STEP=3; fi
            ;;

        5) # Optional Categories (Checklists)
            # We process multiple checkbox categories in sequence to allow Back within them?
            # Or one big list? Let's do one check-list per category for clarity.
            CHECKS=("bar" "compositor" "launcher" "media" "system" "theme" "tools" "vcs")
            CUR_CAT_IDX=0
            # We use a sub-step logic here
            while [ "$CUR_CAT_IDX" -lt "${#CHECKS[@]}" ] && [ "$CUR_CAT_IDX" -ge 0 ]; do
                cat="${CHECKS[$CUR_CAT_IDX]}"
                OPTIONS=()
                for mod_dir in modules/"$cat"/*; do
                    [ -d "$mod_dir" ] || continue
                    name=$(basename "$mod_dir")
                    about=$(get_about "$mod_dir")
                    status="ON"
                    # Check if we have a saved state (comma separated list)
                    [[ "${CATEGORY_SELECTIONS[$cat]}" == *"$name"* ]] && status="ON"
                    # If it's the first time visiting, everything is ON by default
                    [ -z "${CATEGORY_SELECTIONS[$cat]}" ] && status="ON"

                    OPTIONS+=("$name" "$about" "$status")
                done

                SEL=$(whiptail --title "Select $cat Tools (Step 5)" --checklist --cancel-button "$BACK_LABEL" \
                "Choose $(echo "$cat" | sed 's/./\U&/') components:" 20 75 10 \
                "${OPTIONS[@]}" 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ]; then
                    CATEGORY_SELECTIONS[$cat]=$(echo "$SEL" | tr -d '"')
                    ((CUR_CAT_IDX++))
                else
                    ((CUR_CAT_IDX--))
                fi
            done
            
            if [ "$CUR_CAT_IDX" -ge "${#CHECKS[@]}" ]; then STEP=6; 
            else STEP=4; fi
            ;;

        6) # Partition Selection
            PART_OPTIONS=()
            # More robust parsing for Dynamic/LDM Disks
            while IFS= read -r line; do
                eval "$line" # Sets NAME, SIZE, FSTYPE, TYPE, MOUNTPOINT, LABEL, PARTLABEL
                [ "$TYPE" != "part" ] && continue
                
                # Protect system partitions (Root and Boot)
                [ "$MOUNTPOINT" == "/" ] && continue
                [[ "$MOUNTPOINT" == "/boot"* ]] && continue
                
                # Filter small system partitions or loop devices
                echo "$SIZE" | grep -qE "^[0-9.]+[K|M]$" && ! echo "$SIZE" | grep -qE "[0-9]{3,}" && continue
                
                # Construct meaningful description
                DESC="[$SIZE] "
                [ -n "$LABEL" ] && DESC+="$LABEL "
                [ -n "$FSTYPE" ] && DESC+="($FSTYPE) "
                [ -n "$PARTLABEL" ] && DESC+="{$PARTLABEL}"
                [ -z "$LABEL" ] && [ -z "$FSTYPE" ] && [ -z "$PARTLABEL" ] && DESC+="Unidentified Partition"
                
                status="OFF"
                [[ "$SELECTED_PARTITIONS" == *"$NAME"* ]] && status="ON"
                
                PART_OPTIONS+=("$NAME" "$DESC" "$status")
            done < <(lsblk -P -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL,PARTLABEL 2>/dev/null | sort)

            if [ ${#PART_OPTIONS[@]} -gt 0 ]; then
                RESULT=$(whiptail --title "Auto-Mount (Step 6)" --checklist --cancel-button "$BACK_LABEL" \
"Select partitions to auto-mount via udiskie: (LDM/Dynamic supported)" \
22 80 12 "${PART_OPTIONS[@]}" 3>&1 1>&2 2>&3)
                
                if [ $? -eq 0 ]; then
                    SELECTED_PARTITIONS=$(echo "$RESULT" | tr -d '"')
                    STEP=7
                else
                    STEP=5
                fi
            else
                STEP=7 # Skip if no partitions
            fi
            ;;

        7) # Confirmation
            # Build the module path string for make
            FINAL_MODULES=""
            for k in "${!CATEGORY_SELECTIONS[@]}"; do
                for item in ${CATEGORY_SELECTIONS[$k]}; do
                    FINAL_MODULES="$FINAL_MODULES modules/$k/$item"
                done
            done

            whiptail --title "Review & Apply (Final Step)" --yesno --cancel-button "$BACK_LABEL" "
Are you ready to apply the following config?

OS:         $SELECTED_OS
WM:         $SELECTED_WM
Modules:    $(echo "$FINAL_MODULES" | sed 's/modules\///g')
Automounts: ${SELECTED_PARTITIONS:-None}

Command will trigger installation (if opted-in) and symlinking.
" 22 80

            if [ $? -eq 0 ]; then
                clear
                if [ "$DO_INSTALL" = true ]; then
                    echo "📦 Installing packages for $SELECTED_OS..."
                    bash "$DOT_DIR/os/$SELECTED_OS/install.sh" "$SELECTED_WM $FINAL_MODULES"
                    echo "✅ Package installation complete."
                fi
                
                # 7.5 Git Interactive Configuration
                if [[ "$FINAL_MODULES" == *"modules/vcs/git"* ]]; then
                    # Try to pre-fill from current config
                    PRE_NAME=$(git config --global user.name)
                    PRE_EMAIL=$(git config --global user.email)
                    
                    GIT_NAME=$(whiptail --title "Git Configuration" --inputbox "Enter your Git Username:" 10 60 "$PRE_NAME" 3>&1 1>&2 2>&3)
                    GIT_EMAIL=$(whiptail --title "Git Configuration" --inputbox "Enter your Git Email:" 10 60 "$PRE_EMAIL" 3>&1 1>&2 2>&3)
                    
                    if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
                        echo "💾 Updating Git configuration in dotfiles..."
                        cat > "$DOT_DIR/base/.gitconfig" <<EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
                        git config --global user.name "$GIT_NAME"
                        git config --global user.email "$GIT_EMAIL"
                    fi
                fi

                # 7.6 Default Shell Configuration
                SELECTED_SHELL="${CATEGORY_SELECTIONS[shell]}"
                if [ -n "$SELECTED_SHELL" ]; then
                    # We use which -a because sometimes shells are in /bin and /usr/bin
                    SHELL_PATH=$(which "$SELECTED_SHELL" 2>/dev/null)
                    if [ -n "$SHELL_PATH" ] && [ "$SHELL_PATH" != "$SHELL" ]; then
                        if whiptail --title "Shell Configuration" --yesno "Would you like to set $SELECTED_SHELL as your default shell?" 10 60; then
                            echo "🐚 Setting $SELECTED_SHELL as default shell..."
                            # This will prompt for password in the terminal
                            sudo chsh -s "$SHELL_PATH" "$USER"
                        fi
                    fi
                fi

                # Write Selections State (for Autostart and other tools)
                echo "💾 Saving selection state..."
                mkdir -p "$HOME/.config/dotconfig"
                cat > "$HOME/.config/dotconfig/state.sh" <<EOF
# Generated by dotconfig setup
SELECTED_OS="$SELECTED_OS"
SELECTED_WM="$SELECTED_WM"
SELECTED_MODULES="$FINAL_MODULES"
EOF
                
                # Write udiskie config if needed
                if [ -n "$SELECTED_PARTITIONS" ]; then
                    mkdir -p "$HOME/.config/udiskie"
                    cat > "$HOME/.config/udiskie/config.yml" <<EOF
program_options:
  automount: true
  tray: true
device_config:
EOF
                    for p in $SELECTED_PARTITIONS; do
                        echo "  - device_file: $p" >> "$HOME/.config/udiskie/config.yml"
                        echo "    mount_options: [defaults]" >> "$HOME/.config/udiskie/config.yml"
                    done
                fi

                # 7a. Post-Processing: Abstraction Layer
                # Create Local Bin for generic commands
                mkdir -p "$HOME/.local/bin"
                
                echo "🔗 Linking Generic Application Defaults..."
                link_default() {
                    local cat=$1
                    local bin=$2
                    local app=${CATEGORY_SELECTIONS[$cat]}
                    if [ -n "$app" ]; then
                        local path=$(which "$app" 2>/dev/null)
                        if [ -n "$path" ]; then
                            ln -sf "$path" "$HOME/.local/bin/$bin"
                        fi
                    fi
                }

                link_default "terminal" "terminal"
                link_default "files" "files"
                link_default "browser" "browser"
                link_default "shell" "shell"
                
                # Link default editor
                EDITOR_PATH=$(which nvim 2>/dev/null || which vim 2>/dev/null || which nano 2>/dev/null)
                [ -n "$EDITOR_PATH" ] && ln -sf "$EDITOR_PATH" "$HOME/.local/bin/editor"
                
                # 7b. Update XDG Mime Types
                echo "📁 Updating XDG Default MIME Types..."
                mkdir -p "$HOME/.config"
                XDG_MIME="$HOME/.config/mimeapps.list"
                [ ! -f "$XDG_MIME" ] && echo "[Default Applications]" > "$XDG_MIME"
                
                # Helper to update mime
                update_mime_entry() {
                    local mime=$1
                    local app=$2
                    # Remove existing entries for this mime type using # as delimiter
                    sed -i "\#$mime#d" "$XDG_MIME"
                    # Add new entry
                    if [ -n "$app" ]; then
                        echo "$mime=$app.desktop" >> "$XDG_MIME"
                    fi
                }
                
                [ -n "${CATEGORY_SELECTIONS[files]}" ] && update_mime_entry "inode/directory" "${CATEGORY_SELECTIONS[files]}"
                [ -n "${CATEGORY_SELECTIONS[browser]}" ] && {
                    update_mime_entry "x-scheme-handler/http" "${CATEGORY_SELECTIONS[browser]}"
                    update_mime_entry "x-scheme-handler/https" "${CATEGORY_SELECTIONS[browser]}"
                    update_mime_entry "text/html" "${CATEGORY_SELECTIONS[browser]}"
                }

                # Enable Resume Hook (Sleep logic)
                echo "🌙 Configuring Sleep/Wake Synchronization..."
                systemctl --user daemon-reload || true
                systemctl --user enable resume-wallpaper.service || true

                echo "Running orchestrator..."
                make all OS="$SELECTED_OS" WM="$SELECTED_WM" MODULES="$FINAL_MODULES"

                # 7b. Priming Theme (Initialize WPGTK library and colors.ini)
                if command -v wpg &>/dev/null && [ -f "$HOME/Pictures/desktop.png" ]; then
                    echo "🎨 Priming theme with default wallpaper..."
                    # Check if wpg already has themes; if not, initialize
                    if [ -z "$(wpg -l)" ]; then
                        bash "$HOME/projects/dotconfig/scripts/pywallpaper.sh" "$HOME/Pictures/desktop.png"
                    fi
                fi

                # 8. Hot Reload Desktop Environment
                echo "🔥 Triggering Hot Reload..."
                
                # Restart major UI services
                pkill polybar
                pkill picom
                pkill dunst
                pkill -USR1 -x sxhkd || pkill sxhkd
                
                # Refresh Font Cache
                echo "🔤 Refreshing font cache..."
                fc-cache -f
                
                # Reload Window Manager
                case "$SELECTED_WM" in
                    openbox) openbox --reconfigure ;;
                    i3) i3-msg reload ;;
                    bspwm) bspc wm -r ;;
                esac
                
                # Re-run autostart
                if [ -f "$HOME/.config/dotconfig/autostart.sh" ]; then
                    echo "🚀 Relaunching autostart services..."
                    bash "$HOME/.config/dotconfig/autostart.sh" &
                fi

                echo "✅ Setup and Hot Reload complete!"
                exit 0
            else
                STEP=6
            fi
            ;;
    esac
done
