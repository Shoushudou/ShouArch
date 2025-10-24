#!/bin/bash

# ShouArch Blue Light Filter (Night Light)

set -e

# Config
CONFIG_DIR="$HOME/.config/shouarch"
CONFIG_FILE="$CONFIG_DIR/nightlight.conf"
PID_FILE="/tmp/shouarch-nightlight.pid"
LOG_FILE="/tmp/shouarch-nightlight.log"

# Default settings
SUNSET_TIME="19:00"    # 7 PM
SUNRISE_TIME="07:00"   # 7 AM  
DAY_TEMPERATURE=6500   # Normal daylight
NIGHT_TEMPERATURE=3500 # Warm night light
TRANSITION_DURATION=1  # hours
AUTO_START=true
LOCATION_AUTO=true

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[→]${NC} $1"; }
print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_night() { echo -e "${MAGENTA}[🌙]${NC} $1"; }

# Load config if exists
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        print_info "Loaded config from $CONFIG_FILE"
    else
        print_info "Using default settings"
    fi
}

# Save config
save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# ShouArch Night Light Configuration
SUNSET_TIME="$SUNSET_TIME"
SUNRISE_TIME="$SUNRISE_TIME"
DAY_TEMPERATURE=$DAY_TEMPERATURE
NIGHT_TEMPERATURE=$NIGHT_TEMPERATURE
TRANSITION_DURATION=$TRANSITION_DURATION
AUTO_START=$AUTO_START
LOCATION_AUTO=$LOCATION_AUTO
EOF
    print_info "Config saved to $CONFIG_FILE"
}

# Get location-based sunset/sunrise times
get_sun_times() {
    if [[ "$LOCATION_AUTO" == "true" ]] && command -v curl &> /dev/null; then
        print_info "Fetching location-based sun times..."
        
        # Try to get location from IP
        local location_data=$(curl -s "http://ip-api.com/json/")
        local lat=$(echo "$location_data" | grep -o '"lat":[^,]*' | cut -d':' -f2)
        local lon=$(echo "$location_data" | grep -o '"lon":[^,]*' | cut -d':' -f2)
        
        if [[ -n "$lat" && -n "$lon" ]]; then
            # Get sun times from sunrise-sunset.org API
            local sun_data=$(curl -s "https://api.sunrise-sunset.org/json?lat=$lat&lng=$lon&formatted=0")
            local sunrise_utc=$(echo "$sun_data" | grep -o '"sunrise":"[^"]*' | cut -d'"' -f4)
            local sunset_utc=$(echo "$sun_data" | grep -o '"sunset":"[^"]*' | cut -d'"' -f4)
            
            if [[ -n "$sunrise_utc" && -n "$sunset_utc" ]]; then
                # Convert to local time
                SUNRISE_TIME=$(date -d "$sunrise_utc" +%H:%M 2>/dev/null || echo "$SUNRISE_TIME")
                SUNSET_TIME=$(date -d "$sunset_utc" +%H:%M 2>/dev/null || echo "$SUNSET_TIME")
                print_info "Location-based times: Sunrise $SUNRISE_TIME, Sunset $SUNSET_TIME"
            fi
        fi
    fi
}

# Check if it's nighttime
is_night_time() {
    local current_time=$(date +%H:%M)
    [[ "$current_time" > "$SUNSET_TIME" ]] || [[ "$current_time" < "$SUNRISE_TIME" ]]
}

