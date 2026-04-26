#!/usr/bin/env bash
# scripts/generate_mouse_demos.sh (v2: Professional Screencast Edition)
# Automate BSPWM Mouse Interaction Recording with Cursor Highlights

OUT_DIR="assets/screenshots"
RAW_DIR="/tmp/bspwm_record"
mkdir -p "$OUT_DIR" "$RAW_DIR"

# 1. Setup BSPWM rules for the Halo (unmanaged to bypass WM logic)
bspc rule -a "cursor_halo" manage=off border=off focus=off click_to_focus=false

# 2. Cleanup & Initializer
pkill -f screenkey
pkill -f kitty
sleep 1

# 3. Start Visualizers
# A. Screenkey for Button clicks
if command -v screenkey &>/dev/null; then
    screenkey --show-settings off --font-size 22 --timeout 1.5 --position top --geometry 400x100+2900+50 &
    SK_PID=$!
else
    echo "⚠️ screenkey not found, falling back to notification-based clicks."
fi

# B. Cursor Halo (Yellow 30x30 box)
kitty --class "cursor_halo" -o initial_window_width=30 -o initial_window_height=30 \
      -e sh -c 'printf "\033]11;#ffff00\007"; while :; do sleep 100; done' &
sleep 2
HALO_ID=$(xdotool search --class cursor_halo | tail -n 1)
bspc node "$HALO_ID" --layer above

# C. Halo Following Loop
(
    while :; do
        eval $(xdotool getmouselocation --shell 2>/dev/null)
        # Move the halo relative to cursor using xdotool (works on unmanaged windows)
        xdotool windowmove "$HALO_ID" $((X - 15)) $((Y - 15)) 2>/dev/null
        sleep 0.02 # 50fps follow
    done
) &
LOOP_PID=$!

# 4. Launch Reference Windows
kitty --title "Demo-A" &
sleep 0.5
kitty --title "Demo-B" &
sleep 1

# Center 1600x900 capture region
record_interaction() {
    local name=$1
    local action=$2
    local video="$RAW_DIR/$name.mp4"
    local gif="$OUT_DIR/$name.gif"

    echo "📹 Recording $name..."
    # Build filter string based on action
    local draw_filter=""
    if [[ "$name" == *"move"* ]]; then
        draw_filter=",drawtext=text='SUPER + BUTTON 1 (MOVE)':fontcolor=white:fontsize=36:x=(w-text_w)/2:y=h-60:box=1:boxcolor=black@0.6:boxborderw=10:enable='between(t,2,5)'"
    elif [[ "$name" == *"resize"* ]]; then
        draw_filter=",drawtext=text='SUPER + BUTTON 3 (RESIZE)':fontcolor=white:fontsize=36:x=(w-text_w)/2:y=h-60:box=1:boxcolor=black@0.6:boxborderw=10:enable='between(t,2,6)'"
    fi

    ffmpeg -y -f x11grab -video_size 1600x900 -i :0.0+920,200 -t 8 "$video" &
    FF_PID=$!
    
    sleep 1
    # Run simulation
    bash -c "$action"
    
    wait $FF_PID
    
    echo "🎨 Converting to GIF with Visual Overlays..."
    ffmpeg -y -i "$video" -vf "fps=15,scale=800:-1:flags=lanczos$draw_filter,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$gif"
}

# Simulations with notification fallbacks if screenkey is missing
show_click() {
    [ -z "$SK_PID" ] && notify-send -t 1000 "Mouse Action" "$1"
}

MOVE_SIM='
    xdotool keydown Super_L
    xdotool mousemove 1300 600
    sleep 0.5
    '$(show_click "MOVE START (Button 1)")'
    xdotool mousedown 1
    xdotool mousemove 2500 600
    sleep 1
    xdotool mousemove 1300 600
    sleep 0.5
    xdotool mouseup 1
    xdotool keyup Super_L
'

RESIZE_SIM='
    xdotool keydown Super_L
    xdotool mousemove 1700 600
    sleep 0.5
    '$(show_click "RESIZE START (Button 3)")'
    xdotool mousedown 3
    xdotool mousemove 2000 700
    sleep 0.8
    xdotool mousemove 1500 500
    sleep 0.8
    xdotool mouseup 3
    xdotool keyup Super_L
'

record_interaction "bspwm_mouse_move" "$MOVE_SIM"
record_interaction "bspwm_mouse_resize" "$RESIZE_SIM"

# Final Cleanup
kill $LOOP_PID
[ -n "$SK_PID" ] && kill $SK_PID
pkill -f cursor_halo
pkill -f kitty
sleep 1
echo "✅ Enhanced Demos generated in $OUT_DIR"
