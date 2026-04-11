#!/usr/bin/env bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1;done

#Launch bar1 & bar2
# echo "---" | tee -a /tmp/polybar1.log & disown
# polybar bar1 2>&1 | tee -a /tmp/polybar1.log & disown
# polybar bar2 2>&1 | tee -a /tmp/polybar2.log & disown
polybar example 2>&1 | tee -a /tmp/polybar1.log & disown

# echo > /tmp/polybar_mqueue.$!
# ln -sf /tmp/polybar_mqueue.$! /tmp/ipc-example
