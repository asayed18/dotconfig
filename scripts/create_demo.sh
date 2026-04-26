#!/usr/bin/env bash
# scripts/create_demo.sh
# Antigravity Screencast Skill - Versatile Demo Generator (AI-Refined)

# Default Settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUT_DIR="$ROOT_DIR/assets/screenshots"
NAME="demo_$(date +%s)"
DURATION=5
SCALE=800
HALO_SIZE=30
OVERLAY_TEXT=""
JSON_OUTPUT=false

mkdir -p "$OUT_DIR"

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -n, --name <name>       Output filename (default: demo_<ts>)"
    echo "  -d, --duration <sec>    Recording duration in seconds (default: 5)"
    echo "  -s, --select            Select window interactively"
    echo "  -w, --window <search>   Search and record window by title/class (non-interactive)"
    echo "  -p, --preset <name>     Use preset (center, split, full)"
    echo "  -r, --region <WxH+X+Y>  Manual region definition"
    echo "  -t, --text <text>       Add button/feature overlay text"
    echo "  --sim <command>         Command/Script to run during simulation"
    echo "  --no-halo               Disable cursor highlight"
    echo "  --json                  Output result in JSON format"
    exit 1
}

fail() {
    if [ "$JSON_OUTPUT" = true ]; then
        echo "{\"success\": false, \"error\": \"$1\"}"
    else
        echo "Error: $1"
    fi
    exit 1
}

# Parse Args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--name) NAME="$2"; shift ;;
        -d|--duration) DURATION="$2"; shift ;;
        -s|--select) SELECT=true ;;
        -w|--window) WINDOW_SEARCH="$2"; shift ;;
        -p|--preset) PRESET="$2"; shift ;;
        -r|--region) REGION="$2"; shift ;;
        -t|--text) OVERLAY_TEXT="$2"; shift ;;
        --sim) SIM_CMD="$2"; shift ;;
        --no-halo) NO_HALO=true ;;
        --json) JSON_OUTPUT=true ;;
        *) show_usage ;;
    esac
    shift
done

log_info() { [ "$JSON_OUTPUT" = false ] && echo "$@"; }

# 1. Determine Region
if [ "$SELECT" = true ]; then
    log_info "🖱️ Click on the window you want to record..."
    WIN_INFO=$(xwininfo || fail "xwininfo failed")
    W=$(echo "$WIN_INFO" | grep "Width:" | awk '{print $NF}')
    H=$(echo "$WIN_INFO" | grep "Height:" | awk '{print $NF}')
    X=$(echo "$WIN_INFO" | grep "Absolute upper-left X:" | awk '{print $NF}')
    Y=$(echo "$WIN_INFO" | grep "Absolute upper-left Y:" | awk '{print $NF}')
    REGION="${W}x${H}+${X}+${Y}"
elif [ -n "$WINDOW_SEARCH" ]; then
    log_info "🔍 Searching for visible window matching: $WINDOW_SEARCH"
    WIN_ID=$(xdotool search --onlyvisible --name "$WINDOW_SEARCH" | tail -n 1)
    if [ -z "$WIN_ID" ]; then
        fail "No visible window found matching: $WINDOW_SEARCH"
    fi
    log_info "🎯 Found Window ID: $WIN_ID"
    WIN_INFO=$(xwininfo -id "$WIN_ID" || fail "Failed to get info for ID $WIN_ID")
    W=$(echo "$WIN_INFO" | grep "Width:" | awk '{print $NF}')
    H=$(echo "$WIN_INFO" | grep "Height:" | awk '{print $NF}')
    X=$(echo "$WIN_INFO" | grep "Absolute upper-left X:" | awk '{print $NF}')
    Y=$(echo "$WIN_INFO" | grep "Absolute upper-left Y:" | awk '{print $NF}')
    REGION="${W}x${H}+${X}+${Y}"
elif [ -n "$PRESET" ]; then
    case $PRESET in
        center) REGION="1600x900+920+200" ;;
        split)  REGION="1720x1440+0+0" ;;
        full)   REGION="3440x1440+0+0" ;;
        *) log_info "Unknown preset $PRESET. Using default."; REGION="1600x900+920+200" ;;
    esac
fi

[ -z "$REGION" ] && REGION="1600x900+920+200"

OFFSET_X=$(echo "$REGION" | cut -d'+' -f2)
OFFSET_Y=$(echo "$REGION" | cut -d'+' -f3)
SIZE=$(echo "$REGION" | cut -d'+' -f1)

log_info "🎥 Region: $REGION"

# 2. Setup Cursor Halo
if [ "$NO_HALO" != true ]; then
    log_info "✨ Initializing Cursor Halo..."
    bspc rule -a "cursor_halo" manage=off border=off focus=off click_to_focus=false || true
    pkill -f cursor_halo || true
    
    kitty --class "cursor_halo" -o initial_window_width=$HALO_SIZE -o initial_window_height=$HALO_SIZE \
          -e sh -c 'printf "\033]11;#ffff00\007"; while :; do sleep 100; done' &
    sleep 2
    HALO_ID=$(xdotool search --class cursor_halo | tail -n 1)
    
    if [ -n "$HALO_ID" ]; then
        (
            while :; do
                eval $(xdotool getmouselocation --shell 2>/dev/null)
                xdotool windowmove "$HALO_ID" $((X - HALO_SIZE/2)) $((Y - HALO_SIZE/2)) 2>/dev/null
                sleep 0.02
            done
        ) &
        LOOP_PID=$!
    fi
fi

# 3. Recording
RAW_VIDEO="/tmp/${NAME}_raw.mp4"
log_info "📹 Recording for $DURATION seconds..."

ffmpeg -y -f x11grab -video_size $SIZE -i :0.0+${OFFSET_X},${OFFSET_Y} -t "$DURATION" "$RAW_VIDEO" &>/dev/null &
FF_PID=$!

sleep 1
if [ -n "$SIM_CMD" ]; then
    log_info "🚀 Running Simulation..."
    eval "$SIM_CMD" || log_info "Simulation command failed."
fi

wait $FF_PID || true

# 4. Conversion & Overlays
FINAL_GIF="$OUT_DIR/${NAME}.gif"
log_info "🎨 Processing GIF..."

DRAW_FILTER=""
if [ -n "$OVERLAY_TEXT" ]; then
    DRAW_FILTER=",drawtext=text='${OVERLAY_TEXT}':fontcolor=white:fontsize=32:x=(w-text_w)/2:y=h-50:box=1:boxcolor=black@0.6:boxborderw=10:enable='between(t,1,${DURATION}-1)'"
fi

if ! [ -f "$RAW_VIDEO" ]; then
    fail "Recording failed, $RAW_VIDEO not created."
fi

ffmpeg -y -i "$RAW_VIDEO" -vf "fps=15,scale=${SCALE}:-1:flags=lanczos${DRAW_FILTER},split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$FINAL_GIF" &>/dev/null

# 5. Cleanup
[ -n "$LOOP_PID" ] && kill $LOOP_PID
pkill -f cursor_halo || true

if [ "$JSON_OUTPUT" = true ]; then
    echo "{\"success\": true, \"path\": \"$FINAL_GIF\", \"name\": \"$NAME\", \"region\": \"$REGION\"}"
else
    echo "✅ Demo created: $FINAL_GIF"
fi
