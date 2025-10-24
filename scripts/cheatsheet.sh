#!/bin/bash

# ShouArch Keybinds Cheatsheet with Interactive Features

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_section() {
    echo -e "${MAGENTA}$1${NC}"
}

print_keybind() {
    echo -e "  ${YELLOW}$1${NC} $2"
}

print_category() {
    echo -e "${CYAN}$1${NC}"
}

show_cheatsheet() {
    clear
    echo -e "${GREEN}🎮 SHOUARCH KEYBINDS CHEATSHEET${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo ""
    
    print_section "🌐 WEB & BROWSER"
    print_keybind "Super + F1" "Firefox"
    print_keybind "Super + Shift + F1" "Chrome"
    print_keybind "Super + F2" "Thorium"
    print_keybind "Super + F3" "Brave"
    echo ""
    
    print_section "💻 DEVELOPMENT"
    print_keybind "Super + C" "VS Code"
    print_keybind "Super + Shift + C" "VS Codium"
    print_keybind "Super + T" "Kitty Terminal"
    print_keybind "Super + Shift + T" "WezTerm"
    print_keybind "Super + ;" "NeoVim"
    print_keybind "Super + G" "GitHub Desktop"
    echo ""
    
    print_section "📁 FILE MANAGEMENT"
    print_keybind "Super + E" "Thunar"
    print_keybind "Super + Shift + E" "Nautilus"
    print_keybind "Super + F" "Nemo"
    print_keybind "Super + R" "Ranger (in Kitty)"
    echo ""
    
    print_section "💬 COMMUNICATION"
    print_keybind "Super + D" "Discord"
    print_keybind "Super + Shift + D" "Webcord"
    print_keybind "Super + M" "Telegram"
    print_keybind "Super + Shift + M" "Element"
    print_keybind "Super + B" "Thunderbird"
    echo ""
    
    print_section "🎵 MEDIA & CREATIVE"
    print_keybind "Super + S" "Spotify"
    print_keybind "Super + Shift + S" "Spotify (Launcher)"
    print_keybind "Super + V" "VLC"
    print_keybind "Super + Shift + V" "MPV"
    print_keybind "Super + O" "OBS Studio"
    print_keybind "Super + Shift + O" "Kdenlive"
    print_keybind "Super + P" "GIMP"
    print_keybind "Super + Shift + P" "Inkscape"
    echo ""
    
    print_section "🎮 GAMING"
    print_keybind "Super + A" "Steam"
    print_keybind "Super + Shift + A" "Lutris"
    print_keybind "Super + Z" "Bottles"
    print_keybind "Super + Shift + Z" "Heroic"
    print_keybind "Super + L" "Gaming Mode ON"
    print_keybind "Super + Shift + L" "Gaming Mode OFF"
    echo ""
    
    print_section "⚙️ SYSTEM & UTILITIES"
    print_keybind "Super + X" "System Info"
    print_keybind "Super + Shift + X" "System Dashboard"
    print_keybind "Super + W" "Random Wallpaper"
    print_keybind "Super + N" "Toggle Night Light"
    print_keybind "Super + Space" "App Launcher"
    print_keybind "Super + Q" "Quick Settings"
    print_keybind "Super + I" "System Monitor"
    print_keybind "Super + Shift + I" "btop"
    echo ""
    
    print_section "📸 SCREENSHOT & RECORDING"
    print_keybind "Super + Print" "Area Screenshot"
    print_keybind "Super + Shift + Print" "Window Screenshot"
    print_keybind "Super + Ctrl + Print" "Fullscreen Screenshot"
    print_keybind "Super + K" "Start Recording"
    print_keybind "Super + Shift + K" "Stop Recording"
    echo ""
    
    print_section "🪟 WINDOW MANAGEMENT"
    print_keybind "Super + H/J/K/L" "Move Focus (hy3)"
    print_keybind "Super + Shift + H/J/K/L" "Move Window (hy3)"
    print_keybind "Super + Tab" "Next Tab (hy3)"
    print_keybind "Super + Shift + Tab" "Previous Tab (hy3)"
    print_keybind "Super + U" "Toggle Window Wrapping"
    print_keybind "Super + Enter" "Toggle Fullscreen"
    print_keybind "Super + Shift + Enter" "Toggle Floating"
    echo ""
    
    print_section "🎵 MUSIC CONTROLS"
    print_keybind "Super + F7" "Play/Pause"
    print_keybind "Super + F8" "Next Track"
    print_keybind "Super + F9" "Previous Track"
    print_keybind "Super + Shift + F8" "Next Album (Random)"
    echo ""
    
    print_section "🔊 AUDIO CONTROLS"
    print_keybind "Volume Up" "Volume +5% (with OSD)"
    print_keybind "Volume Down" "Volume -5% (with OSD)"
    print_keybind "Volume Mute" "Toggle Mute (with OSD)"
    print_keybind "Super + F10" "Audio Settings (pavucontrol)"
    echo ""
    
    print_section "💡 DISPLAY CONTROLS"
    print_keybind "Brightness Up" "Brightness +5% (with OSD)"
    print_keybind "Brightness Down" "Brightness -5% (with OSD)"
    print_keybind "Super + F11" "Display Settings"
    echo ""
}

