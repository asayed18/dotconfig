#!/usr/bin/env bash

set -euo pipefail

# Configuration
MODEL="${DOTCONFIG_WHISPER_MODEL:-tiny.en}"
LANGUAGE="${DOTCONFIG_WHISPER_LANG:-en}"

# Runtime Files
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/dotconfig-ptt.pid"
AUDIO_FILE="${XDG_RUNTIME_DIR:-/tmp}/dotconfig-ptt.wav"
TEXT_FILE="${XDG_RUNTIME_DIR:-/tmp}/dotconfig-ptt.txt"
LOG_FILE="/tmp/ptt.log"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/dotconfig-ptt-state"

PYTHON_BIN="$HOME/.local/share/dotconfig/venv/bin/python3"
mkdir -p "$STATE_DIR"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"; }
get_ms() { date +%s%3N; }

# Improved keyboard detection logic moved inside functions

start_recording() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        exit 0
    fi
    rm -f "$AUDIO_FILE" "$TEXT_FILE"
    echo "STARTING" > "$PID_FILE"
    log "Recording started..."
    # Use -D pulse for better device management and wake-up
    arecord -D pulse --quiet --format=S16_LE --rate=16000 --channels=1 --duration=30 "$AUDIO_FILE" &
    echo "$!" > "$PID_FILE"
    polybar-msg action "#ptt.hook.1"
}

stop_recording() {
    [ -f "$PID_FILE" ] || exit 0
    local pid=$(cat "$PID_FILE")
    rm -f "$PID_FILE"
    [ "$pid" = "STARTING" ] || kill "$pid" 2>/dev/null || true
    
    if [ -s "$AUDIO_FILE" ]; then
        local size=$(stat -c%s "$AUDIO_FILE")
        log "Recording stopped. File size: $size bytes"
        
        if [ "$size" -le 44 ]; then
            log "ERROR: Recording is empty (only WAV header)."
            polybar-msg action "#ptt.hook.0"
            exit 0
        fi

        polybar-msg action "#ptt.hook.2"
        # Communicate with daemon over socket (allowing 60s for heavy processing)
        log "Sending to whisper daemon..."
        text=$(echo "$AUDIO_FILE" | nc -U -w 60 /tmp/whisper_ptt.socket || echo "")
        
        if [ -n "$text" ] && [[ ! "$text" == ERROR* ]]; then
            log "Transcription received: '$text'"
            ydotool type --key-delay 1 -- "$text"
        else
            log "ERROR: No transcription received or daemon error. Result: '$text'"
        fi
    else
        log "ERROR: Audio file does not exist or is empty."
    fi
    polybar-msg action "#ptt.hook.0"
}

wait_for_release() {
    local kbd_ids=$(xinput --list --short | grep "slave  keyboard" | grep -vE "XTEST|Power|Button" | grep -o 'id=[0-9]\+' | cut -d= -f2)
    log "Watching KBD IDs: $kbd_ids for release..."
    
    local timeout=600 
    while [ $timeout -gt 0 ]; do
        local still_down=0
        for id in $kbd_ids; do
            if xinput query-state "$id" 2>/dev/null | grep -E "key\[133\]=down|key\[134\]=down" >/dev/null; then
                still_down=1
                break
            fi
        done
        
        if [ "$still_down" -eq 0 ]; then
            log "Key release detected on all devices."
            break
        fi
        sleep 0.05
        timeout=$((timeout - 1))
    done
    stop_recording
}

case "${1:-}" in
    tap_press)
        now=$(get_ms)
        last_press=$(cat "$STATE_DIR/last_press" 2>/dev/null || echo 0)
        echo "$now" > "$STATE_DIR/last_press"
        
        diff=$((now - last_press))
        log "Press detected. diff=$diff"
        
        if [ "$diff" -lt 400 ] && [ "$diff" -gt 50 ]; then
            log "Double-tap detected! Starting recording loop..."
            start_recording
            wait_for_release
        fi
        ;;
    *) exit 1 ;;
esac
