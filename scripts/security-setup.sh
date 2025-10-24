#!/bin/bash

# ShouArch Security Hardening

set -e

print_status() { echo -e "\033[0;32m[*]\033[0m $1"; }

# Enable firewall
enable_firewall() {
    print_status "Configuring firewall..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
}

# Configure Firejail
setup_firejail() {
    print_status "Setting up Firejail..."
    
    # Create Firejail profiles for common apps
    sudo firejail --list
    
    # Browser sandboxing
    # Note: Create custom profiles in /etc/firejail/
}

# AppArmor setup
setup_apparmor() {
    print_status "Configuring AppArmor..."
    sudo systemctl enable apparmor
    sudo systemctl start apparmor
}

# System hardening
harden_system() {
    print_status "Applying system hardening..."
    
    # Disable root login
    sudo passwd -l root
    
    # Secure shared memory
    echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" | sudo tee -a /etc/fstab
}

main_security() {
    enable_firewall
    setup_firejail
    setup_apparmor
    harden_system
    
    print_status "Security setup completed!"
}

main_security