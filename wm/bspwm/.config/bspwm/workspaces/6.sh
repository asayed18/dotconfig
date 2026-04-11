#!/bin/env bash
if ! pgrep -f steam; then steam & disown; fi
bspc desktop -f '^6'