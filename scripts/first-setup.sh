#!/bin/bash

# ShouArch First-Time Setup Wizard

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   SHOUARCH SETUP WIZARD                     ║"
    echo "║                                                              ║"
    echo "║             Let's configure your system! 🚀                ║"
    echo "║                                                              ║"
    echo "║    A custom Arch Linux experience with Hyprland WM          ║"
    echo "║             Dark aesthetic • Gaming ready • Dev friendly    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[→]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Please run as regular user (will use sudo when needed)"
        exit 1
    fi
}

# Check if this is the first run
check_first_run() {
    if [[ -f ~/.config/shouarch-setup-complete ]]; then
        print_warning "Setup has already been run on this system."
        read -p "Do you want to run it again? (y/N): " response
        if [[ ! "$response" =~ [yY] ]]; then
            print_info "Setup cancelled."
            exit 0
        fi
    fi
}

# System update
system_update() {
    print_step "Updating system packages..."
    sudo pacman -Syu --noconfirm || {
        print_warning "System update had some issues, continuing..."
    }
}

# Setup themes and appearance
setup_themes() {
    print_step "Setting up themes and appearance..."
    
    if [[ -f ~/scripts/setup-themes.sh ]]; then
        ~/scripts/setup-themes.sh
    else
        # Fallback theme setup
        print_info "Setting up fallback themes..."
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
}

# Setup wallpapers
setup_wallpapers() {
    print_step "Setting up wallpapers..."
    
    if [[ -f ~/scripts/walset.sh ]]; then
        ~/scripts/walset.sh default.jpg || {
            print_warning "Wallpaper setup had issues, continuing..."
        }
    else
        print_warning "Wallpaper script not found"
    fi
}

# Install essential software with categories
install_software() {
    print_step "Installing essential software..."
    
    # Categories for user selection
    print_info "Select software categories to install:"
    echo ""
    echo -e "  ${CYAN}1${NC} - Gaming 🎮"
    echo -e "  ${CYAN}2${NC} - Development 💻" 
    echo -e "  ${CYAN}3${NC} - Media 🎵"
    echo -e "  ${CYAN}4${NC} - Productivity 📊"
    echo -e "  ${CYAN}5${NC} - Utilities 🔧"
    echo -e "  ${CYAN}6${NC} - All of the above ✅"
    echo ""
    read -p "Enter choices (e.g., 1,3,5 or 6 for all): " choices
    
    # Convert choices to array
    IFS=',' read -ra selected_categories <<< "$choices"
    
    # Software packages by category
    declare -A software_categories=(
        ["gaming"]="steam discord lutris gamemode"
        ["development"]="code docker docker-compose nodejs npm python python-pip git"
        ["media"]="vlc obs-studio gimp inkscape audacity"
        ["productivity"]="libreoffice-fresh keepassxc thunderbird"
        ["utilities"]="htop btop neofetch ranger timeshift gparted"
    )
    
    packages_to_install=""
    
    for choice in "${selected_categories[@]}"; do
        case $choice in
            1) packages_to_install+=" ${software_categories[gaming]}" ;;
            2) packages_to_install+=" ${software_categories[development]}" ;;
            3) packages_to_install+=" ${software_categories[media]}" ;;
            4) packages_to_install+=" ${software_categories[productivity]}" ;;
            5) packages_to_install+=" ${software_categories[utilities]}" ;;
            6) 
                for category in "${!software_categories[@]}"; do
                    packages_to_install+=" ${software_categories[$category]}"
                done
                break
                ;;
        esac
    done
    
    if [[ -n "$packages_to_install" ]]; then
        print_info "Installing: $packages_to_install"
        sudo pacman -S --noconfirm $packages_to_install || {
            print_warning "Some packages failed to install, continuing..."
        }
    else
        print_warning "No software categories selected"
    fi
}

# Configure Git
configure_git() {
    print_step "Configuring Git..."
    
    if command -v git &> /dev/null; then
        # Get Git configuration interactively
        if [[ -z "$(git config --global user.name)" ]]; then
            read -p "Enter your Git name: " git_name
            if [[ -n "$git_name" ]]; then
                git config --global user.name "$git_name"
            fi
        fi
        
        if [[ -z "$(git config --global user.email)" ]]; then
            read -p "Enter your Git email: " git_email
            if [[ -n "$git_email" ]]; then
                git config --global user.email "$git_email"
            fi
        fi
        
        # Set sensible defaults
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.editor "nvim"
        
        print_success "Git configured"
        print_info "Name:  $(git config --global user.name 2>/dev/null || echo 'Not set')"
        print_info "Email: $(git config --global user.email 2>/dev/null || echo 'Not set')"
    else
        print_warning "Git not installed"
    fi
}

# Setup development environment
setup_development() {
    print_step "Setting up development environment..."
    
    if [[ -f ~/scripts/dev-setup.sh ]]; then
        read -p "Set up development environments? (Y/n): " response
        if [[ ! "$response" =~ [nN] ]]; then
            ~/scripts/dev-setup.sh || {
                print_warning "Development setup had issues"
            }
        fi
    else
        print_warning "Development setup script not found"
    fi
}

