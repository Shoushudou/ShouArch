#!/bin/bash

# ShouArch Quick Settings Menu

set -e

# Config
ROFI_THEME="$HOME/.config/rofi/quick-settings.rasi"
LOG_FILE="/tmp/shouarch-quick-settings.log"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[→]${NC} $1"; }
print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Check dependencies
check_dependencies() {
    if ! command -v rofi &> /dev/null; then
        print_error "rofi is required but not installed"
        exit 1
    fi
}

# Get menu options based on available tools
get_menu_options() {
    local options=()
    
    # Always available options
    options+=("🎵 Audio Settings")
    options+=("💡 Display Settings") 
    options+=("🔗 Network Settings")
    options+=("🎨 Appearance")
    options+=("🔄 System Update")
    options+=("📊 System Info")
    options+=("🌙 Night Light")
    options+=("🚀 Gaming Mode")
    options+=("🔒 Security & Privacy")
    options+=("⚡ Performance")
    options+=("🛠️ Utilities")
    options+=("🎮 Game Launcher")
    options+=("📸 Screenshot Tools")
    options+=("🔧 Advanced Settings")
    options+=("❓ Help & About")
    
    echo "$(printf '%s\n' "${options[@]}")"
}

# Audio settings
audio_settings() {
    print_status "Opening audio settings..."
    
    if command -v pavucontrol &> /dev/null; then
        pavucontrol &
    elif command -v wpctl &> /dev/null; then
        # Fallback to terminal-based control
        kitty -e bash -c 'echo "Audio Devices:"; wpctl status; echo "Press any key to exit"; read -n1' &
    else
        notify-send -t 3000 "Audio Settings" "No audio control utility found"
    fi
}

# Display settings
display_settings() {
    print_status "Opening display settings..."
    
    if command -v arandr &> /dev/null; then
        arandr &
    elif command -v kanshi &> /dev/null; then
        # Hyprland-friendly alternative
        kitty -e nvim ~/.config/kanshi/config &
    else
        notify-send -t 3000 "Display Settings" "Install arandr for display configuration"
    fi
}

# Network settings
network_settings() {
    print_status "Opening network settings..."
    
    if command -v nm-connection-editor &> /dev/null; then
        nm-connection-editor &
    elif command -v nmtui &> /dev/null; then
        kitty -e nmtui &
    else
        notify-send -t 3000 "Network Settings" "Network manager tools not available"
    fi
}

# Appearance settings
appearance_settings() {
    print_status "Opening appearance settings..."
    
    if command -v lxappearance &> /dev/null; then
        lxappearance &
    elif command -v nwg-look &> /dev/null; then
        nwg-look &
    else
        notify-send -t 3000 "Appearance" "Install lxappearance for theme configuration"
    fi
}

# System update
system_update() {
    print_status "Starting system update..."
    
    if command -v kitty &> /dev/null; then
        kitty -e bash -c '
            echo "🔄 Updating system packages..."
            sudo pacman -Syu
            echo ""
            echo "✅ Update complete!"
            echo "Press any key to exit..."
            read -n1
        ' &
    else
        # Fallback to terminal
        echo "System update requires terminal access"
        sudo pacman -Syu
    fi
}

# System info
system_info() {
    print_status "Showing system information..."
    
    if [[ -f ~/scripts/hypr-systeminfo.sh ]]; then
        ~/scripts/hypr-systeminfo.sh notify
    else
        notify-send -t 5000 "System Info" "System info script not found"
    fi
}

# Night light control
night_light() {
    print_status "Controlling night light..."
    
    if [[ -f ~/scripts/hypr-sunset.sh ]]; then
        ~/scripts/hypr-sunset.sh toggle
    else
        notify-send -t 3000 "Night Light" "Night light script not found"
    fi
}

