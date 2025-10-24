#!/bin/bash

# ShouArch On-Screen Display for Media & System Controls

# Config
OSD_TIMEOUT=2000  # ms
OSD_URGENCY="normal"
DUNST_CATEGORY="shouarch-osd"

# Colors for progress bars (RGB)
PROGRESS_COLOR="66ff00"
PROGRESS_BG_COLOR="333333"

# Notification IDs for different types
VOLUME_ID=9999
BRIGHTNESS_ID=9998
MUSIC_ID=9997
MIC_ID=9996
MEDIA_ID=9995
SYSTEM_ID=9994

print_error() {
    echo "❌ OSD Error: $1" >&2
}

show_osd() {
    local type=$1
    local value=$2
    local icon=$3
    local extra_info=$4
    
    case "$type" in
        "volume")
            dunstify -h "int:value:$value" \
                     -h "string:hlcolor:#$PROGRESS_COLOR" \
                     -h "string:bgcolor:#$PROGRESS_BG_COLOR" \
                     -t "$OSD_TIMEOUT" \
                     -a "ShouArch" \
                     -u "$OSD_URGENCY" \
                     -r "$VOLUME_ID" \
                     -c "$DUNST_CATEGORY" \
                     "$icon Volume" "$value%$extra_info"
            ;;
        "brightness")
            dunstify -h "int:value:$value" \
                     -h "string:hlcolor:#$PROGRESS_COLOR" \
                     -h "string:bgcolor:#$PROGRESS_BG_COLOR" \
                     -t "$OSD_TIMEOUT" \
                     -a "ShouArch" \
                     -u "$OSD_URGENCY" \
                     -r "$BRIGHTNESS_ID" \
                     -c "$DUNST_CATEGORY" \
                     "$icon Brightness" "$value%$extra_info"
            ;;
        "music")
            dunstify -t "$OSD_TIMEOUT" \
                     -a "ShouArch" \
                     -u "$OSD_URGENCY" \
                     -r "$MUSIC_ID" \
                     -c "$DUNST_CATEGORY" \
                     "$icon Music" "$value"
            ;;
        "microphone")
            dunstify -t "$OSD_TIMEOUT" \
                     -a "ShouArch" \
                     -u "$OSD_URGENCY" \
                     -r "$MIC_ID" \
                     -c "$DUNST_CATEGORY" \
                     "$icon Microphone" "$value"
            ;;
        "media")
            dunstify -t "$OSD_TIMEOUT" \
                     -a "ShouArch" \
                     -u "$OSD_URGENCY" \
                     -r "$MEDIA_ID" \
                     -c "$DUNST_CATEGORY" \
                     "$icon Media" "$value"
            ;;
        "system")
            dunstify -t "$OSD_TIMEOUT" \
                     -a "ShouArch" \
                     -u "$OSD_URGENCY" \
                     -r "$SYSTEM_ID" \
                     -c "$DUNST_CATEGORY" \
                     "$icon System" "$value"
            ;;
    esac
}

# Audio controls
get_volume() {
    if command -v wpctl &> /dev/null; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d' ' -f2 | awk '{printf "%.0f", $1*100}'
    elif command -v pamixer &> /dev/null; then
        pamixer --get-volume
    else
        echo "0"
    fi
}

get_mute_status() {
    if command -v wpctl &> /dev/null; then
        wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "1" || echo "0"
    elif command -v pamixer &> /dev/null; then
        pamixer --get-mute && echo "1" || echo "0"
    else
        echo "0"
    fi
}

volume_up() {
    local step=${1:-5}
    
    if command -v wpctl &> /dev/null; then
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ ${step}%+
    elif command -v pamixer &> /dev/null; then
        pamixer -i "$step"
    else
        print_error "No volume control utility found"
        return 1
    fi
    
    local volume=$(get_volume)
    local muted=$(get_mute_status)
    
    if [[ "$muted" == "1" ]]; then
        show_osd "volume" "$volume" "🔇" " (Muted)"
    else
        show_osd "volume" "$volume" "🔊" ""
    fi
}

volume_down() {
    local step=${1:-5}
    
    if command -v wpctl &> /dev/null; then
        wpctl set-volume @DEFAULT_AUDIO_SINK@ ${step}%-
    elif command -v pamixer &> /dev/null; then
        pamixer -d "$step"
    else
        print_error "No volume control utility found"
        return 1
    fi
    
    local volume=$(get_volume)
    local muted=$(get_mute_status)
    
    if [[ "$muted" == "1" ]]; then
        show_osd "volume" "$volume" "🔇" " (Muted)"
    else
        show_osd "volume" "$volume" "🔊" ""
    fi
}

