#!/bin/bash

if ! pgrep -x picom; then 
picom;
else 
killall -q picom;
fi