# Gaming mode
gaming_mode() {
    print_status "Toggling gaming mode..."
    
    if [[ -f ~/scripts/gaming-mode.sh ]]; then
        ~/scripts/gaming-mode.sh toggle
    else
        notify-send -t 3000 "Gaming Mode" "Gaming mode script not found"
    fi
}

# Security and privacy
security_settings() {
    print_status "Opening security settings..."
    
    if command -v firefox &> /dev/null; then
        firefox about:preferences#privacy &
    else
        notify-send -t 3000 "Security Settings" "Open browser privacy settings manually"
    fi
}

# Performance settings
performance_settings() {
    local perf_options=$(echo -e "System Monitor\nProcess Manager\nGPU Stats\nDisk Usage\nNetwork Monitor" | rofi -dmenu -p "⚡ Performance:" -theme-str 'window {width: 25%;}')
    
    case "$perf_options" in
        *System\ Monitor*)
            if command -v btop &> /dev/null; then
                kitty -e btop &
            elif command -v htop &> /dev/null; then
                kitty -e htop &
            else
                notify-send -t 3000 "System Monitor" "Install btop or htop"
            fi
            ;;
        *Process\ Manager*)
            if command -v nvidia-smi &> /dev/null; then
                kitty -e nvidia-smi &
            else
                notify-send -t 3000 "GPU Stats" "NVIDIA tools not available"
            fi
            ;;
        *GPU\ Stats*)
            if command -v nvidia-smi &> /dev/null; then
                kitty -e watch -n 1 nvidia-smi &
            else
                notify-send -t 3000 "GPU Stats" "NVIDIA tools not available"
            fi
            ;;
        *Disk\ Usage*)
            kitty -e bash -c 'df -h; echo ""; echo "Press any key to exit"; read -n1' &
            ;;
        *Network\ Monitor*)
            if command -v nethogs &> /dev/null; then
                kitty -e sudo nethogs &
            else
                kitty -e bash -c 'ip addr show; echo ""; echo "Press any key to exit"; read -n1' &
            fi
            ;;
    esac
}

# Utilities menu
utilities_menu() {
    local util_options=$(echo -e "File Manager\nTerminal\nText Editor\nCalculator\nScreenshot\nScreen Recorder\nClipboard Manager\nSystem Cleaner" | rofi -dmenu -p "🛠️ Utilities:" -theme-str 'window {width: 25%;}')
    
    case "$util_options" in
        *File\ Manager*)
            thunar ~/ &
            ;;
        *Terminal*)
            kitty &
            ;;
        *Text\ Editor*)
            nvim &
            ;;
        *Calculator*)
            if command -v gnome-calculator &> /dev/null; then
                gnome-calculator &
            else
                kitty -e bc &
            fi
            ;;
        *Screenshot*)
            ~/scripts/screenshot.sh area &
            ;;
        *Screen\ Recorder*)
            ~/scripts/screen-record.sh start &
            ;;
        *Clipboard\ Manager*)
            if command -v copyq &> /dev/null; then
                copyq &
            else
                notify-send -t 3000 "Clipboard" "Install copyq for clipboard management"
            fi
            ;;
        *System\ Cleaner*)
            if [[ -f ~/scripts/cleanup.sh ]]; then
                kitty -e ~/scripts/cleanup.sh --safe &
            else
                notify-send -t 3000 "System Cleaner" "Cleanup script not found"
            fi
            ;;
    esac
}

# Game launcher
game_launcher() {
    print_status "Opening game launcher..."
    
    if [[ -f ~/scripts/app-launcher.sh ]]; then
        ~/scripts/app-launcher.sh game
    elif command -v steam &> /dev/null; then
        steam &
    else
        notify-send -t 3000 "Game Launcher" "Game launcher not available"
    fi
}

