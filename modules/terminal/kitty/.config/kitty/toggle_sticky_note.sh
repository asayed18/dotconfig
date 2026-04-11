#!/bin/bash


if [ -z "$(xdotool search -class sticky_note)" ]; then
    kitty --class sticky_note -c $HOME/.config/kitty/stick_note.conf -e vim -y ~/sticky_note.md
else
    for w in $(xdotool search -class sticky_note); do
        xdotool windowkill $w;
    done
fi

