#!/bin/env bash
if ! pgrep -f code-oss; then code-oss --enable-proposed-api & disown; fi
bspc desktop -f '^3'