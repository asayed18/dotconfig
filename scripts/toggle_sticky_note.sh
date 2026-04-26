#!/bin/bash


if [ -z "$(xdotool search -class sticky_note)" ]; then
    terminal --class sticky_note -e vim -c "vsplit | vertical resize 60% | terminal glow --watch ~/sticky_note.md" -c "wincmd h" ~/sticky_note.md
else
    for w in $(xdotool search -class sticky_note); do
        xdotool windowkill $w;
    done
fi