show_quick_reference() {
    echo -e "${YELLOW}🚀 QUICK REFERENCE:${NC}"
    echo -e "  ${GREEN}cheatsheet${NC}       - Show this full cheatsheet"
    echo -e "  ${GREEN}cheatsheet quick${NC} - Show quick reference"
    echo -e "  ${GREEN}cheatsheet search${NC} - Search for specific keybind"
    echo -e "  ${GREEN}cheatsheet apps${NC}   - Show app launcher categories"
    echo -e "  ${GREEN}cheatsheet hypr${NC}   - Show Hyprland config location"
    echo ""
}

show_quick_cheatsheet() {
    echo -e "${GREEN}🎮 SHOUARCH QUICK REFERENCE${NC}"
    echo -e "${BLUE}=============================${NC}"
    echo ""
    
    print_category "ESSENTIAL SHORTCUTS:"
    print_keybind "Super + Space" "App Launcher"
    print_keybind "Super + Q" "Quick Settings"
    print_keybind "Super + X" "System Info"
    print_keybind "Super + W" "Random Wallpaper"
    print_keybind "Super + T" "Terminal"
    print_keybind "Super + E" "File Manager"
    echo ""
    
    print_category "MEDIA CONTROL:"
    print_keybind "Super + S" "Spotify"
    print_keybind "Super + F7" "Play/Pause"
    print_keybind "Super + F8" "Next Track"
    print_keybind "Super + N" "Night Light"
    echo ""
    
    print_category "WINDOW MANAGEMENT:"
    print_keybind "Super + H/J/K/L" "Move Focus"
    print_keybind "Super + Enter" "Fullscreen"
    print_keybind "Super + Tab" "Next Tab"
    echo ""
    
    echo -e "${YELLOW}💡 Tip: Use 'cheatsheet' for full reference${NC}"
}

search_keybind() {
    local query="${1:-}"
    if [[ -z "$query" ]]; then
        echo -e "${YELLOW}Enter search term:${NC} "
        read -r query
    fi
    
    echo -e "${GREEN}🔍 Search results for: $query${NC}"
    echo ""
    
    # Simple grep-based search through the cheatsheet
    show_cheatsheet | grep -i -A2 -B2 "$query" || echo -e "${RED}No results found for: $query${NC}"
}

show_app_categories() {
    echo -e "${GREEN}📱 APP LAUNCHER CATEGORIES${NC}"
    echo -e "${BLUE}=============================${NC}"
    echo ""
    echo -e "  ${CYAN}./app-launcher.sh web${NC}      - Web Browsers"
    echo -e "  ${CYAN}./app-launcher.sh dev${NC}      - Development Tools"
    echo -e "  ${CYAN}./app-launcher.sh media${NC}    - Media & Creative"
    echo -e "  ${CYAN}./app-launcher.sh game${NC}     - Gaming"
    echo -e "  ${CYAN}./app-launcher.sh utils${NC}    - Utilities"
    echo -e "  ${CYAN}./app-launcher.sh comms${NC}    - Communication"
    echo -e "  ${CYAN}./app-launcher.sh settings${NC} - System Settings"
    echo ""
    echo -e "${YELLOW}Or use: ${GREEN}Super + Space${NC} for visual launcher"
}

