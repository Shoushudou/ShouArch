#!/bin/bash

# ShouArch Screenshot Utility

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

timestamp=$(date +"%Y%m%d_%H%M%S")

case "${1:-}" in
    "area")
        # Select area to screenshot
        filename="screenshot_area_${timestamp}.png"
        grim -g "$(slurp)" "$SCREENSHOT_DIR/$filename"
        ;;
    "window")
        # Active window screenshot  
        filename="screenshot_window_${timestamp}.png"
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$SCREENSHOT_DIR/$filename"
        ;;
    "screen"|*)
        # Full screen screenshot
        filename="screenshot_${timestamp}.png"
        grim "$SCREENSHOT_DIR/$filename"
        ;;
esac

# Copy to clipboard
wl-copy < "$SCREENSHOT_DIR/$filename"

# Notification
notify-send "Screenshot Captured" "Saved as $filename" -i "$SCREENSHOT_DIR/$filename"

echo "Screenshot saved: $SCREENSHOT_DIR/$filename"