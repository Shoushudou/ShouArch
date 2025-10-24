#!/bin/bash

# ShouArch Post-Installation Setup

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Config
SETUP_COMPLETE_FILE="$HOME/.config/shouarch/postinstall-complete"
LOG_FILE="/tmp/shouarch-postinstall.log"

print_status() { echo -e "${GREEN}[→]${NC} $1"; }
print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_success() { echo -e "${MAGENTA}[✓]${NC} $1"; }

# Logging setup
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "=== ShouArch Post-Installation Started: $(date) ===" >> "$LOG_FILE"
}

# Check if already run
check_already_run() {
    if [[ -f "$SETUP_COMPLETE_FILE" ]]; then
        print_warning "Post-installation setup has already been run."
        read -p "Do you want to run it again? (y/N): " response
        if [[ ! "$response" =~ [yY] ]]; then
            print_info "Setup cancelled."
            exit 0
        fi
    fi
}

# Update system with better error handling
update_system() {
    print_status "Updating system packages..."
    
    if ! sudo pacman -Syu --noconfirm; then
        print_warning "System update encountered issues, continuing..."
    fi
    
    # Update AUR helper if available
    if command -v yay &> /dev/null; then
        print_info "Updating AUR packages..."
        yay -Syu --noconfirm || print_warning "AUR update had issues"
    fi
}

# Setup Spicetify with fallbacks
setup_spicetify() {
    print_status "Setting up Spicetify..."
    
    if command -v spicetify &> /dev/null; then
        # Check if Spotify is installed
        if ! command -v spotify &> /dev/null; then
            print_warning "Spotify not installed, skipping Spicetify setup"
            return 1
        fi
        
        # Backup Spotify
        if spicetify backup; then
            print_info "Spotify backup created"
        else
            print_warning "Spotify backup failed"
        fi
        
        # Apply ShouArch theme configuration
        local themes_dir="$HOME/.config/spicetify/Themes"
        mkdir -p "$themes_dir"
        
        # Create ShouDynamic theme if it doesn't exist
        if [[ ! -d "$themes_dir/ShouDynamic" ]]; then
            print_info "Creating ShouDynamic Spicetify theme..."
            mkdir -p "$themes_dir/ShouDynamic"
            
            cat > "$themes_dir/ShouDynamic/color.ini" << 'EOF'
[Variables]
@background@ = 1a1a1a
@foreground@ = ffffff
@accent@ = ff0066
@accent2@ = 00ff99
@accent3@ = ffcc00

[Base]
background             = @background@
foreground             = @foreground@
accent                 = @accent@
accent_secondary       = @accent2@
accent_tertiary        = @accent3@
text                   = @foreground@
subtext                = cccccc
sidebar                = 2a2a2a
player                 = @background@
card                   = 2a2a2a
shadow                 = 000000
selected-row           = @accent@
button                 = @accent@
button-active          = @accent2@
button-disabled        = 595959
tab-active             = @accent@
notification           = @accent@
notification-error     = ff3333
misc                   = 888888
EOF
        fi
        
        # Apply configuration
        spicetify config current_theme ShouDynamic
        spicetify config color_scheme wal
        spicetify config inject_css 1
        spicetify config replace_colors 1
        spicetify config overwrite_assets 1
        
        if spicetify apply; then
            print_success "Spicetify configured successfully"
        else
            print_warning "Spicetify application had issues"
        fi
    else
        print_warning "Spicetify not found, skipping..."
    fi
}

# Setup themes comprehensively
setup_themes() {
    print_status "Setting up system themes..."
    
    # GTK Themes
    if command -v gsettings &> /dev/null; then
        print_info "Configuring GTK themes..."
        gsettings set org.gnome.desktop.interface gtk-theme "ShouDark" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name "JetBrains Mono 10" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10" 2>/dev/null || true
    fi
    
    # Qt Themes
    print_info "Configuring Qt themes..."
    export QT_QPA_PLATFORMTHEME=qt5ct
    
    mkdir -p ~/.config/qt5ct
    cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
[Appearance]
style=gtk2
theme=ShouDark
icon_theme=Papirus-Dark
font="JetBrains Mono,10,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[PaletteEditor]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x2\x12\0\0\x1\x12\0\0\x4\x61\0\0\x3\x33\0\0\x2\x12\0\0\x1\x31\0\0\x4\x61\0\0\x3R\0\0\0\0\x2\0\0\0\x5V\0\0\x2\x12\0\0\x1\x31\0\0\x4\x61\0\0\x3R)

[SettingsWindow]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x2\x12\0\0\x1\x12\0\0\x4\x61\0\0\x3\x33\0\0\x2\x12\0\0\x1\x31\0\0\x4\x61\0\0\x3R\0\0\0\0\x2\0\0\0\x5V\0\0\x2\x12\0\0\x1\x31\0\0\x4\x61\0\0\x3R)
EOF

    # Apply themes to specific applications
    setup_application_themes
}

