#!/bin/bash

# ShouArch System Dashboard

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"; }
print_footer() { echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"; }
print_divider() { echo -e "${CYAN}────────────────────────────────────────────${NC}"; }

show_system_info() {
    print_header
    echo -e "${MAGENTA}║${NC}            ${CYAN}SHOUARCH DASHBOARD${NC}             ${MAGENTA}║${NC}"
    print_footer
    
    # Fastfetch with custom config
    fastfetch --config /etc/configs/fastfetch.conf
    
    print_divider
}

show_performance() {
    echo -e "${YELLOW}⚡ PERFORMANCE STATUS:${NC}"
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local cpu_temp=$(sensors | grep 'Package id' | awk '{print $4}' | sed 's/+//' | head -1)
    
    # Memory
    local mem_total=$(free -h | grep Mem: | awk '{print $2}')
    local mem_used=$(free -h | grep Mem: | awk '{print $3}')
    local mem_percent=$(free | grep Mem: | awk '{printf "%.1f", $3/$2 * 100}')
    
    # Disk
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    
    echo -e "  CPU:    ${GREEN}${cpu_usage}%${NC} | Temp: ${cpu_temp:-N/A}"
    echo -e "  Memory: ${GREEN}${mem_used}/${mem_total} (${mem_percent}%)${NC}"
    echo -e "  Disk:   ${GREEN}${disk_usage} used${NC}"
    
    print_divider
}

show_network_status() {
    echo -e "${BLUE}🌐 NETWORK STATUS:${NC}"
    
    # IP Address
    local ip_addr=$(ip route get 1 | awk '{print $7}' | head -1)
    local ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    
    # Connection status
    if ping -c1 -W1 8.8.8.8 &>/dev/null; then
        local conn_status="${GREEN}Connected${NC}"
    else
        local conn_status="${RED}Disconnected${NC}"
    fi
    
    echo -e "  Status:   $conn_status"
    echo -e "  IP:       ${GREEN}${ip_addr:-N/A}${NC}"
    echo -e "  WiFi:     ${GREEN}${ssid:-N/A}${NC}"
    
    print_divider
}

show_service_status() {
    echo -e "${CYAN}🛠️ SERVICE STATUS:${NC}"
    
    local services=("NetworkManager" "bluetooth" "docker" "ssh")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  $service: ${GREEN}● Active${NC}"
        else
            echo -e "  $service: ${RED}○ Inactive${NC}"
        fi
    done
    
    print_divider
}

show_quick_actions() {
    echo -e "${GREEN}🎮 QUICK ACTIONS:${NC}"
    echo -e "  ${YELLOW}F1${NC} - Open System Monitor (btop)"
    echo -e "  ${YELLOW}F2${NC} - Check Gaming Mode"
    echo -e "  ${YELLOW}F3${NC} - Update System"
    echo -e "  ${YELLOW}F4${NC} - Backup Configs"
    echo -e "  ${YELLOW}F5${NC} - Toggle Theme"
    echo -e "  ${YELLOW}Q${NC}  - Exit Dashboard"
}

main_dashboard() {
    while true; do
        clear
        show_system_info
        show_performance
        show_network_status
        show_service_status
        show_quick_actions
        
        read -t 10 -n1 -p "Select action (1-5, Q to quit): " input
        case "${input:-}" in
            "1") btop ;;
            "2") ~/scripts/gaming-mode.sh status ;;
            "3") sudo pacman -Syu ;;
            "4") ~/scripts/backup-configs.sh ;;
            "5") ~/scripts/toggle-theme.sh ;;
            "q"|"Q") break ;;
        esac
    done
}

# Run dashboard
main_dashboard