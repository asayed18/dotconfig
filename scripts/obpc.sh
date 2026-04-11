#!/usr/bin/env bash
# scripts/obpc.sh
# Openbox Power Control - Advanced bspc-style compatibility layer

COMMAND=$1
SUBCOMMAND=$2
TARGET=$3
ARGS="${@:3}"

# Helper: Get current desktop index
get_current_desktop() {
    wmctrl -d | grep '*' | awk '{print $1}'
}

# Helper: Get window geometry
# Returns: id x y w h
get_win_geom() {
    local id=$1
    wmctrl -lG | grep "^$id" | awk '{print $1, $3, $4, $5, $6}'
}

# Spatial Focus/Swap Logic
find_neighbor() {
    local dir=$1
    local active_id=$(xdotool getactivewindow 2>/dev/null)
    [ -z "$active_id" ] && return
    
    # Format active ID for wmctrl (hex)
    local hex_id=$(printf "0x%08x" "$active_id")
    
    # Get active geometry
    read vid ax ay aw ah < <(get_win_geom "$hex_id")
    [ -z "$ax" ] && return
    
    local acx=$((ax + aw/2))
    local acy=$((ay + ah/2))
    
    local best_id=""
    local min_dist=999999
    
    local current_desktop=$(get_current_desktop)
    
    # Search all windows on current desktop
    while read -r cid cx cy cw ch; do
        [ "$cid" == "$hex_id" ] && continue # Skip self
        
        local ccx=$((cx + cw/2))
        local ccy=$((cy + ch/2))
        
        local dx=$((ccx - acx))
        local dy=$((ccy - acy))
        
        local match=false
        case "$dir" in
            west)  [ "$ccx" -lt "$acx" ] && match=true ;;
            east)  [ "$ccx" -gt "$acx" ] && match=true ;;
            north) [ "$ccy" -lt "$acy" ] && match=true ;;
            south) [ "$ccy" -gt "$acy" ] && match=true ;;
        esac
        
        if $match; then
            # Calculate weighted distance (taxicab distance with orthogonal penalty)
            local dist
            case "$dir" in
                west|east)  dist=$(( ${dx#-} + ${dy#-}*2 )) ;;
                north|south) dist=$(( ${dy#-} + ${dx#-}*2 )) ;;
            esac
            
            if [ "$dist" -lt "$min_dist" ]; then
                min_dist=$dist
                best_id=$cid
            fi
        fi
    done < <(wmctrl -lG | awk -v d="$current_desktop" '$2 == d {print $1, $3, $4, $5, $6}')
    
    echo "$best_id"
}

case "$COMMAND" in
    node)
        case "$SUBCOMMAND" in
            -f) # Focus
                case "$TARGET" in
                    west|east|north|south)
                        neighbor=$(find_neighbor "$TARGET")
                        [ -n "$neighbor" ] && wmctrl -ia "$neighbor"
                        ;;
                    next) xdotool key alt+Tab ;;
                    prev) xdotool key alt+shift+Tab ;;
                    last) wmctrl -ia :ACTIVE: ;; # Simple last focus
                esac
                ;;
            -s) # Swap positions
                neighbor=$(find_neighbor "$TARGET")
                if [ -n "$neighbor" ]; then
                    active_id=$(printf "0x%08x" "$(xdotool getactivewindow)")
                    read _ ax ay aw ah < <(get_win_geom "$active_id")
                    read _ nx ny nw nh < <(get_win_geom "$neighbor")
                    
                    # Swap them
                    wmctrl -ir "$active_id" -e "0,$nx,$ny,$nw,$nh"
                    wmctrl -ir "$neighbor" -e "0,$ax,$ay,$aw,$ah"
                fi
                ;;
            -t) # Toggle state
                case "$TARGET" in
                    fullscreen) wmctrl -r :ACTIVE: -b toggle,fullscreen ;;
                    floating)   wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz ;;
                    tiled)      wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz ;;
                esac
                ;;
            -z) # Resize (Example: left -20 0)
                # Parse: side delta_x delta_y
                SIDE=$TARGET
                DX=$(echo "$ARGS" | awk '{print $1}')
                DY=$(echo "$ARGS" | awk '{print $2}')
                
                # Use xdotool for relative resizing
                case "$SIDE" in
                    left)   xdotool windowsize --relative -- :ACTIVE: "$((DX#-) )" 0 windowmove --relative -- :ACTIVE: "$DX" 0 ;;
                    right)  xdotool windowsize --relative -- :ACTIVE: "$DX" 0 ;;
                    top)    xdotool windowsize --relative -- :ACTIVE: 0 "$((DY#-) )" windowmove --relative -- :ACTIVE: 0 "$DY" ;;
                    bottom) xdotool windowsize --relative -- :ACTIVE: 0 "$DY" ;;
                esac
                ;;
            -g) # Set flags
                case "$TARGET" in
                    sticky) wmctrl -r :ACTIVE: -b toggle,sticky ;;
                esac
                ;;
            -c|-k) # Close/Kill
                wmctrl -c :ACTIVE: || xdotool getactivewindow windowkill
                ;;
        esac
        ;;
    desktop)
        case "$SUBCOMMAND" in
            -f) # Focus desktop
                TOTAL=$(wmctrl -d | wc -l)
                CURRENT=$(get_current_desktop)
                if [[ "$TARGET" =~ ^[0-9]+$ || "$TARGET" =~ ^\^([0-9]+)$ ]]; then
                    NUM=$(echo "$TARGET" | tr -dc '0-9')
                    wmctrl -s $((NUM - 1))
                elif [ "$TARGET" == "next.local" ] || [ "$TARGET" == "next" ]; then
                    wmctrl -s $(( (CURRENT + 1) % TOTAL ))
                elif [ "$TARGET" == "prev.local" ] || [ "$TARGET" == "prev" ]; then
                    wmctrl -s $(( (CURRENT - 1 + TOTAL) % TOTAL ))
                fi
                ;;
        esac
        ;;
    wm)
        case "$SUBCOMMAND" in
            -r) openbox --reconfigure ;;
        esac
        ;;
esac
