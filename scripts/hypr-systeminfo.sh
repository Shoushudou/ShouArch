#!/bin/bash

# ShouArch System Info Popup for Hyprland

get_system_info() {
    # CPU Usage (more accurate method)
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
    
    # CPU Temperature (multiple fallbacks)
    cpu_temp="N/A"
    if command -v sensors &> /dev/null; then
        # Try Package id first, then Core 0
        cpu_temp=$(sensors | grep -E "(Package id|Core 0|Tdie|Tctl)" | head -1 | awk '{print $2}' | sed 's/+//' | tr -d '\n')
    fi
    
    if [[ "$cpu_temp" == "N/A" ]] || [[ -z "$cpu_temp" ]]; then
        # Fallback to thermal zone
        if [[ -f "/sys/class/thermal/thermal_zone0/temp" ]]; then
            cpu_temp=$(echo "scale=1; $(cat /sys/class/thermal/thermal_zone0/temp) / 1000" | bc)"°C"
        fi
    fi

    # Memory with more details
    mem_info=$(free -h)
    mem_total=$(echo "$mem_info" | grep Mem: | awk '{print $2}')
    mem_used=$(echo "$mem_info" | grep Mem: | awk '{print $3}')
    mem_available=$(echo "$mem_info" | grep Mem: | awk '{print $7}')
    mem_percent=$(free | grep Mem: | awk '{printf "%.1f", $3/$2 * 100}')

    # Disk with multiple partitions
    root_disk=$(df -h / | awk 'NR==2 {print $5 " (" $4 " free)"}')
    home_disk=$(df -h /home 2>/dev/null | awk 'NR==2 {print $5 " (" $4 " free)"}' || echo "N/A")

    # Battery with status
    battery_info="🔌 AC Power"
    if [[ -d "/sys/class/power_supply/BAT0" ]]; then
        battery_capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        battery_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        
        case "$battery_status" in
            "Charging") battery_icon="⚡" ;;
            "Discharging") battery_icon="🔋" ;;
            "Full") battery_icon="✅" ;;
            *) battery_icon="🔋" ;;
        esac
        battery_info="$battery_icon $battery_capacity% ($battery_status)"
    fi

    # Uptime
    uptime=$(uptime -p | sed 's/up //')

    # GPU info (if available)
    gpu_info=""
    if command -v nvidia-smi &> /dev/null; then
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1)
        gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -1)
        gpu_info="🔸 GPU: $gpu_util% | ${gpu_temp}°C\n"
    elif command -v rocm-smi &> /dev/null; then
        gpu_temp=$(rocm-smi --showtemp | grep -oP 'Temperature.*?\K\d+' | head -1)
        gpu_info="🔸 GPU: ${gpu_temp}°C\n"
    fi

    # Network info
    network_info=""
    if command -v nmcli &> /dev/null; then
        network_status=$(nmcli -t -f STATE general)
        if [[ "$network_status" == "connected" ]]; then
            network_device=$(nmcli -t -f DEVICE connection show --active | head -1)
            network_type=$(nmcli -t -f TYPE connection show --active | head -1)
            network_info="🔸 Network: $network_device ($network_type)\n"
        else
            network_info="🔸 Network: Disconnected\n"
        fi
    fi

    # Current music
    music_info=""
    if pgrep -x "spotify" > /dev/null && command -v playerctl &> /dev/null; then
        music_info=$(playerctl -p spotify metadata --format '{{ artist }} - {{ title }}' 2>/dev/null)
        if [[ -n "$music_info" ]]; then
            music_info="🎵 $music_info"
        else
            music_info="🎵 No track playing"
        fi
    else
        music_info="🎵 Spotify not running"
    fi

    # System load
    load_avg=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')

    # Create notification message
    message="🖥️  SHOUARCH SYSTEM INFO\n\n"
    message+="🔸 CPU: ${cpu_usage}% | ${cpu_temp}\n"
    message+="🔸 RAM: ${mem_used}/${mem_total} (${mem_percent}%)\n"
    message+="🔸 Disk: / $root_disk\n"
    if [[ "$home_disk" != "N/A" ]]; then
        message+="🔸 Home: $home_disk\n"
    fi
    message+="$gpu_info"
    message+="$network_info"
    message+="🔸 $battery_info\n"
    message+="🔸 Load: $load_avg\n"
    message+="🔸 Uptime: $uptime\n"
    message+="\n$music_info"

    echo -e "$message"
}

# Function to show compact info for waybar tooltip
get_compact_info() {
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
    mem_percent=$(free | grep Mem: | awk '{printf "%.1f", $3/$2 * 100}')
    
    echo "CPU: ${cpu_usage}% | RAM: ${mem_percent}%"
}

# Handle different modes
case "${1:-}" in
    "compact"|"tooltip")
        get_compact_info
        ;;
    "notify"|"")
        # Show system info popup
        if command -v notify-send &> /dev/null; then
            notify-send -t 8000 -a "ShouArch" "🖥️ System Info" "$(get_system_info)" -u normal
        else
            echo "❌ notify-send not available"
            get_system_info
        fi
        ;;
    "cli")
        get_system_info
        ;;
    "watch")
        # Continuous monitoring
        watch -n 2 ~/scripts/hypr-systeminfo.sh cli
        ;;
    *)
        echo "Usage: $0 [compact|notify|cli|watch]"
        echo "  compact  - Show compact info for tooltips"
        echo "  notify   - Show desktop notification (default)"
        echo "  cli      - Show info in terminal"
        echo "  watch    - Continuous monitoring"
        ;;
esac