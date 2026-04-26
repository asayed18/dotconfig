#!/usr/bin/env bash

# Toggle MPD between Local Music and Radio
# Created by Antigravity

MPC_PORT=6600
MPC_HOST=127.0.0.1
RADIO_URL="http://icecast.radiofrance.fr/fip-midfi.mp3"

# Helper to send commands to MPD
mpd_cmd() {
    echo -e "$1\nclose" | nc -w 1 $MPC_HOST $MPC_PORT
}

# Check current song
CURRENT=$(mpd_cmd "currentsong")

if [[ "$CURRENT" == *"file: http"* ]]; then
    # Currently Radio -> Switch to Music
    mpd_cmd "clear"
    mpd_cmd "add \"/\""
    mpd_cmd "random 1"
    mpd_cmd "play"
    if command -v notify-send >/dev/null; then
        notify-send -i audio-x-generic "MPD Source" "Switched to Local Music (Shuffle ON)"
    fi
else
    # Currently Music (or empty/stopped) -> Switch to Radio
    mpd_cmd "clear"
    mpd_cmd "add \"$RADIO_URL\""
    mpd_cmd "random 0"
    mpd_cmd "play"
    if command -v notify-send >/dev/null; then
        notify-send -i radio "MPD Source" "Switched to FIP Radio"
    fi
fi
