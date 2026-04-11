#!/usr/bin/env bash
# scripts/wallpaper-watcher.sh
# Background daemon to watch for wallpaper changes and auto-trigger themes

WATCH_FILE="$HOME/Pictures/desktop.png"
WATCH_DIR="$(dirname "$WATCH_FILE")"
SCRIPT_PATH="$HOME/projects/dotconfig/scripts/pywallpaper.sh"

echo "👀 Started Wallpaper Watcher on $WATCH_DIR"

# Ensure directory exists
mkdir -p "$WATCH_DIR"

# Start the infinite monitor loop
# We watch the directory to handle cases where the file is deleted/moved/overwritten
inotifywait -m -e close_write -e moved_to "$WATCH_DIR" | while read -r directory events filename; do
    if [ "$filename" == "desktop.png" ]; then
        sleep 1 # Debounce to ensure file is fully written/moved
        echo "♻️  Desktop wallpaper detected change! Re-applying theme..."
        if [ -f "$SCRIPT_PATH" ]; then
            "$SCRIPT_PATH" "$WATCH_FILE"
        else
            echo "Error: Theme script not found at $SCRIPT_PATH"
        fi
    fi
done
