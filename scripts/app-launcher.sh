#!/bin/bash

# ShouArch Categorized App Launcher

# App database - mudah untuk ditambah/modify
declare -A APPS=(
    # Web Browsers
    ["🌐 Firefox"]="firefox"
    ["🌐 Chrome"]="google-chrome-stable"
    ["🌐 Edge"]="microsoft-edge-stable"
    ["🌐 Brave"]="brave"
    ["🌐 Thorium"]="thorium-browser"

    # Development
    ["💻 VS Code"]="code"
    ["💻 VS Codium"]="codium"
    ["💻 NeoVim"]="nvim"
    ["💻 Kitty"]="kitty"
    ["💻 WezTerm"]="wezterm"
    ["💻 GitHub Desktop"]="github-desktop"
    ["💻 GitKraken"]="gitkraken"
    ["💻 Intellij IDEA"]="idea"
    ["💻 PyCharm"]="pycharm"
    ["💻 WebStorm"]="webstorm"

    # File Management
    ["📁 Thunar"]="thunar"
    ["📁 Nautilus"]="nautilus"
    ["📁 Nemo"]="nemo"
    ["📁 Ranger"]="kitty -e ranger"
    ["📁 Double Commander"]="doublecmd"

    # Communication
    ["💬 Discord"]="discord"
    ["💬 Telegram"]="telegram-desktop"
    ["💬 Slack"]="slack"
    ["💬 Element"]="element-desktop"
    ["💬 Thunderbird"]="thunderbird"

    # Media
    ["🎵 Spotify"]="spotify"
    ["🎵 VLC"]="vlc"
    ["🎵 MPV"]="mpv"
    ["🎵 OBS Studio"]="obs"
    ["🎵 Kdenlive"]="kdenlive"
    ["🎵 GIMP"]="gimp"
    ["🎵 Inkscape"]="inkscape"
    ["🎵 Blender"]="blender"
    ["🎵 Audacity"]="audacity"

    # Gaming
    ["🎮 Steam"]="steam"
    ["🎮 Lutris"]="lutris"
    ["🎮 Bottles"]="bottles"
    ["🎮 Heroic"]="heroic"
    ["🎮 Minecraft"]="minecraft-launcher"

    # Utilities
    ["🔧 System Monitor"]="gnome-system-monitor"
    ["🔧 GParted"]="gparted"
    ["🔧 Timeshift"]="timeshift"
    ["🔧 KeePassXC"]="keepassxc"
    ["🔧 Bitwarden"]="bitwarden"
    ["🔧 LibreOffice"]="libreoffice"
    ["🔧 Calculator"]="gnome-calculator"

    # Settings
    ["⚙️ System Settings"]="gnome-control-center"
    ["⚙️ Network Manager"]="nm-connection-editor"
    ["⚙️ Bluetooth"]="blueman-manager"
    ["⚙️ Audio Control"]="pavucontrol"
    ["⚙️ Display Settings"]="arandr"
)

# Category-based app lists
get_apps_by_category() {
    case "$1" in
        "web")
            echo -e "🌐 Firefox\n🌐 Chrome\n🌐 Edge\n🌐 Brave\n🌐 Thorium"
            ;;
        "dev")
            echo -e "💻 VS Code\n💻 VS Codium\n💻 NeoVim\n💻 Kitty\n💻 WezTerm\n💻 GitHub Desktop\n💻 GitKraken"
            ;;
        "media")
            echo -e "🎵 Spotify\n🎵 VLC\n🎵 MPV\n🎵 OBS Studio\n🎵 Kdenlive\n🎵 GIMP\n🎵 Inkscape\n🎵 Blender"
            ;;
        "game")
            echo -e "🎮 Steam\n🎮 Lutris\n🎮 Bottles\n🎮 Heroic\n🎮 Minecraft"
            ;;
        "utils")
            echo -e "📁 Thunar\n📁 Nautilus\n🔧 System Monitor\n🔧 GParted\n🔧 Timeshift\n🔧 KeePassXC\n🔧 Bitwarden"
            ;;
        "comms")
            echo -e "💬 Discord\n💬 Telegram\n💬 Slack\n💬 Element\n💬 Thunderbird"
            ;;
        "settings")
            echo -e "⚙️ System Settings\n⚙️ Network Manager\n⚙️ Bluetooth\n⚙️ Audio Control\n⚙️ Display Settings"
            ;;
        *)
            # Return all apps sorted by category
            {
                echo "🌐 WEB BROWSERS"
                echo "🌐 Firefox"
                echo "🌐 Chrome" 
                echo "🌐 Edge"
                echo "🌐 Brave"
                echo "🌐 Thorium"
                echo ""
                echo "💻 DEVELOPMENT"
                echo "💻 VS Code"
                echo "💻 VS Codium"
                echo "💻 NeoVim"
                echo "💻 Kitty"
                echo "💻 WezTerm"
                echo "💻 GitHub Desktop"
                echo ""
                echo "📁 FILE MANAGERS"
                echo "📁 Thunar"
                echo "📁 Nautilus"
                echo "📁 Nemo"
                echo ""
                echo "💬 COMMUNICATION"
                echo "💬 Discord"
                echo "💬 Telegram"
                echo "💬 Slack"
                echo "💬 Element"
                echo ""
                echo "🎵 MEDIA & CREATIVE"
                echo "🎵 Spotify"
                echo "🎵 VLC"
                echo "🎵 MPV"
                echo "🎵 OBS Studio"
                echo "🎵 GIMP"
                echo "🎵 Inkscape"
                echo ""
                echo "🎮 GAMING"
                echo "🎮 Steam"
                echo "🎮 Lutris"
                echo "🎮 Bottles"
                echo "🎮 Heroic"
                echo ""
                echo "🔧 UTILITIES"
                echo "🔧 System Monitor"
                echo "🔧 GParted"
                echo "🔧 Timeshift"
                echo "🔧 KeePassXC"
                echo "🔧 Bitwarden"
                echo ""
                echo "⚙️ SETTINGS"
                echo "⚙️ System Settings"
                echo "⚙️ Network Manager"
                echo "⚙️ Bluetooth"
                echo "⚙️ Audio Control"
            }
            ;;
    esac
}

