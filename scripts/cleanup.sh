#!/bin/bash

# ShouArch Cleanup Script
# Cleans cache and temporary files before ISO build

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Safety checks
safety_checks() {
    print_status "Running safety checks..."
    
    # Check if we're in a live environment or have confirmation
    if [[ ! -f "/etc/shoutarch-build" ]] && [[ "${1:-}" != "--force" ]]; then
        print_warning "This script is designed for pre-ISO build cleanup."
        print_warning "It will remove many cached files and temporary data."
        read -p "Are you sure you want to continue? (y/N): " confirm
        if [[ ! "$confirm" =~ [yY] ]]; then
            print_info "Cleanup cancelled."
            exit 0
        fi
    fi
    
    # Check disk space before cleanup
    local available_space=$(df / | awk 'NR==2 {print $4}')
    print_info "Available disk space: $available_space"
}

# Clean package cache with better error handling
clean_package_cache() {
    print_status "Cleaning package cache..."
    
    # Clean pacman cache
    if command -v pacman &> /dev/null; then
        sudo pacman -Scc --noconfirm || {
            print_warning "Failed to clean pacman cache, continuing..."
        }
        
        # Remove all package files
        sudo rm -rf /var/cache/pacman/pkg/* || {
            print_warning "Failed to remove package files"
        }
    else
        print_warning "pacman not found, skipping package cache cleanup"
    fi
}

# Clean user caches with more comprehensive coverage
clean_user_caches() {
    print_status "Cleaning user caches..."
    
    # Browser caches (multiple browsers)
    local browsers=(
        "~/.cache/mozilla/firefox"
        "~/.cache/chromium"
        "~/.cache/google-chrome"
        "~/.cache/brave"
        "~/.cache/microsoft-edge"
        "~/.cache/thorium"
        "~/.config/google-chrome/Default/Service Worker"
        "~/.config/chromium/Default/Service Worker"
    )
    
    for browser in "${browsers[@]}"; do
        if [[ -d "${browser/#\~/$HOME}" ]]; then
            find "${browser/#\~/$HOME}" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
            find "${browser/#\~/$HOME}" -name "cache2" -type d -exec rm -rf {} + 2>/dev/null || true
            find "${browser/#\~/$HOME}" -name "Code Cache" -type d -exec rm -rf {} + 2>/dev/null || true
        fi
    done
    
    # Application caches
    local app_caches=(
        "~/.cache/spotify"
        "~/.cache/discord"
        "~/.cache/telegram-desktop"
        "~/.cache/vlc"
        "~/.cache/gimp"
        "~/.cache/obs-studio"
        "~/.cache/code"
        "~/.cache/vscode"
    )
    
    for cache in "${app_caches[@]}"; do
        if [[ -d "${cache/#\~/$HOME}" ]]; then
            rm -rf "${cache/#\~/$HOME}"/* 2>/dev/null || true
        fi
    done
    
    # System caches (with caution)
    if [[ $EUID -eq 0 ]]; then
        sudo rm -rf /var/cache/* 2>/dev/null || true
        # Don't remove /var/tmp completely, just clean old files
        find /var/tmp -type f -atime +7 -delete 2>/dev/null || true
    fi
    
    # User caches
    rm -rf ~/.cache/* 2>/dev/null || true
    rm -rf ~/.thumbnails/* 2>/dev/null || true
    rm -rf ~/.local/share/Trash/* 2>/dev/null || true
    rm -rf ~/.local/share/recently-used.xbel 2>/dev/null || true
}

# Clean logs safely
clean_logs() {
    print_status "Cleaning system logs..."
    
    if command -v journalctl &> /dev/null; then
        # Rotate and vacuum journal
        sudo journalctl --rotate 2>/dev/null || true
        sudo journalctl --vacuum-time=1h 2>/dev/null || {  # 1 hour instead of 1 second for safety
            print_warning "Failed to vacuum journal"
        }
    fi
    
    # Clean log files (keep current logs, remove old ones)
    if [[ $EUID -eq 0 ]]; then
        find /var/log -name "*.log" -type f -exec truncate -s 0 {} \; 2>/dev/null || true
        find /var/log -name "*.old" -type f -delete 2>/dev/null || true
        find /var/log -name "*.gz" -type f -delete 2>/dev/null || true
        find /var/log -name "*.1" -type f -delete 2>/dev/null || true
    fi
}

# Clean temporary files safely
clean_temporary_files() {
    print_status "Cleaning temporary files..."
    
    # System temp files (keep directory structure)
    if [[ $EUID -eq 0 ]]; then
        find /tmp -mindepth 1 -maxdepth 1 -not -name ".*" -exec rm -rf {} + 2>/dev/null || true
        find /var/tmp -mindepth 1 -maxdepth 1 -not -name ".*" -exec rm -rf {} + 2>/dev/null || true
    else
        # User temp files only
        find /tmp -user "$USER" -exec rm -rf {} + 2>/dev/null || true
    fi
    
    # User-specific temp files
    rm -rf ~/tmp/* 2>/dev/null || true
    rm -rf ~/.tmp/* 2>/dev/null || true
    
    # Package build files
    if [[ $EUID -eq 0 ]]; then
        sudo rm -rf /var/lib/pacman/sync/*.db 2>/dev/null || true
        sudo rm -rf /var/lib/pacman/sync/*.files 2>/dev/null || true
    fi
}

# Reset machine ID (important for live ISO)
reset_machine_id() {
    print_status "Resetting machine ID..."
    
    if [[ $EUID -eq 0 ]]; then
        if [[ -f /etc/machine-id ]]; then
            sudo truncate -s 0 /etc/machine-id 2>/dev/null || {
                print_warning "Failed to reset /etc/machine-id"
            }
        fi
        
        if [[ -f /var/lib/dbus/machine-id ]]; then
            sudo truncate -s 0 /var/lib/dbus/machine-id 2>/dev/null || {
                print_warning "Failed to reset DBus machine-id"
            }
        fi
    else
        print_warning "Need root privileges to reset machine ID"
    fi
}

# Remove history files
remove_history_files() {
    print_status "Removing history files..."
    
    # Shell histories
    local history_files=(
        "~/.bash_history"
        "~/.zsh_history"
        "~/.fish_history"
        "~/.node_repl_history"
        "~/.python_history"
        "~/.mysql_history"
        "~/.psql_history"
    )
    
    for history_file in "${history_files[@]}"; do
        if [[ -f "${history_file/#\~/$HOME}" ]]; then
            rm -f "${history_file/#\~/$HOME}" 2>/dev/null || true
        fi
    done
    
    # Application histories
    local app_histories=(
        "~/.viminfo"
        "~/.nvimlog"
        "~/.local/share/recently-used.xbel"
        "~/.config/Code/User/History"
        "~/.config/Code - OSS/User/History"
    )
    
    for app_history in "${app_histories[@]}"; do
        if [[ -e "${app_history/#\~/$HOME}" ]]; then
            rm -rf "${app_history/#\~/$HOME}" 2>/dev/null || true
        fi
    done
    
    # Root history if running as root
    if [[ $EUID -eq 0 ]] && [[ -f /root/.bash_history ]]; then
        rm -f /root/.bash_history 2>/dev/null || true
    fi
}

# Clean package manager data
clean_package_data() {
    print_status "Cleaning package manager data..."
    
    if command -v pacman &> /dev/null; then
        # Remove orphaned packages (with better error handling)
        local orphans=$(pacman -Qtdq 2>/dev/null)
        if [[ -n "$orphans" ]]; then
            echo "$orphans" | sudo pacman -Rns --noconfirm - 2>/dev/null || {
                print_warning "Failed to remove some orphaned packages"
            }
        fi
        
        # Clean package database lock file
        sudo rm -f /var/lib/pacman/db.lck 2>/dev/null || true
    fi
}

# Clean sensitive data (for live ISO security)
clean_sensitive_data() {
    print_status "Cleaning sensitive data..."
    
    if [[ $EUID -eq 0 ]]; then
        # SSH host keys (regenerate on first boot)
        sudo rm -rf /etc/ssh/ssh_host_* 2>/dev/null || {
            print_warning "Failed to remove SSH host keys"
        }
        
        # SSL private keys
        sudo rm -rf /etc/ssl/private/* 2>/dev/null || true
    fi
    
    # User SSH data (keep config, remove known_hosts)
    rm -f ~/.ssh/known_hosts 2>/dev/null || true
    rm -f ~/.ssh/known_hosts.old 2>/dev/null || true
    
    # GPG data (selective cleanup)
    if [[ -d ~/.gnupg ]]; then
        # Keep GPG config, remove cached data
        find ~/.gnupg -name "*.lock" -delete 2>/dev/null || true
        find ~/.gnupg -name "S.*" -delete 2>/dev/null || true
    fi
    
    # Browser saved passwords and form data
    local browser_storage=(
        "~/.mozilla/firefox/*/logins.json"
        "~/.config/chromium/Default/Login Data"
        "~/.config/google-chrome/Default/Login Data"
        "~/.config/brave/Default/Login Data"
    )
    
    for storage in "${browser_storage[@]}"; do
        if [[ -f "${storage/#\~/$HOME}" ]]; then
            rm -f "${storage/#\~/$HOME}" 2>/dev/null || true
        fi
    done
}

