#!/usr/bin/env bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1;done

# Detect Wifi Interface
export POLYBAR_WLAN=$(nmcli -t -f DEVICE,TYPE device | grep :wifi | head -n1 | cut -d: -f1)

#Launch bar1 & bar2
# echo "---" | tee -a /tmp/polybar1.log & disown
# polybar bar1 2>&1 | tee -a /tmp/polybar1.log & disown
# polybar bar2 2>&1 | tee -a /tmp/polybar2.log & disown
polybar example 2>&1 | tee -a /tmp/polybar1.log & disown