volume_mute() {
    if command -v wpctl &> /dev/null; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    elif command -v pamixer &> /dev/null; then
        pamixer -t
    else
        print_error "No volume control utility found"
        return 1
    fi
    
    local volume=$(get_volume)
    local muted=$(get_mute_status)
    
    if [[ "$muted" == "1" ]]; then
        show_osd "volume" "$volume" "🔇" " (Muted)"
    else
        show_osd "volume" "$volume" "🔊" ""
    fi
}

# Microphone controls
mic_mute() {
    if command -v wpctl &> /dev/null; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        local muted=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo "Muted" || echo "Unmuted")
        show_osd "microphone" "$muted" "🎤"
    elif command -v pamixer &> /dev/null; then
        pamixer --default-source -t
        local muted=$(pamixer --default-source --get-mute && echo "Muted" || echo "Unmuted")
        show_osd "microphone" "$muted" "🎤"
    else
        print_error "No microphone control utility found"
    fi
}

# Brightness controls
get_brightness() {
    if command -v brightnessctl &> /dev/null; then
        local current=$(brightnessctl g)
        local max=$(brightnessctl m)
        echo $(( (current * 100) / max ))
    elif [[ -f "/sys/class/backlight/intel_backlight/brightness" ]]; then
        local current=$(cat /sys/class/backlight/intel_backlight/brightness)
        local max=$(cat /sys/class/backlight/intel_backlight/max_brightness)
        echo $(( (current * 100) / max ))
    else
        echo "0"
    fi
}

brightness_up() {
    local step=${1:-5}
    local current_percent=$(get_brightness)
    
    if [[ $current_percent -lt 100 ]]; then
        if command -v brightnessctl &> /dev/null; then
            brightnessctl set "${step}%+"
        elif [[ -f "/sys/class/backlight/intel_backlight/brightness" ]]; then
            local max=$(cat /sys/class/backlight/intel_backlight/max_brightness)
            local step_abs=$(( max * step / 100 ))
            local current=$(cat /sys/class/backlight/intel_backlight/brightness)
            local new=$(( current + step_abs ))
            [[ $new -gt $max ]] && new=$max
            echo "$new" | sudo tee /sys/class/backlight/intel_backlight/brightness > /dev/null
        else
            print_error "No brightness control utility found"
            return 1
        fi
        
        local new_percent=$(get_brightness)
        show_osd "brightness" "$new_percent" "💡"
    else
        show_osd "brightness" "100" "💡" " (Max)"
    fi
}

brightness_down() {
    local step=${1:-5}
    local current_percent=$(get_brightness)
    
    if [[ $current_percent -gt 5 ]]; then
        if command -v brightnessctl &> /dev/null; then
            brightnessctl set "${step}%-"
        elif [[ -f "/sys/class/backlight/intel_backlight/brightness" ]]; then
            local max=$(cat /sys/class/backlight/intel_backlight/max_brightness)
            local step_abs=$(( max * step / 100 ))
            local current=$(cat /sys/class/backlight/intel_backlight/brightness)
            local new=$(( current - step_abs ))
            [[ $new -lt 1 ]] && new=1
            echo "$new" | sudo tee /sys/class/backlight/intel_backlight/brightness > /dev/null
        else
            print_error "No brightness control utility found"
            return 1
        fi
        
        local new_percent=$(get_brightness)
        show_osd "brightness" "$new_percent" "💡"
    else
        show_osd "brightness" "5" "💡" " (Min)"
    fi
}

# Media controls with multiple player support
get_current_player() {
    # Try to get the best available player
    if playerctl -p spotify status &>/dev/null; then
        echo "spotify"
    elif playerctl -p vlc status &>/dev/null; then
        echo "vlc"
    elif playerctl -p mpv status &>/dev/null; then
        echo "mpv"
    else
        # Get first available player
        playerctl -l 2>/dev/null | head -1
    fi
}

music_playpause() {
    local player=$(get_current_player)
    
    if [[ -n "$player" ]]; then
        playerctl -p "$player" play-pause
        local status=$(playerctl -p "$player" status 2>/dev/null)
        
        if [[ "$status" == "Playing" ]]; then
            local track=$(playerctl -p "$player" metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo "Unknown Track")
            show_osd "music" "$track" "▶️"
        else
            show_osd "music" "Paused" "⏸️"
        fi
    else
        show_osd "music" "No media player active" "⏹️"
    fi
}

