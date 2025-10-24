#!/bin/bash

# ShouArch ISO Builder
# GitHub: https://github.com/ShouShudou/shouarch

set -e

# Config
ISO_NAME="ShouArch"
ISO_VERSION="1.0"
WORK_DIR="/tmp/shouarch-build"
ISO_DIR="$WORK_DIR/iso"
ROOTFS="$WORK_DIR/rootfs"
PACKAGES_FILE="packages.txt"
OUTPUT_FILE="${ISO_NAME}-${ISO_VERSION}.iso"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    local deps=("arch-install-scripts" "squashfs-tools" "grub" "efibootmgr" "mtools" "dosfstools" "libisoburn")
    
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" &>/dev/null; then
            print_status "Installing dependency: $dep"
            sudo pacman -Sy --noconfirm "$dep" || {
                print_error "Failed to install $dep"
                exit 1
            }
        fi
    done
}

cleanup() {
    print_status "Cleaning up..."
    if [[ -d "$WORK_DIR" ]]; then
        sudo rm -rf "$WORK_DIR"
    fi
}

prepare_directories() {
    print_status "Preparing directories..."
    mkdir -p "$ISO_DIR"/{boot/grub,live,EFI}
    mkdir -p "$ROOTFS"
}

install_base_system() {
    print_status "Installing base system..."
    
    # Base packages untuk live environment
    local base_packages=(
        "base" "base-devel" "linux" "linux-firmware" 
        "grub" "efibootmgr" "networkmanager" "sudo"
        "nano" "vim" "git" "curl" "wget"
        "bash-completion" "man-db" "man-pages"
    )
    
    sudo pacstrap -C /etc/pacman.conf -G -M "$ROOTFS" "${base_packages[@]}" || {
        print_error "Failed to install base system"
        exit 1
    }
}

