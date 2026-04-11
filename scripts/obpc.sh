#!/usr/bin/env bash
# scripts/obpc.sh
# Openbox Power Control - A bspc-style compatibility layer for Openbox

COMMAND=$1
SUBCOMMAND=$2
TARGET=$3

# Helper: Get current window ID
get_active() {
    xdotool getactivewindow
}

case "$COMMAND" in
    node)
        case "$SUBCOMMAND" in
            -f) # Focus in direction or next/prev
                case "$TARGET" in
                    west|Left)  wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz && wmctrl -r :ACTIVE: -e 0,0,0,$(($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f1) / 2)),-1 ;;
                    east|Right) wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz && wmctrl -r :ACTIVE: -e 0,$(($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f1) / 2)),0,$(($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f1) / 2)),-1 ;;
                    north|Up)   wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz && wmctrl -r :ACTIVE: -e 0,0,0,-1,$(($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f2) / 2)) ;;
                    south|Down) wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz && wmctrl -r :ACTIVE: -e 0,0,$(($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f2) / 2)),-1,$(($(xdpyinfo | grep dimensions | awk '{print $2}' | cut -d'x' -f2) / 2)) ;;
                    next) xdotool key alt+Tab ;;
                    prev) xdotool key alt+shift+Tab ;;
                esac
                ;;
            -t) # Toggle state
                case "$TARGET" in
                    fullscreen) wmctrl -r :ACTIVE: -b toggle,fullscreen ;;
                    floating)   wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz ;;
                    tiled)      wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz ;;
                esac
                ;;
            -c|-k) # Close/Kill
                wmctrl -c :ACTIVE: || xdotool getactivewindow windowkill
                ;;
            -s) # Swap (Simple implementation: move to other side)
                # Not implemented yet
                ;;
        esac
        ;;
    desktop)
        case "$SUBCOMMAND" in
            -f) # Focus desktop
                # Handle relative {next,prev} or absolute numbers
                if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
                    wmctrl -s $((TARGET - 1))
                elif [ "$TARGET" == "next" ]; then
                    wmctrl -s $(($(wmctrl -d | grep '*' | cut -d' ' -f1) + 1))
                elif [ "$TARGET" == "prev" ]; then
                    wmctrl -s $(($(wmctrl -d | grep '*' | cut -d' ' -f1) - 1))
                fi
                ;;
        esac
        ;;
    wm)
        case "$SUBCOMMAND" in
            -r) # Restart
                openbox --reconfigure
                ;;
        esac
        ;;
esac