launch_app() {
    local app_name="$1"
    local app_command="${APPS[$app_name]}"
    
    if [[ -n "$app_command" ]]; then
        echo "🚀 Launching: $app_name"
        
        # Check if app exists
        if command -v $(echo "$app_command" | awk '{print $1}') &> /dev/null; then
            # Launch in background and disown
            eval "$app_command" & disown
            sleep 0.5
        else
            # Fallback: try to launch via desktop file
            local app_basename=$(echo "$app_command" | awk '{print $1}')
            if command -v gtk-launch &> /dev/null; then
                gtk-launch "$app_basename.desktop" & disown
            else
                notify-send -t 3000 "App Launcher" "❌ $app_name is not installed"
                echo "❌ $app_name is not installed"
            fi
        fi
    else
        notify-send -t 3000 "App Launcher" "❌ Unknown application: $app_name"
        echo "❌ Unknown application: $app_name"
    fi
}

show_main_menu() {
    local selected=$(get_apps_by_category "all" | rofi -dmenu -p "🚀 ShouArch Launcher:" \
        -mesg "Type to filter or use categories: web, dev, media, game, utils, comms, settings" \
        -theme-str 'window {width: 55%;}' \
        -theme-str 'listview {lines: 20;}' \
        -theme-str 'element-text {vertical-align: 0.5;}')
    
    # Handle category headers (non-selectable)
    if [[ -n "$selected" ]] && [[ ! "$selected" =~ ^(🌐 WEB|💻 DEV|📁 FILE|💬 COMM|🎵 MEDIA|🎮 GAMING|🔧 UTIL|⚙️ SETT) ]]; then
        launch_app "$selected"
    fi
}

show_category_menu() {
    local category="$1"
    local apps_list=$(get_apps_by_category "$category")
    
    local selected=$(echo -e "$apps_list" | rofi -dmenu -p "🚀 $category:" \
        -theme-str 'window {width: 45%;}' \
        -theme-str 'listview {lines: 15;}')
    
    if [[ -n "$selected" ]]; then
        launch_app "$selected"
    fi
}

# Handle command line arguments
case "${1:-}" in
    "web")
        show_category_menu "web"
        ;;
    "dev")
        show_category_menu "dev"
        ;;
    "media")
        show_category_menu "media"
        ;;
    "game")
        show_category_menu "game"
        ;;
    "utils")
        show_category_menu "utils"
        ;;
    "comms")
        show_category_menu "comms"
        ;;
    "settings")
        show_category_menu "settings"
        ;;
    "list")
        # Show all available apps
        for app in "${!APPS[@]}"; do
            echo "$app: ${APPS[$app]}"
        done | sort
        ;;
    "test")
        # Test if apps are installed
        for app in "${!APPS[@]}"; do
            app_cmd=$(echo "${APPS[$app]}" | awk '{print $1}')
            if command -v "$app_cmd" &> /dev/null; then
                echo "✅ $app"
            else
                echo "❌ $app"
            fi
        done
        ;;
    *)
        show_main_menu
        ;;
esac