install_custom_packages() {
    print_status "Installing custom packages from $PACKAGES_FILE..."
    
    if [[ ! -f "$PACKAGES_FILE" ]]; then
        print_error "Packages file not found: $PACKAGES_FILE"
        exit 1
    fi
    
    # Read packages from file
    mapfile -t packages < <(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$')
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No packages found in $PACKAGES_FILE"
        return 0
    fi
    
    sudo pacstrap -C /etc/pacman.conf -G -M "$ROOTFS" "${packages[@]}" || {
        print_error "Failed to install custom packages"
        exit 1
    }
}

copy_configurations() {
    print_status "Copying configurations..."
    
    # Copy main configs
    if [[ -d "configs" ]]; then
        sudo cp -r configs/* "$ROOTFS/etc/" || {
            print_error "Failed to copy configs"
            exit 1
        }
        sudo chown -R root:root "$ROOTFS/etc/"
    else
        print_warning "configs/ directory not found"
    fi
    
    # Copy scripts
    if [[ -d "scripts" ]]; then
        sudo mkdir -p "$ROOTFS/usr/local/bin/"
        sudo cp -r scripts/* "$ROOTFS/usr/local/bin/" || {
            print_error "Failed to copy scripts"
            exit 1
        }
        sudo chmod +x "$ROOTFS/usr/local/bin/"* || {
            print_error "Failed to make scripts executable"
            exit 1
        }
    else
        print_warning "scripts/ directory not found"
    fi
    
    # Copy themes
    if [[ -d "themes" ]]; then
        sudo mkdir -p "$ROOTFS/usr/share/themes/"
        sudo cp -r themes/* "$ROOTFS/usr/share/themes/" || {
            print_error "Failed to copy themes"
            exit 1
        }
    else
        print_warning "themes/ directory not found"
    fi
    
    # Copy Hyprland plugins config
    sudo mkdir -p "$ROOTFS/etc/configs/hypr/"
    if [[ -f "configs/hypr/hyprbars.conf" ]]; then
        sudo cp configs/hypr/hyprbars.conf "$ROOTFS/etc/configs/hypr/" || {
            print_warning "Failed to copy hyprbars.conf"
        }
    fi
    if [[ -f "configs/hypr/hy3.conf" ]]; then
        sudo cp configs/hypr/hy3.conf "$ROOTFS/etc/configs/hypr/" || {
            print_warning "Failed to copy hy3.conf"
        }
    fi
    if [[ -f "configs/hypr/hyprwinwrap.conf" ]]; then
        sudo cp configs/hypr/hyprwinwrap.conf "$ROOTFS/etc/configs/hypr/" || {
            print_warning "Failed to copy hyprwinwrap.conf"
        }
    fi
}

setup_user() {
    print_status "Setting up default user..."
    
    # Create user shou
    cat << EOF | sudo arch-chroot "$ROOTFS" bash || {
        print_error "Failed to setup user"
        exit 1
    }
useradd -m -G wheel -s /bin/bash shou
echo "shou:130910" | chpasswd
echo "root:130910" | chpasswd

# Setup sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Create necessary directories
mkdir -p /home/shou/.config
chown -R shou:shou /home/shou
EOF
}

configure_system() {
    print_status "Configuring system..."
    
    # Generate fstab
    sudo genfstab -U "$ROOTFS" >> "$ROOTFS/etc/fstab" || {
        print_error "Failed to generate fstab"
        exit 1
    }
    
    # Set hostname
    echo "shouarch" | sudo tee "$ROOTFS/etc/hostname" || {
        print_error "Failed to set hostname"
        exit 1
    }
    
    # Set locale
    sudo sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' "$ROOTFS/etc/locale.gen" || {
        print_error "Failed to configure locale"
        exit 1
    }
    
    echo "LANG=en_US.UTF-8" | sudo tee "$ROOTFS/etc/locale.conf" || {
        print_error "Failed to set locale"
        exit 1
    }
    
    # Enable services
    cat << EOF | sudo arch-chroot "$ROOTFS" bash || {
        print_error "Failed to enable services"
        exit 1
    }
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable systemd-resolved

# Generate locale
locale-gen

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
EOF
}

create_squashfs() {
    print_status "Creating SquashFS..."
    
    # Check if rootfs exists and has content
    if [[ ! -d "$ROOTFS" ]] || [[ -z "$(ls -A "$ROOTFS")" ]]; then
        print_error "RootFS is empty or doesn't exist"
        exit 1
    fi
    
    sudo mksquashfs "$ROOTFS" "$ISO_DIR/live/rootfs.sfs" -comp xz -b 1M -noappend || {
        print_error "Failed to create SquashFS"
        exit 1
    }
}

setup_bootloaders() {
    print_status "Setting up bootloaders..."
    
    # Check if kernel files exist
    if [[ ! -f "$ROOTFS/boot/vmlinuz-linux" ]]; then
        print_error "Kernel not found: $ROOTFS/boot/vmlinuz-linux"
        exit 1
    fi
    
    if [[ ! -f "$ROOTFS/boot/initramfs-linux.img" ]]; then
        print_error "Initramfs not found: $ROOTFS/boot/initramfs-linux.img"
        exit 1
    fi
    
    # Copy kernel and initramfs
    sudo cp "$ROOTFS/boot/vmlinuz-linux" "$ISO_DIR/live/" || {
        print_error "Failed to copy kernel"
        exit 1
    }
    
    sudo cp "$ROOTFS/boot/initramfs-linux.img" "$ISO_DIR/live/" || {
        print_error "Failed to copy initramfs"
        exit 1
    }
    
    # GRUB configuration
    cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=5
set default=0

menuentry "ShouArch Live" {
    linux /live/vmlinuz-linux boot=live quiet splash
    initrd /live/initramfs-linux.img
}

menuentry "ShouArch Live (Safe Mode)" {
    linux /live/vmlinuz-linux boot=live systemd.unit=rescue.target
    initrd /live/initramfs-linux.img
}

menuentry "ShouArch Live (Debug Mode)" {
    linux /live/vmlinuz-linux boot=live systemd.log_level=debug systemd.log_target=console
    initrd /live/initramfs-linux.img
}
EOF
}

create_iso() {
    print_status "Creating ISO..."
    
    # Check if required files exist
    if [[ ! -f "$ISO_DIR/live/rootfs.sfs" ]]; then
        print_error "SquashFS not found: $ISO_DIR/live/rootfs.sfs"
        exit 1
    fi
    
    if [[ ! -f "$ISO_DIR/live/vmlinuz-linux" ]]; then
        print_error "Kernel not found in ISO directory"
        exit 1
    fi
    
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "SHOUARCH" \
        -eltorito-boot boot/grub/grub.cfg \
        -eltorito-catalog boot/grub/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr /usr/lib/syslinux/bios/isohdpfx.bin \
        -output "$OUTPUT_FILE" \
        "$ISO_DIR" || {
        print_error "Failed to create ISO"
        exit 1
    }
    
    print_status "ISO created: $OUTPUT_FILE"
    
    # Show size
    if [[ -f "$OUTPUT_FILE" ]]; then
        local size=$(du -h "$OUTPUT_FILE" | cut -f1)
        print_status "ISO size: $size"
    else
        print_error "ISO file was not created"
        exit 1
    fi
}

main() {
    print_status "Starting ShouArch ISO build..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "Please run as regular user (will use sudo when needed)"
        exit 1
    fi
    
    # Check if we're on Arch Linux
    if [[ ! -f "/etc/arch-release" ]]; then
        print_warning "This script is designed for Arch Linux. Proceed with caution."
    fi
    
    # Cleanup previous builds
    cleanup
    
    # Build steps
    check_dependencies
    prepare_directories
    install_base_system
    install_custom_packages
    copy_configurations
    setup_user
    configure_system
    create_squashfs
    setup_bootloaders
    create_iso
    
    print_status "Build completed successfully!"
    print_status "You can write the ISO to USB with:"
    echo "sudo dd if=$OUTPUT_FILE of=/dev/sdX bs=4M status=progress oflag=sync"
    echo ""
    print_status "Or use:"
    echo "sudo balena-etcher-electron # if etcher is installed"
}

# Run main function
main "$@"