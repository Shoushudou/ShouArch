#!/bin/bash

# ShouArch Advanced System Info with Progress Bars

create_progress_bar() {
    local value=$1
    local max=100
    local bar_width=20
    local filled=$((value * bar_width / max))
    local empty=$((bar_width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$value"
}

get_system_info_fancy() {
    # CPU
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f", usage}')
    
    # Memory
    mem_percent=$(free | grep Mem: | awk '{printf "%.0f", $3/$2 * 100}')
    mem_used=$(free -h | grep Mem: | awk '{print $3}')
    mem_total=$(free -h | grep Mem: | awk '{print $2}')
    
    # Disk
    disk_percent=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    disk_free=$(df -h / | awk 'NR==2 {print $4}')
    
    # Create fancy message with progress bars
    message="<b>🖥️ SHOUARCH SYSTEM INFO</b>\n\n"
    message+="<b>CPU:</b> $(create_progress_bar $cpu_usage)\n"
    message+="<b>RAM:</b> $(create_progress_bar $mem_percent) ${mem_used}/${mem_total}\n"
    message+="<b>Disk:</b> $(create_progress_bar $disk_percent) ${disk_free} free\n"
    
    # Battery if available
    if [[ -d "/sys/class/power_supply/BAT0" ]]; then
        battery=$(cat /sys/class/power_supply/BAT0/capacity)
        battery_status=$(cat /sys/class/power_supply/BAT0/status)
        message+="<b>Battery:</b> $(create_progress_bar $battery) $battery_status\n"
    fi
    
    # Music
    if pgrep -x "spotify" > /dev/null && command -v playerctl &> /dev/null; then
        music_info=$(playerctl -p spotify metadata --format '{{ artist }} - {{ title }}' 2>/dev/null)
        if [[ -n "$music_info" ]]; then
            message+="\n🎵 <i>$music_info</i>"
        fi
    fi
    
    echo -e "$message"
}

# Show fancy notification
if command -v notify-send &> /dev/null; then
    notify-send -t 8000 -a "ShouArch" "🖥️ System Info" "$(get_system_info_fancy)" -u normal
else
    get_system_info_fancy | sed 's/<[^>]*>//g'  # Remove HTML tags for terminal
fi