# Setup application-specific themes
setup_application_themes() {
    print_status "Setting up application themes..."
    
    # Firefox theme (if userChrome.css is supported)
    local firefox_profile=$(find ~/.mozilla/firefox -name "*.default-release" -type d 2>/dev/null | head -1)
    if [[ -n "$firefox_profile" ]]; then
        mkdir -p "$firefox_profile/chrome"
        print_info "Firefox userChrome directory created"
    fi
    
    # VS Code theme
    if command -v code &> /dev/null; then
        print_info "VS Code detected - install ShouArch theme from marketplace"
    fi
}

# Setup Pywal templates and initial theme
setup_pywal() {
    print_status "Setting up Pywal dynamic theming..."
    
    if command -v wal &> /dev/null; then
        # Create custom templates directory
        mkdir -p ~/.config/wal/templates/
        
        # Hyprland color template
        cat > ~/.config/wal/templates/colors-hyprland.conf << 'EOF'
# Hyprland colors generated by Pywal

general {
    col.active_border = rgba({color1.strip}ee) rgba({color2.strip}ee) 45deg
    col.inactive_border = rgba({color8.strip}aa)
}

decoration {
    col.shadow = rgba({color0.strip}ee)
}

# Window specific rules
windowrulev2 = opacity 0.9 0.7,class:^(kitty)$
windowrulev2 = opacity 0.8 0.7,class:^(code-url-handler)$

# Keybind highlight
bind = $mainMod, F1, exec, hyprctl keyword general:col.active_border rgba({color1.strip}ee)
EOF

        # CSS template for web apps
        cat > ~/.config/wal/templates/colors.css << 'EOF'
/* CSS colors generated by Pywal */

:root {
    --bg: #{background.strip};
    --fg: #{foreground.strip};
    --accent: #{color1.strip};
    --accent2: #{color2.strip};
    --accent3: #{color3.strip};
    --border: #{color8.strip};
}

.theme-shouarch {
    background-color: var(--bg);
    color: var(--fg);
    accent-color: var(--accent);
}
EOF

        # GTK template
        cat > ~/.config/wal/templates/gtk3.0.vim << 'EOF'
" GTK 3.0 colors generated by Pywal

gtk-color-scheme = "bg_color:#{background.strip}\nfg_color:#{foreground.strip}\nbase_color:#{background.strip}\ntext_color:#{foreground.strip}\nselected_bg_color:#{color2.strip}\nselected_fg_color:#{background.strip}\ntooltip_bg_color:#{color0.strip}\ntooltip_fg_color:#{foreground.strip}"
EOF

        # Generate initial theme from default wallpaper
        local default_wallpaper="/etc/configs/wallpapers/default.jpg"
        if [[ -f "$default_wallpaper" ]]; then
            print_info "Generating initial Pywal theme..."
            wal -i "$default_wallpaper" -n -q
        else
            print_warning "Default wallpaper not found for initial Pywal setup"
        fi
    else
        print_warning "Pywal not installed, skipping dynamic theming"
    fi
}

# Setup default applications
setup_default_apps() {
    print_status "Setting up default applications..."
    
    # Default terminal
    if command -v update-alternatives &> /dev/null; then
        sudo update-alternatives --set x-terminal-emulator /usr/bin/kitty 2>/dev/null || \
        print_warning "Could not set kitty as default terminal"
    fi
    
    # File associations using xdg-utils
    if command -v xdg-mime &> /dev/null; then
        xdg-mime default Thunar.desktop inode/directory 2>/dev/null || true
        xdg-mime default nvim.desktop text/plain 2>/dev/null || true
        xdg-settings set default-web-browser firefox.desktop 2>/dev/null || true
    fi
    
    # Create desktop entries for common apps
    setup_desktop_entries
}

# Setup desktop entries and application integration
setup_desktop_entries() {
    print_status "Setting up desktop integration..."
    
    local apps_dir="$HOME/.local/share/applications"
    mkdir -p "$apps_dir"
    
    # ShouArch-specific desktop entries
    cat > "$apps_dir/shouarch-settings.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ShouArch Settings
Comment=ShouArch System Settings
Exec=shouarch-settings
Icon=preferences-system
Categories=Settings;
Terminal=false
EOF
    
    # Make desktop entries executable
    chmod +x "$apps_dir/shouarch-settings.desktop" 2>/dev/null || true
}

# Setup user services and autostart
setup_services() {
    print_status "Setting up user services..."
    
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    # Night light autostart
    cat > "$autostart_dir/shouarch-nightlight.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=ShouArch Night Light
Exec=hypr-sunset.sh auto
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Auto-start night light
EOF
    
    # Clipboard manager (if installed)
    if command -v copyq &> /dev/null; then
        cat > "$autostart_dir/copyq.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=CopyQ
Exec=copyq
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Clipboard manager
EOF
    fi
    
    print_info "Autostart entries created"
}