# Get current temperature based on time (for smooth transitions)
get_current_temperature() {
    local current_time=$(date +%H:%M)
    local sunset_sec=$(date -d "$SUNSET_TIME" +%s 2>/dev/null || echo 0)
    local sunrise_sec=$(date -d "$SUNRISE_TIME" +%s 2>/dev/null || echo 0)
    local current_sec=$(date -d "$current_time" +%s 2>/dev/null || echo 0)
    
    # If we can't calculate times, use simple day/night
    if [[ $sunset_sec -eq 0 ]] || [[ $sunrise_sec -eq 0 ]]; then
        if is_night_time; then
            echo "$NIGHT_TEMPERATURE"
        else
            echo "$DAY_TEMPERATURE"
        fi
        return
    fi
    
    # Calculate transition periods
    local transition_sec=$((TRANSITION_DURATION * 3600 / 2))
    local night_start=$((sunset_sec - transition_sec))
    local night_end=$((sunrise_sec + transition_sec))
    
    if [[ $current_sec -ge $night_start ]] && [[ $current_sec -le $sunset_sec ]]; then
        # Evening transition
        local progress=$((current_sec - night_start))
        local total=$((sunset_sec - night_start))
        local temp_range=$((DAY_TEMPERATURE - NIGHT_TEMPERATURE))
        echo $((DAY_TEMPERATURE - (temp_range * progress / total)))
    elif [[ $current_sec -ge $sunrise_sec ]] && [[ $current_sec -le $night_end ]]; then
        # Morning transition
        local progress=$((current_sec - sunrise_sec))
        local total=$((night_end - sunrise_sec))
        local temp_range=$((DAY_TEMPERATURE - NIGHT_TEMPERATURE))
        echo $((NIGHT_TEMPERATURE + (temp_range * progress / total)))
    elif is_night_time; then
        echo "$NIGHT_TEMPERATURE"
    else
        echo "$DAY_TEMPERATURE"
    fi
}

# Check for available night light utilities
get_nightlight_util() {
    if command -v gammastep &> /dev/null; then
        echo "gammastep"
    elif command -v wlsunset &> /dev/null; then
        echo "wlsunset"
    elif command -v redshift &> /dev/null; then
        echo "redshift"
    else
        echo "none"
    fi
}

# Start night light with current temperature
start_night_light() {
    local util=$(get_nightlight_util)
    local temperature=${1:-$(get_current_temperature)}
    
    # Stop any existing instances
    stop_night_light
    
    print_night "Starting night light ($temperature K) with $util"
    
    case "$util" in
        "gammastep")
            if [[ "$temperature" == "$DAY_TEMPERATURE" ]]; then
                gammastep -x &
            else
                gammastep -O "$temperature" -b 0.8:0.7 &
            fi
            echo $! > "$PID_FILE"
            ;;
        "wlsunset")
            if [[ "$temperature" == "$DAY_TEMPERATURE" ]]; then
                wlsunset -T 6500 &
            else
                wlsunset -t "$temperature" -T 6500 &
            fi
            echo $! > "$PID_FILE"
            ;;
        "redshift")
            if [[ "$temperature" == "$DAY_TEMPERATURE" ]]; then
                redshift -x &
            else
                redshift -O "$temperature" -b 0.8:0.7 &
            fi
            echo $! > "$PID_FILE"
            ;;
        "none")
            print_error "No night light utility found. Install one of: gammastep, wlsunset, redshift"
            return 1
            ;;
    esac
    
    # Log the action
    echo "$(date): Started night light at ${temperature}K with $util" >> "$LOG_FILE"
    print_status "Night light active at ${temperature}K"
}

# Stop night light
stop_night_light() {
    local util=$(get_nightlight_util)
    
    print_info "Stopping night light..."
    
    case "$util" in
        "gammastep")
            pkill -f gammastep 2>/dev/null || true
            gammastep -x 2>/dev/null || true
            ;;
        "wlsunset")
            pkill -f wlsunset 2>/dev/null || true
            ;;
        "redshift")
            pkill -f redshift 2>/dev/null || true
            redshift -x 2>/dev/null || true
            ;;
    esac
    
    rm -f "$PID_FILE"
    echo "$(date): Stopped night light" >> "$LOG_FILE"
    print_status "Night light stopped"
}

# Toggle night light
toggle_night_light() {
    if is_running; then
        stop_night_light
    else
        start_night_light
    fi
}