# Screenshot tools
screenshot_tools() {
    local screenshot_options=$(echo -e "📸 Capture Area\n🖼️ Capture Window\n🖥️ Capture Screen\n⏹️ Stop Recording" | rofi -dmenu -p "📸 Screenshot:" -theme-str 'window {width: 25%;}')
    
    case "$screenshot_options" in
        *Capture\ Area*)
            ~/scripts/screenshot.sh area &
            ;;
        *Capture\ Window*)
            ~/scripts/screenshot.sh window &
            ;;
        *Capture\ Screen*)
            ~/scripts/screenshot.sh screen &
            ;;
        *Stop\ Recording*)
            ~/scripts/screen-record.sh stop &
            ;;
    esac
}

# Advanced settings
advanced_settings() {
    local advanced_options=$(echo -e "🖥️ Hyprland Config\n📊 Waybar Config\n🐚 Shell Config\n🎨 Pywal Refresh\n🔧 Service Manager\n📝 Edit Scripts" | rofi -dmenu -p "🔧 Advanced:" -theme-str 'window {width: 25%;}')
    
    case "$advanced_options" in
        *Hyprland\ Config*)
            kitty -e nvim ~/.config/hypr/hyprland.conf &
            ;;
        *Waybar\ Config*)
            kitty -e nvim ~/.config/waybar/config &
            ;;
        *Shell\ Config*)
            kitty -e nvim ~/.bashrc &
            ;;
        *Pywal\ Refresh*)
            if command -v wal &> /dev/null; then
                wal -R
                notify-send -t 2000 "Pywal" "Colorscheme refreshed"
            fi
            ;;
        *Service\ Manager*)
            kitty -e sudo systemctl status &
            ;;
        *Edit\ Scripts*)
            kitty -e nvim ~/scripts/ &
            ;;
    esac
}

# Help and about
help_about() {
    local help_options=$(echo -e "📖 Cheatsheet\n🎮 Keybinds Help\n🐛 Report Issue\n🌟 About ShouArch" | rofi -dmenu -p "❓ Help:" -theme-str 'window {width: 25%;}')
    
    case "$help_options" in
        *Cheatsheet*)
            if [[ -f ~/scripts/cheatsheet.sh ]]; then
                kitty -e ~/scripts/cheatsheet.sh &
            else
                notify-send -t 3000 "Cheatsheet" "Cheatsheet script not found"
            fi
            ;;
        *Keybinds\ Help*)
            notify-send -t 5000 "Keybinds Help" "Press Super+Q for quick settings\nPress Super+Space for app launcher\nPress Super+X for system info\nType 'cheatsheet' in terminal for full list"
            ;;
        *Report\ Issue*)
            if command -v firefox &> /dev/null; then
                firefox https://github.com/ShouShudou/shouarch/issues &
            else
                notify-send -t 3000 "Report Issue" "Open browser to GitHub issues page"
            fi
            ;;
        *About\ ShouArch*)
            notify-send -t 6000 "About ShouArch" "ShouArch Linux v1.0\n\nA custom Arch-based distribution with Hyprland WM\nDark aesthetic theme • Gaming ready • Developer friendly\n\nGitHub: https://github.com/ShouShudou/shouarch"
            ;;
    esac
}

# Main menu function
show_settings_menu() {
    local option=$(get_menu_options | rofi -dmenu -p "⚙️ ShouArch Settings:" \
        -theme-str 'window {width: 35%;}' \
        -theme-str 'listview {lines: 16;}' \
        -theme-str 'element-text {vertical-align: 0.5;}')
    
    case "$option" in
        *Audio*) audio_settings ;;
        *Display*) display_settings ;;
        *Network*) network_settings ;;
        *Appearance*) appearance_settings ;;
        *System\ Update*) system_update ;;
        *System\ Info*) system_info ;;
        *Night\ Light*) night_light ;;
        *Gaming\ Mode*) gaming_mode ;;
        *Security*) security_settings ;;
        *Performance*) performance_settings ;;
        *Utilities*) utilities_menu ;;
        *Game\ Launcher*) game_launcher ;;
        *Screenshot*) screenshot_tools ;;
        *Advanced*) advanced_settings ;;
        *Help*) help_about ;;
        *) 
            # User pressed ESC or closed menu
            print_info "Settings menu closed"
            ;;
    esac
}