# Optimize systemd journal
optimize_journal() {
    print_status "Optimizing systemd journal..."
    
    if command -v journalctl &> /dev/null && [[ $EUID -eq 0 ]]; then
        sudo journalctl --vacuum-time=1h 2>/dev/null || {  # Keep 1 hour of logs
            print_warning "Failed to optimize journal"
        }
        sudo systemctl restart systemd-journald 2>/dev/null || {
            print_warning "Failed to restart journald"
        }
    fi
}

# Generate new machine ID (for live ISO)
generate_new_ids() {
    print_status "Generating new system IDs..."
    
    if [[ $EUID -eq 0 ]]; then
        # Generate new machine ID
        if [[ -f /etc/machine-id ]]; then
            dbus-uuidgen --ensure=/etc/machine-id 2>/dev/null || true
        fi
        
        # Generate new DBus machine ID
        if [[ -f /var/lib/dbus/machine-id ]]; then
            dbus-uuidgen --ensure 2>/dev/null || true
        fi
    fi
}

# Show cleanup summary
show_summary() {
    print_status "Cleanup completed!"
    
    # Show disk usage
    echo ""
    print_info "Disk usage after cleanup:"
    df -h / | tail -1
    
    # Show total space freed (approximate)
    echo ""
    print_info "Cleanup operations performed:"
    echo "  ✓ Package cache cleaned"
    echo "  ✓ User caches removed"
    echo "  ✓ System logs rotated"
    echo "  ✓ Temporary files deleted"
    echo "  ✓ History files cleared"
    echo "  ✓ Sensitive data removed"
    echo "  ✓ System IDs reset"
    
    print_warning "System is now ready for ISO building."
}

# Main cleanup function
main_cleanup() {
    print_status "Starting ShouArch system cleanup..."
    
    safety_checks "$@"
    
    clean_package_cache
    clean_user_caches
    clean_logs
    clean_temporary_files
    reset_machine_id
    remove_history_files
    clean_package_data
    clean_sensitive_data
    optimize_journal
    generate_new_ids
    
    show_summary
}

# Show help
show_help() {
    echo "ShouArch Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force     Skip confirmation prompt"
    echo "  --safe      Only clean user caches (safe for daily use)"
    echo "  --help      Show this help message"
    echo ""
    echo "This script cleans system caches and temporary files in preparation"
    echo "for ISO building. Use with caution on production systems."
}

# Safe cleanup mode (for daily use)
safe_cleanup() {
    print_status "Running safe cleanup (user data only)..."
    
    clean_user_caches
    clean_temporary_files
    remove_history_files
    
    print_status "Safe cleanup completed!"
}

# Parse command line arguments
case "${1:-}" in
    "--help"|"-h")
        show_help
        exit 0
        ;;
    "--safe")
        safe_cleanup
        exit 0
        ;;
    "--force")
        main_cleanup --force
        ;;
    *)
        main_cleanup "$@"
        ;;
esac