# Check if night light is running
is_running() {
    [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null
}

# Auto mode based on time
auto_night_light() {
    if is_night_time; then
        if ! is_running || [[ "$(get_current_temperature)" != "$NIGHT_TEMPERATURE" ]]; then
            start_night_light "$NIGHT_TEMPERATURE"
        fi
    else
        if is_running; then
            stop_night_light
        fi
    fi
}

# Show current status
show_status() {
    local util=$(get_nightlight_util)
    local current_time=$(date +%H:%M)
    local current_temp=$(get_current_temperature)
    
    echo "🌙 ShouArch Night Light Status"
    echo "================================"
    echo ""
    echo "🕐 Current time: $current_time"
    echo "🌅 Sunrise: $SUNRISE_TIME"
    echo "🌇 Sunset: $SUNSET_TIME"
    echo "🎨 Current temperature: ${current_temp}K"
    echo "🔧 Available utility: $util"
    echo ""
    
    if is_running; then
        print_status "Status: ACTIVE"
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        echo "PID: $pid"
    else
        print_info "Status: INACTIVE"
    fi
    
    if is_night_time; then
        print_night "It's nighttime - night light should be active"
    else
        print_info "It's daytime - night light should be inactive"
    fi
}

# Configure settings interactively
configure_settings() {
    print_status "Configuring night light settings..."
    
    read -p "Sunset time (HH:MM) [$SUNSET_TIME]: " sunset_input
    [[ -n "$sunset_input" ]] && SUNSET_TIME="$sunset_input"
    
    read -p "Sunrise time (HH:MM) [$SUNRISE_TIME]: " sunrise_input
    [[ -n "$sunrise_input" ]] && SUNRISE_TIME="$sunrise_input"
    
    read -p "Night temperature (K) [$NIGHT_TEMPERATURE]: " temp_input
    [[ -n "$temp_input" ]] && NIGHT_TEMPERATURE="$temp_input"
    
    read -p "Transition duration (hours) [$TRANSITION_DURATION]: " transition_input
    [[ -n "$transition_input" ]] && TRANSITION_DURATION="$transition_input"
    
    read -p "Auto-start with system? (y/N) [$AUTO_START]: " auto_input
    if [[ "$auto_input" =~ [yY] ]]; then
        AUTO_START=true
    else
        AUTO_START=false
    fi
    
    read -p "Use location-based times? (y/N) [$LOCATION_AUTO]: " location_input
    if [[ "$location_input" =~ [yY] ]]; then
        LOCATION_AUTO=true
        get_sun_times
    else
        LOCATION_AUTO=false
    fi
    
    save_config
    print_status "Settings updated and saved"
}

# Setup auto-start
setup_autostart() {
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    cat > "$autostart_dir/shouarch-nightlight.desktop" << EOF
[Desktop Entry]
Type=Application
Name=ShouArch Night Light
Exec=$HOME/scripts/hypr-sunset.sh auto
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Auto-start night light
EOF
    
    print_status "Auto-start configured"
}

# Monitor mode (for debugging)
monitor_mode() {
    print_status "Entering monitor mode (Ctrl+C to exit)..."
    while true; do
        clear
        show_status
        echo ""
        echo "Monitoring... (Ctrl+C to exit)"
        echo "Last update: $(date)"
        sleep 5
    done
}

# Main execution
main() {
    load_config
    
    case "${1:-}" in
        "on"|"start"|"enable")
            start_night_light "$NIGHT_TEMPERATURE"
            ;;
        "off"|"stop"|"disable")
            stop_night_light
            ;;
        "toggle")
            toggle_night_light
            ;;
        "auto")
            auto_night_light
            ;;
        "status")
            show_status
            ;;
        "config"|"configure")
            configure_settings
            ;;
        "autostart")
            setup_autostart
            ;;
        "monitor")
            monitor_mode
            ;;
        "reset")
            rm -f "$CONFIG_FILE" "$PID_FILE"
            print_status "Configuration reset"
            ;;
        "help"|"-h"|"--help")
            echo "ShouArch Night Light (Blue Light Filter)"
            echo ""
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  on, start     - Enable night light"
            echo "  off, stop     - Disable night light"
            echo "  toggle        - Toggle night light"
            echo "  auto          - Auto enable/disable based on time"
            echo "  status        - Show current status"
            echo "  config        - Interactive configuration"
            echo "  autostart     - Setup auto-start"
            echo "  monitor       - Real-time monitoring mode"
            echo "  reset         - Reset configuration"
            echo "  help          - Show this help"
            echo ""
            echo "Features:"
            echo "  • Multiple backends (gammastep, wlsunset, redshift)"
            echo "  • Location-based sunset/sunrise times"
            echo "  • Smooth temperature transitions"
            echo "  • Auto-start capability"
            echo "  • Configurable temperatures and times"
            ;;
        *)
            if [[ -z "$1" ]]; then
                show_status
            else
                echo "Unknown command: $1"
                echo "Use '$0 help' for usage information."
                exit 1
            fi
            ;;
    esac
}

# Run main function
main "$@"