# Rofi theme for quick settings
ensure_rofi_theme() {
    local theme_dir="$HOME/.config/rofi"
    mkdir -p "$theme_dir"
    
    if [[ ! -f "$theme_dir/quick-settings.rasi" ]]; then
        cat > "$theme_dir/quick-settings.rasi" << 'EOF'
@theme "shouarch-quick"

* {
    bg0: #1a1a1a;
    bg1: #2a2a2a;
    bg2: #3a3a3a;
    fg0: #ffffff;
    fg1: #cccccc;
    ac0: #ff0066;
    ac1: #00ff99;
    
    background-color: transparent;
    text-color: @fg0;
    border-color: @ac0;
}

window {
    background-color: @bg0;
    border: 2px;
    border-radius: 12px;
    padding: 20px;
    width: 35%;
}

inputbar {
    background-color: @bg1;
    border-radius: 8px;
    padding: 12px;
    margin: 0px 0px 10px 0px;
    children: [ prompt, entry ];
}

prompt {
    background-color: inherit;
    text-color: @ac0;
    padding: 0px 8px 0px 0px;
    font: "JetBrains Mono Bold 12";
}

entry {
    background-color: inherit;
    text-color: @fg0;
    font: "JetBrains Mono 12";
}

listview {
    background-color: transparent;
    lines: 16;
    scrollbar: true;
    cycle: true;
}

element {
    background-color: transparent;
    text-color: @fg1;
    padding: 8px 12px;
    border-radius: 6px;
}

element selected {
    background-color: @ac0;
    text-color: @bg0;
    border-radius: 6px;
}

element-text {
    background-color: inherit;
    text-color: inherit;
    font: "JetBrains Mono 11";
    vertical-align: 0.5;
}

element-icon {
    size: 18px;
    background-color: inherit;
    margin: 0px 8px 0px 0px;
}

message {
    background-color: @bg1;
    border-radius: 8px;
    padding: 8px;
    margin: 10px 0px 0px 0px;
    text-color: @fg1;
}

textbox {
    background-color: inherit;
    text-color: @fg1;
    font: "JetBrains Mono 10";
}
EOF
        print_info "Rofi theme created"
    fi
}

# Command line interface
case "${1:-}" in
    "audio")
        audio_settings
        ;;
    "display")
        display_settings
        ;;
    "network")
        network_settings
        ;;
    "appearance")
        appearance_settings
        ;;
    "update")
        system_update
        ;;
    "info")
        system_info
        ;;
    "nightlight")
        night_light
        ;;
    "gaming")
        gaming_mode
        ;;
    "performance")
        performance_settings
        ;;
    "screenshot")
        screenshot_tools
        ;;
    "help")
        help_about
        ;;
    "theme")
        ensure_rofi_theme
        print_status "Rofi theme ensured"
        ;;
    "version"|"-v")
        echo "ShouArch Quick Settings v1.0"
        ;;
    "help"|"-h"|"--help")
        echo "ShouArch Quick Settings Menu"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no command)  Show full settings menu"
        echo "  audio         Audio settings"
        echo "  display       Display settings"
        echo "  network       Network settings"
        echo "  appearance    Appearance settings"
        echo "  update        System update"
        echo "  info          System information"
        echo "  nightlight    Night light control"
        echo "  gaming        Gaming mode toggle"
        echo "  performance   Performance tools"
        echo "  screenshot    Screenshot tools"
        echo "  help          Help and about"
        echo "  theme         Ensure rofi theme exists"
        echo "  version       Show version"
        echo ""
        echo "Keybind: Super+Q to open quick settings"
        ;;
    *)
        check_dependencies
        ensure_rofi_theme
        show_settings_menu
        ;;
esac