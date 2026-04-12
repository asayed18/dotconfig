#!/usr/bin/env bash
# modules/bar/polybar/.config/polybar/scripts/nvidia_vram.sh

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc)G"
    else
        echo "${bytes}M"
    fi
}

# Fetch usage
# nvidia-smi gives MiB by default. We use nounits for easy parsing.
VRAM_INFO=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$VRAM_INFO" ]; then
    echo "󰢮 --"
    exit 0
fi

USED_MIB=$(echo "$VRAM_INFO" | cut -d',' -f1 | tr -d ' ')
TOTAL_MIB=$(echo "$VRAM_INFO" | cut -d',' -f2 | tr -d ' ')

# Icon: 󰢮 (Nvidia from Nerd Fonts)
echo "󰢮 $(format_bytes $USED_MIB)"
