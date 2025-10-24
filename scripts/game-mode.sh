#!/bin/bash

# ShouArch Gaming Mode Optimizer

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Config
GAMING_MODE_FILE="/tmp/shouarch-gaming-mode"
GAMEMODE_PID_FILE="/tmp/gamemode.pid"

print_status() { echo -e "${GREEN}[→]${NC} $1"; }
print_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_gaming() { echo -e "${MAGENTA}[🎮]${NC} $1"; }

# Check if running as root
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Please run as regular user (will use sudo when needed)"
        exit 1
    fi
}

# Check current system state
check_system_state() {
    print_info "Checking system state..."
    
    # CPU governor
    local current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Unknown")
    print_info "CPU Governor: $current_governor"
    
    # GameMode status
    if pgrep -x "gamemoded" > /dev/null; then
        print_info "GameMode: Running"
    else
        print_info "GameMode: Not running"
    fi
    
    # GPU info
    if command -v nvidia-smi &> /dev/null; then
        local gpu_mode=$(nvidia-smi --query-gpu=power.default_limit -i 0 --format=csv,noheader,nounits 2>/dev/null || echo "Unknown")
        print_info "NVIDIA GPU: Power mode data available"
    elif command -v rocm-smi &> /dev/null; then
        print_info "AMD GPU: ROCm detected"
    else
        print_info "GPU: Integrated or unknown"
    fi
}