# Setup backup system
setup_backups() {
    print_step "Setting up backup system..."
    
    mkdir -p ~/.config/backup
    
    # Add backup cron job if not exists
    if ! crontab -l 2>/dev/null | grep -q "backup-configs.sh"; then
        (crontab -l 2>/dev/null; echo "0 2 * * * $HOME/scripts/backup-configs.sh") | crontab -
        print_success "Backup cron job added (runs daily at 2 AM)"
    else
        print_info "Backup cron job already exists"
    fi
    
    # Create initial backup
    if [[ -f ~/scripts/backup-configs.sh ]]; then
        ~/scripts/backup-configs.sh || {
            print_warning "Initial backup had issues"
        }
    fi
}

# Configure system services
setup_services() {
    print_step "Configuring system services..."
    
    local services=("docker" "bluetooth" "cronie" "ssh")
    
    for service in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            sudo systemctl enable "$service" 2>/dev/null && print_info "Enabled $service" || print_warning "Failed to enable $service"
        fi
    done
}

# Setup user directories and structure
setup_directories() {
    print_step "Creating user directory structure..."
    
    local directories=(
        "~/Development"
        "~/Development/projects"
        "~/Development/learning" 
        "~/Documents/Notes"
        "~/Pictures/Screenshots"
        "~/Videos/Recordings"
        "~/Music/Playlists"
        "~/.local/bin"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "${dir/#\~/$HOME}"
    done
    
    # Add local bin to PATH if not already
    if ! grep -q "\.local/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        print_info "Added ~/.local/bin to PATH"
    fi
}

# Test key features
test_features() {
    print_step "Testing key features..."
    
    local tests=(
        "Hyprland:hyprctl version"
        "Spotify:playerctl --version"
        "Terminal:kitty --version"
        "File Manager:thunar --version"
    )
    
    for test in "${tests[@]}"; do
        IFS=':' read -r feature command <<< "$test"
        if eval "$command" &>/dev/null; then
            print_success "$feature: Working"
        else
            print_warning "$feature: Not working"
        fi
    done
}

# Show final instructions
show_final_instructions() {
    print_success "Setup completed! 🎉"
    echo ""
    echo -e "${CYAN}🎯 NEXT STEPS:${NC}"
    echo ""
    echo -e "  ${GREEN}1. Restart your system${NC} to apply all changes"
    echo -e "  ${GREEN}2. Explore your new ShouArch system:${NC}"
    echo -e "     • Press ${YELLOW}Super + Space${NC} for app launcher"
    echo -e "     • Press ${YELLOW}Super + X${NC} for system info"  
    echo -e "     • Press ${YELLOW}Super + Q${NC} for quick settings"
    echo -e "     • Type ${YELLOW}cheatsheet${NC} for keybinds reference"
    echo ""
    echo -e "  ${GREEN}3. Customize your setup:${NC}"
    echo -e "     • Edit ${YELLOW}~/.config/hypr/hyprland.conf${NC} for WM settings"
    echo -e "     • Use ${YELLOW}~/scripts/walset.sh${NC} to change wallpapers"
    echo -e "     • Run ${YELLOW}~/scripts/dev-setup.sh${NC} for more dev tools"
    echo ""
    echo -e "  ${GREEN}4. Get help:${NC}"
    echo -e "     • Check ${YELLOW}~/.bashrc${NC} for aliases and shortcuts"
    echo -e "     • Use ${YELLOW}cheatsheet${NC} command anytime"
    echo -e "     • Visit GitHub repo for documentation"
    echo ""
    echo -e "${MAGENTA}Welcome to ShouArch! Happy computing! 🚀${NC}"
}

# Mark setup as complete
mark_complete() {
    mkdir -p ~/.config
    touch ~/.config/shouarch-setup-complete
    echo "ShouArch setup completed: $(date)" >> ~/.config/shouarch-setup-complete
}

# Main setup function
main_setup() {
    print_header
    check_root
    check_first_run
    
    echo -e "${YELLOW}This will configure your ShouArch system.${NC}"
    echo -e "${YELLOW}It may take 10-30 minutes depending on your internet speed.${NC}"
    echo ""
    read -p "Continue with setup? (Y/n): " response
    
    if [[ "$response" =~ [nN] ]]; then
        print_info "Setup cancelled."
        exit 0
    fi
    
    # Start setup process
    system_update
    setup_directories
    setup_themes
    setup_wallpapers
    install_software
    configure_git
    setup_development
    setup_services
    setup_backups
    test_features
    mark_complete
    
    show_final_instructions
}

# Handle command line arguments
case "${1:-}" in
    "minimal")
        # Minimal setup for testing
        setup_themes
        setup_wallpapers
        configure_git
        mark_complete
        print_success "Minimal setup completed"
        ;;
    "reset")
        # Reset setup marker
        rm -f ~/.config/shouarch-setup-complete
        print_success "Setup marker reset. Run without arguments for full setup."
        ;;
    "status")
        # Show setup status
        if [[ -f ~/.config/shouarch-setup-complete ]]; then
            print_success "Setup completed on: $(cat ~/.config/shouarch-setup-complete)"
        else
            print_warning "Setup has not been run yet."
        fi
        ;;
    "help"|"-h"|"--help")
        echo "ShouArch First-Time Setup Wizard"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no option)  Run full interactive setup"
        echo "  minimal       Run minimal setup (themes + git)"
        echo "  reset         Reset setup completion marker"
        echo "  status        Show setup status"
        echo "  help          Show this help"
        ;;
    *)
        main_setup
        ;;
esac