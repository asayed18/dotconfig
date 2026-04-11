#!/bin/env bash
if ! pgrep -f vlc; then vlc & disown; fi
bspc desktop -f '^5'