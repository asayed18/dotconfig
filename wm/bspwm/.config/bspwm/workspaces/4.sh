#!/bin/env bash
if ! pgrep -f evince; then evince & disown; fi
if ! pgrep -f Joplin; then /opt/Joplin-2.7.15.AppImage & disown; fi
bspc desktop -f '^4'