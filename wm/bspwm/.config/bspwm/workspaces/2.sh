#!/bin/env bash
if ! pgrep -f brave; then /opt/brave-browser-nightly/brave-browser-nightly & disown; fi
bspc desktop -f '^2'