music_next() {
    local player=$(get_current_player)
    
    if [[ -n "$player" ]]; then
        playerctl -p "$player" next
        sleep 0.8  # Wait for track to change
        local track=$(playerctl -p "$player" metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo "Unknown Track")
        show_osd "music" "$track" "⏭️"
    else
        show_osd "music" "No media player active" "⏹️"
    fi
}

music_prev() {
    local player=$(get_current_player)
    
    if [[ -n "$player" ]]; then
        playerctl -p "$player" previous
        sleep 0.8  # Wait for track to change
        local track=$(playerctl -p "$player" metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo "Unknown Track")
        show_osd "music" "$track" "⏮️"
    else
        show_osd "music" "No media player active" "⏹️"
    fi
}

music_stop() {
    local player=$(get_current_player)
    
    if [[ -n "$player" ]]; then
        playerctl -p "$player" stop
        show_osd "music" "Playback stopped" "⏹️"
    else
        show_osd "music" "No media player active" "⏹️"
    fi
}

# System controls
show_system_info() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_used=$(free -h | grep Mem: | awk '{print $3}')
    local mem_total=$(free -h | grep Mem: | awk '{print $2}')
    
    local info="CPU: ${cpu_usage}% | RAM: ${mem_used}/${mem_total}"
    show_osd "system" "$info" "🖥️"
}

show_power_menu() {
    local choice=$(echo -e "Shutdown\nRestart\nSleep\nLogout" | rofi -dmenu -p "Power:" -theme-str 'window {width: 20%;}')
    
    case "$choice" in
        "Shutdown") systemctl poweroff ;;
        "Restart") systemctl reboot ;;
        "Sleep") systemctl suspend ;;
        "Logout") hyprctl dispatch exit ;;
    esac
}

# Screenshot with OSD
screenshot_area() {
    ~/scripts/screenshot.sh area
    show_osd "media" "Screenshot captured" "📸"
}

screenshot_full() {
    ~/scripts/screenshot.sh screen
    show_osd "media" "Fullscreen screenshot captured" "📸"
}

# Help function
show_help() {
    echo "ShouArch On-Screen Display Controls"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Audio Commands:"
    echo "  volume-up [STEP]      Increase volume (default: 5%)"
    echo "  volume-down [STEP]    Decrease volume (default: 5%)"
    echo "  volume-mute           Toggle mute"
    echo "  mic-mute              Toggle microphone mute"
    echo ""
    echo "Display Commands:"
    echo "  brightness-up [STEP]  Increase brightness (default: 5%)"
    echo "  brightness-down [STEP] Decrease brightness (default: 5%)"
    echo ""
    echo "Media Commands:"
    echo "  music-playpause       Play/Pause current media"
    echo "  music-next            Next track"
    echo "  music-prev            Previous track"
    echo "  music-stop            Stop playback"
    echo ""
    echo "System Commands:"
    echo "  system-info           Show system status"
    echo "  power-menu            Show power options"
    echo "  screenshot-area       Capture area screenshot"
    echo "  screenshot-full       Capture fullscreen screenshot"
    echo ""
    echo "Examples:"
    echo "  $0 volume-up 10       # Increase volume by 10%"
    echo "  $0 brightness-down    # Decrease brightness by 5%"
    echo "  $0 music-next         # Next track"
}

# Main command handler
case "${1:-}" in
    # Audio
    "volume-up") volume_up "${2:-5}" ;;
    "volume-down") volume_down "${2:-5}" ;;
    "volume-mute") volume_mute ;;
    "mic-mute") mic_mute ;;
    
    # Display
    "brightness-up") brightness_up "${2:-5}" ;;
    "brightness-down") brightness_down "${2:-5}" ;;
    
    # Media
    "music-playpause") music_playpause ;;
    "music-next") music_next ;;
    "music-prev") music_prev ;;
    "music-stop") music_stop ;;
    
    # System
    "system-info") show_system_info ;;
    "power-menu") show_power_menu ;;
    "screenshot-area") screenshot_area ;;
    "screenshot-full") screenshot_full ;;
    
    # Help
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        if [[ -z "$1" ]]; then
            show_help
        else
            echo "Unknown command: $1"
            echo "Use '$0 help' for usage information."
            exit 1
        fi
        ;;
esac