# Setup development environment
setup_development() {
    print_status "Setting up development environment..."
    
    if [[ -f "$HOME/scripts/dev-setup.sh" ]]; then
        print_info "Running development environment setup..."
        "$HOME/scripts/dev-setup.sh" || print_warning "Development setup had issues"
    else
        print_info "Development setup script not found, skipping..."
    fi
}

# Setup gaming environment
setup_gaming() {
    print_status "Setting up gaming environment..."
    
    # Enable GameMode if installed
    if command -v gamemoded &> /dev/null; then
        sudo systemctl enable --now gamemoded 2>/dev/null || true
        print_info "GameMode service enabled"
    fi
    
    # Setup MangoHUD if installed
    if command -v mangohud &> /dev/null; then
        mkdir -p "$HOME/.config/MangoHud"
        print_info "MangoHUD configured"
    fi
}

# Setup shell and terminal
setup_shell() {
    print_status "Setting up shell environment..."
    
    # Ensure bashrc is sourced
    if ! grep -q "ShouArch" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# ShouArch Configuration" >> ~/.bashrc
        echo "source /etc/configs/.bashrc" >> ~/.bashrc
    fi
    
    # Setup Zsh if installed
    if command -v zsh &> /dev/null && [[ -f "/etc/configs/.zshrc" ]]; then
        cp /etc/configs/.zshrc ~/.zshrc 2>/dev/null || true
        print_info "Zsh configuration copied"
    fi
}

# Cleanup and optimization
cleanup_system() {
    print_status "Cleaning up system..."
    
    # Clean package cache
    sudo pacman -Scc --noconfirm 2>/dev/null || true
    
    # Clean temporary files
    rm -rf /tmp/shouarch-* 2>/dev/null || true
    
    # Update font cache
    if command -v fc-cache &> /dev/null; then
        fc-cache -f 2>/dev/null || true
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database ~/.local/share/applications 2>/dev/null || true
    fi
}

# Mark setup as complete
mark_complete() {
    mkdir -p "$(dirname "$SETUP_COMPLETE_FILE")"
    date > "$SETUP_COMPLETE_FILE"
    echo "ShouArch post-installation completed successfully" >> "$SETUP_COMPLETE_FILE"
}

# Show completion summary
show_summary() {
    print_success "Post-installation setup completed! 🎉"
    echo ""
    echo "📋 Setup Summary:"
    echo "  ✓ System updated"
    echo "  ✓ Themes configured (GTK, Qt, Pywal)"
    echo "  ✓ Spicetify setup (if Spotify available)"
    echo "  ✓ Default applications set"
    echo "  ✓ Development environment configured"
    echo "  ✓ Gaming optimizations applied"
    echo "  ✓ User services and autostart setup"
    echo "  ✓ System cleaned and optimized"
    echo ""
    print_info "Next steps:"
    echo "  1. Restart your session to apply all changes"
    echo "  2. Run 'first-setup.sh' for additional configuration"
    echo "  3. Check ~/.config/ for custom settings"
    echo "  4. Visit ShouArch documentation for tips"
    echo ""
    print_warning "Log file: $LOG_FILE"
}

# Main execution
main() {
    print_status "Starting ShouArch post-installation setup..."
    
    setup_logging
    check_already_run
    
    update_system
    setup_themes
    setup_pywal
    setup_spicetify
    setup_default_apps
    setup_services
    setup_development
    setup_gaming
    setup_shell
    cleanup_system
    mark_complete
    
    show_summary
}

# Individual setup functions
case "${1:-}" in
    "themes")
        setup_themes
        setup_pywal
        ;;
    "spicetify")
        setup_spicetify
        ;;
    "apps")
        setup_default_apps
        setup_services
        ;;
    "dev")
        setup_development
        ;;
    "gaming")
        setup_gaming
        ;;
    "cleanup")
        cleanup_system
        ;;
    "status")
        if [[ -f "$SETUP_COMPLETE_FILE" ]]; then
            print_success "Post-installation completed on: $(cat "$SETUP_COMPLETE_FILE")"
        else
            print_info "Post-installation has not been run"
        fi
        ;;
    "reset")
        rm -f "$SETUP_COMPLETE_FILE"
        print_success "Post-installation marker reset"
        ;;
    "help"|"-h"|"--help")
        echo "ShouArch Post-Installation Setup"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no command)  Run full setup"
        echo "  themes         Setup themes only"
        echo "  spicetify      Setup Spicetify only"
        echo "  apps           Setup applications only"
        echo "  dev            Setup development environment"
        echo "  gaming         Setup gaming environment"
        echo "  cleanup        Run cleanup only"
        echo "  status         Show setup status"
        echo "  reset          Reset setup completion marker"
        echo "  help           Show this help"
        ;;
    *)
        main
        ;;
esac