#!/bin/bash

# ShouArch Wallpaper Setter with Pywal Integration
# Supports 6 different wallpapers

WALLPAPER_DIR="/etc/configs/wallpapers"
SOUND_FILE="/etc/configs/sounds/click.oga"

# Available wallpapers
WALLPAPERS=(
    "default.png"
    "alt1.png" 
    "alt2.png"
    "alt3.png"
    "alt4.png"
    "alt5.png"
)

show_usage() {
    echo "Usage: $0 <wallpaper-file|random|list>"
    echo ""
    echo "Available wallpapers:"
    for i in "${!WALLPAPERS[@]}"; do
        echo "  $((i+1)). ${WALLPAPERS[$i]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 default.png           # Set specific wallpaper"
    echo "  $0 random                # Set random wallpaper"
    echo "  $0 list                  # List available wallpapers"
}

list_wallpapers() {
    echo "📁 Available wallpapers in $WALLPAPER_DIR:"
    for i in "${!WALLPAPERS[@]}"; do
        local wp="${WALLPAPERS[$i]}"
        if [[ -f "$WALLPAPER_DIR/$wp" ]]; then
            echo "  ✅ $((i+1)). $wp"
        else
            echo "  ❌ $((i+1)). $wp (missing)"
        fi
    done
}

set_random_wallpaper() {
    local available_wallpapers=()
    
    for wp in "${WALLPAPERS[@]}"; do
        if [[ -f "$WALLPAPER_DIR/$wp" ]]; then
            available_wallpapers+=("$wp")
        fi
    done
    
    if [[ ${#available_wallpapers[@]} -eq 0 ]]; then
        echo "❌ No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    local random_index=$((RANDOM % ${#available_wallpapers[@]}))
    local selected_wallpaper="${available_wallpapers[$random_index]}"
    
    echo "🎲 Randomly selected: $selected_wallpaper"
    set_wallpaper "$selected_wallpaper"
}

set_wallpaper() {
    local wallpaper="$1"
    local wallpaper_path="$WALLPAPER_DIR/$wallpaper"
    
    # Check if wallpaper exists
    if [[ ! -f "$wallpaper_path" ]]; then
        echo "❌ Wallpaper not found: $wallpaper_path"
        echo "📁 Available wallpapers:"
        ls -1 "$WALLPAPER_DIR" 2>/dev/null || echo "No wallpapers found"
        exit 1
    fi
    
    echo "🎨 Setting wallpaper: $wallpaper"
    
    # Set wallpaper with swww
    if command -v swww &> /dev/null; then
        swww img "$wallpaper_path" \
            --transition-type grow \
            --transition-pos 0.98,0.97 \
            --transition-step 255 \
            --transition-fps 60
    else
        # Fallback to feh
        echo "⚠️  SWWW not found, using feh fallback"
        feh --bg-scale "$wallpaper_path"
    fi
    
    # Generate Pywal colors
    echo "🎨 Generating Pywal colorscheme..."
    wal -i "$wallpaper_path" -n
    
    # Apply colors to Hyprland
    if command -v hyprctl &> /dev/null; then
        echo "🪟 Reloading Hyprland..."
        hyprctl reload
    fi
    
    # Play sound if available
    if [[ -f "$SOUND_FILE" ]] && command -v paplay &> /dev/null; then
        paplay "$SOUND_FILE" &
    fi
    
    # Update Spicetify if running
    if pgrep -x "spotify" > /dev/null && command -v spicetify &> /dev/null; then
        echo "🎵 Updating Spicetify..."
        spicetify update
    fi
    
    echo "✅ Wallpaper set to: $wallpaper"
    echo "🎨 Pywal colorscheme updated"
}

# Main script logic
case "${1:-}" in
    "list")
        list_wallpapers
        ;;
    "random"|"rnd")
        set_random_wallpaper
        ;;
    "")
        show_usage
        ;;
    *)
        if [[ "$1" =~ ^[1-6]$ ]]; then
            # Convert number to wallpaper filename
            local index=$((10#$1 - 1))
            if [[ $index -ge 0 && $index -lt ${#WALLPAPERS[@]} ]]; then
                set_wallpaper "${WALLPAPERS[$index]}"
            else
                echo "❌ Invalid wallpaper number: $1"
                show_usage
                exit 1
            fi
        else
            set_wallpaper "$1"
        fi
        ;;
esac