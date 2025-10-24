#!/bin/bash

# ShouArch Initial Setup Script

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Setup user environment
setup_user_env() {
    print_status "Setting up user environment..."
    
    # Create user directories
    xdg-user-dirs-update
    
    # Setup dotfiles
    cp -r /etc/configs/.bashrc ~/.bashrc
    cp -r /etc/configs/hyprland.conf ~/.config/hypr/
    cp -r /etc/configs/waybar/ ~/.config/waybar/
    
    # Set proper permissions
    chmod +x ~/.config/waybar/scripts/* 2>/dev/null || true
}

# Setup themes
setup_themes() {
    print_status "Setting up themes..."
    
    # GTK Theme
    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=ShouDark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Bibata-Modern-Classic
EOF
    
    # Qt Theme
    export QT_QPA_PLATFORMTHEME=qt5ct
    mkdir -p ~/.config/qt5ct
    cat > ~/.config/qt5ct/qt5ct.conf << EOF
[Appearance]
style=gtk2
theme=ShouDark
color_scheme=/usr/share/themes/ShouDark/colors.conf
icon_theme=Papirus-Dark
font="JetBrains Mono,10,-1,5,50,0,0,0,0,0"
EOF
}

# Setup Spicetify
setup_spicetify() {
    print_status "Setting up Spicetify..."
    
    if command -v spicetify &> /dev/null; then
        spicetify backup apply
        spicetify config current_theme ShouDark
        spicetify config color_scheme dark
        spicetify apply
    else
        print_info "Spicetify not found, skipping..."
    fi
}

# Setup Pywal
setup_pywal() {
    print_status "Setting up Pywal..."
    
    # Set initial wallpaper
    if [[ -f "/etc/configs/wallpapers/default.png" ]]; then
        wal -i "/etc/configs/wallpapers/default.png" -n
    fi
    
    # Add to shell profile
    echo "cat ~/.cache/wal/sequences" >> ~/.bashrc
}

# Main setup function
main_setup() {
    print_status "Starting ShouArch setup..."
    
    setup_user_env
    setup_themes
    setup_spicetify
    setup_pywal
    
    print_status "Setup completed! Please restart your session."
}

# Check if running in live environment
if grep -q "boot=live" /proc/cmdline; then
    main_setup
else
    echo "This script should only run in live environment"
    exit 1
fi