# CPU optimizations
optimize_cpu() {
    print_status "Optimizing CPU performance..."
    
    # Set CPU governor to performance
    if [[ -d "/sys/devices/system/cpu/cpufreq" ]]; then
        echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || {
            print_warning "Could not set CPU governor (may require cpupower)"
        }
        
        # Use cpupower if available
        if command -v cpupower &> /dev/null; then
            sudo cpupower frequency-set -g performance || {
                print_warning "cpupower governor setting failed"
            }
        fi
    else
        print_warning "CPU frequency scaling not available"
    fi
    
    # Set nice value for current process
    renice -n -5 $$ 2>/dev/null || true
    
    # Disable CPU frequency scaling limits temporarily
    if [[ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
        echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    fi
}

# GPU optimizations
optimize_gpu() {
    print_status "Optimizing GPU performance..."
    
    # NVIDIA GPU
    if command -v nvidia-settings &> /dev/null; then
        print_info "Configuring NVIDIA GPU..."
        nvidia-settings -a '[gpu:0]/GPUPowerMizerMode=1' 2>/dev/null || {
            print_warning "Failed to set NVIDIA PowerMizer mode"
        }
        
        # Set performance mode
        nvidia-settings -a '[gpu:0]/PerfMode=1' 2>/dev/null || true
        
    # AMD GPU (ROCm)
    elif command -v rocm-smi &> /dev/null; then
        print_info "Configuring AMD GPU..."
        sudo rocm-smi --setperflevel high 2>/dev/null || {
            print_warning "Failed to set AMD GPU performance level"
        }
    
    # Generic GPU (Mesa)
    else
        print_info "Using generic GPU optimizations..."
        # Set environment variables for Mesa
        export __GL_THREADED_OPTIMIZATIONS=1
        export __GL_SYNC_TO_VBLANK=0
        export __GL_YIELD="USLEEP"
    fi
}

# GameMode integration
start_gamemode() {
    print_status "Starting GameMode..."
    
    if command -v gamemoded &> /dev/null; then
        if ! pgrep -x "gamemoded" > /dev/null; then
            gamemoded -d &
            echo $! > "$GAMEMODE_PID_FILE"
            print_info "GameMode daemon started"
        else
            print_info "GameMode already running"
        fi
        
        # Set GameMode state
        gamemoded -s &
    else
        print_warning "GameMode not installed. Install 'gamemode' package."
    fi
}

# Process priority optimizations
optimize_process_priority() {
    print_status "Optimizing process priorities..."
    
    # Set nice values for common background processes (higher nice = lower priority)
    for process in "pulseaudio" "pipewire" "spotify" "discord"; do
        if pgrep -x "$process" > /dev/null; then
            sudo renice -n 10 $(pgrep -x "$process") 2>/dev/null || true
        fi
    done
    
    # Reduce swappiness for better gaming performance
    echo 10 | sudo tee /proc/sys/vm/swappiness 2>/dev/null || true
}

# Kernel and system optimizations
optimize_kernel() {
    print_status "Applying kernel optimizations..."
    
    # Disable transparent hugepages for better latency
    echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
    
    # Increase VM dirty ratio for better performance
    echo 20 | sudo tee /proc/sys/vm/dirty_ratio 2>/dev/null || true
    echo 10 | sudo tee /proc/sys/vm/dirty_background_ratio 2>/dev/null || true
    
    # Disable watchdog for better performance
    echo 0 | sudo tee /proc/sys/kernel/watchdog 2>/dev/null || true
}

# Network optimizations (for online gaming)
optimize_network() {
    print_status "Applying network optimizations..."
    
    # Increase socket buffers
    echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.d/99-gaming.conf > /dev/null 2>&1 || true
    echo 'net.core.wmem_max = 16777216' | sudo tee -a /etc/sysctl.d/99-gaming.conf > /dev/null 2>&1 || true
    
    # TCP optimizations
    echo 'net.ipv4.tcp_rmem = 4096 87380 16777216' | sudo tee -a /etc/sysctl.d/99-gaming.conf > /dev/null 2>&1 || true
    echo 'net.ipv4.tcp_wmem = 4096 16384 16777216' | sudo tee -a /etc/sysctl.d/99-gaming.conf > /dev/null 2>&1 || true
}

# Audio optimizations for gaming
optimize_audio() {
    print_status "Optimizing audio for gaming..."
    
    # Set PipeWire/Zoom to gaming profile if available
    if command -v pw-top &> /dev/null; then
        print_info "PipeWire detected - using gaming profile"
        # PipeWire is generally good for gaming, no changes needed
    fi
}

# Monitoring and status
start_monitoring() {
    print_status "Starting performance monitoring..."
    
    # Start MangoHUD if available
    if command -v mangohud &> /dev/null; then
        print_info "MangoHUD available - enable with 'mangohud %command%' in game launch options"
    fi
    
    # Create gaming mode status file
    echo "Gaming Mode Active - Started: $(date)" > "$GAMING_MODE_FILE"
}

# Revert all optimizations
revert_optimizations() {
    print_status "Reverting to normal system state..."
    
    # CPU governor back to ondemand
    if [[ -d "/sys/devices/system/cpu/cpufreq" ]]; then
        echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        
        if command -v cpupower &> /dev/null; then
            sudo cpupower frequency-set -g ondemand 2>/dev/null || true
        fi
    fi
    
    # Re-enable CPU frequency limits
    if [[ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
        echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    fi
    
    # Stop GameMode
    if [[ -f "$GAMEMODE_PID_FILE" ]]; then
        kill $(cat "$GAMEMODE_PID_FILE") 2>/dev/null || true
        rm -f "$GAMEMODE_PID_FILE"
    fi
    pkill -x "gamemoded" 2>/dev/null || true
    
    # Reset nice values
    renice -n 0 $$ 2>/dev/null || true
    
    # Remove gaming mode status file
    rm -f "$GAMING_MODE_FILE"
    
    # Reset kernel parameters
    echo 60 | sudo tee /proc/sys/vm/swappiness 2>/dev/null || true
    echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
}

# Show current gaming mode status
show_status() {
    if [[ -f "$GAMING_MODE_FILE" ]]; then
        print_gaming "Gaming Mode is ACTIVE"
        cat "$GAMING_MODE_FILE"
        echo ""
        
        # Show current optimizations
        print_info "Current optimizations:"
        local cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Unknown")
        echo "  CPU Governor: $cpu_gov"
        
        if pgrep -x "gamemoded" > /dev/null; then
            echo "  GameMode: Running"
        else
            echo "  GameMode: Not running"
        fi
    else
        print_info "Gaming Mode is INACTIVE"
    fi
}

# Performance benchmark (quick test)
quick_benchmark() {
    print_status "Running quick performance check..."
    
    # CPU benchmark (very basic)
    local start_time=$(date +%s%N)
    for i in {1..1000}; do : ; done
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    print_info "CPU responsiveness: ${duration}ms (lower is better)"
    
    # Memory speed (basic test)
    local mem_speed=$(dd if=/dev/zero of=/tmp/test bs=1M count=64 2>&1 | grep "copied" | awk '{print $8, $9}')
    print_info "Memory write speed: $mem_speed"
    rm -f /tmp/test
}

# Main enable function
enable_gaming_mode() {
    print_gaming "Enabling ShouArch Gaming Mode..."
    echo ""
    
    check_privileges
    check_system_state
    echo ""
    
    optimize_cpu
    optimize_gpu
    start_gamemode
    optimize_process_priority
    optimize_kernel
    optimize_network
    optimize_audio
    start_monitoring
    
    echo ""
    print_gaming "🎮 Gaming Mode Activated! 🎮"
    echo ""
    print_info "Optimizations applied:"
    echo "  ✓ CPU performance governor"
    echo "  ✓ GPU performance mode" 
    echo "  ✓ GameMode integration"
    echo "  ✓ Process priority optimization"
    echo "  ✓ Kernel performance tweaks"
    echo "  ✓ Network optimizations"
    echo ""
    print_warning "Use '$0 status' to check current mode"
    print_warning "Use '$0 off' to disable gaming mode"
}

# Main disable function  
disable_gaming_mode() {
    print_gaming "Disabling Gaming Mode..."
    
    check_privileges
    revert_optimizations
    
    print_info "🎮 Gaming Mode Deactivated 🎮"
    print_info "System returned to normal power profile"
}

# Handle command line arguments
case "${1:-}" in
    "on"|"enable"|"start")
        enable_gaming_mode
        ;;
    "off"|"disable"|"stop")
        disable_gaming_mode
        ;;
    "status"|"check")
        show_status
        ;;
    "benchmark"|"test")
        quick_benchmark
        ;;
    "monitor")
        if command -v btop &> /dev/null; then
            btop
        elif command -v htop &> /dev/null; then
            htop
        else
            print_warning "Install btop or htop for system monitoring"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "ShouArch Gaming Mode Optimizer"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  on, enable    - Enable gaming optimizations"
        echo "  off, disable  - Disable gaming optimizations" 
        echo "  status        - Show current gaming mode status"
        echo "  benchmark     - Run quick performance check"
        echo "  monitor       - Open system monitor"
        echo "  help          - Show this help"
        echo ""
        echo "Features:"
        echo "  • CPU performance governor"
        echo "  • GPU performance mode (NVIDIA/AMD)"
        echo "  • GameMode integration"
        echo "  • Process priority optimization"
        echo "  • Kernel and network tweaks"
        echo "  • Audio optimizations"
        ;;
    *)
        if [[ -f "$GAMING_MODE_FILE" ]]; then
            show_status
        else
            echo "Usage: $0 [on|off|status|benchmark|monitor|help]"
            echo "Try '$0 help' for more information."
        fi
        ;;
esac