show_hypr_info() {
    echo -e "${GREEN}🪟 HYPRLAND CONFIGURATION${NC}"
    echo -e "${BLUE}=============================${NC}"
    echo ""
    echo -e "  ${CYAN}Config File:${NC} ~/.config/hypr/hyprland.conf"
    echo -e "  ${CYAN}Edit Config:${NC} ${GREEN}hyprconf${NC} or ${GREEN}nano ~/.config/hypr/hyprland.conf${NC}"
    echo -e "  ${CYAN}Reload Config:${NC} ${GREEN}Super + Shift + R${NC}"
    echo ""
    echo -e "  ${YELLOW}Useful Commands:${NC}"
    echo -e "  ${GREEN}hyprctl monitors${NC}    - Show monitor info"
    echo -e "  ${GREEN}hyprctl clients${NC}     - Show open windows"
    echo -e "  ${GREEN}hyprctl keyword${NC}     - Change settings temporarily"
    echo -e "  ${GREEN}hyprctl reload${NC}      - Reload configuration"
    echo ""
}

# Interactive mode
interactive_mode() {
    while true; do
        echo ""
        echo -e "${GREEN}🎮 ShouArch Cheatsheet Menu${NC}"
        echo -e "${BLUE}=============================${NC}"
        echo ""
        echo -e "  ${CYAN}1${NC} - Full Cheatsheet"
        echo -e "  ${CYAN}2${NC} - Quick Reference" 
        echo -e "  ${CYAN}3${NC} - Search Keybinds"
        echo -e "  ${CYAN}4${NC} - App Categories"
        echo -e "  ${CYAN}5${NC} - Hyprland Info"
        echo -e "  ${CYAN}6${NC} - Test Keybind"
        echo -e "  ${CYAN}0${NC} - Exit"
        echo ""
        read -p "Select option (0-6): " choice
        
        case $choice in
            1) show_cheatsheet ;;
            2) show_quick_cheatsheet ;;
            3) 
                read -p "Enter search term: " search_term
                search_keybind "$search_term"
                ;;
            4) show_app_categories ;;
            5) show_hypr_info ;;
            6) 
                echo -e "${YELLOW}Enter keybind to test (e.g., 'Super + T'):${NC}"
                read -p "Keybind: " keybind
                echo -e "${GREEN}Testing: $keybind${NC}"
                echo -e "${YELLOW}This would execute the associated command${NC}"
                ;;
            0) 
                echo -e "${GREEN}🎉 Happy computing! Use 'cheatsheet' anytime.${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
    done
}

# Main execution
case "${1:-}" in
    "quick"|"q")
        show_quick_cheatsheet
        ;;
    "search"|"s")
        search_keybind "$2"
        ;;
    "apps"|"a")
        show_app_categories
        ;;
    "hypr"|"h")
        show_hypr_info
        ;;
    "interactive"|"i")
        interactive_mode
        ;;
    "help"|"-h"|"--help")
        echo -e "${GREEN}ShouArch Cheatsheet Help${NC}"
        echo ""
        echo "Usage: cheatsheet [option]"
        echo ""
        echo "Options:"
        echo "  (no option)  Show full cheatsheet"
        echo "  quick, q     Show quick reference"
        echo "  search, s    Search for keybinds"
        echo "  apps, a      Show app categories"
        echo "  hypr, h      Show Hyprland info"
        echo "  interactive, i Interactive mode"
        echo "  help         Show this help"
        ;;
    *)
        if [[ -t 1 ]]; then
            # If output is to terminal, show full cheatsheet
            show_cheatsheet
            show_quick_reference
        else
            # If being piped or redirected, show minimal version
            show_quick_cheatsheet
        fi
        ;;
esac