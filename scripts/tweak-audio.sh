#!/bin/bash

# ShouArch Audio Tweaks for PipeWire

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

# Check if PipeWire is running
check_pipewire() {
    if ! systemctl --user is-active --quiet pipewire; then
        print_info "Starting PipeWire..."
        systemctl --user start pipewire
    fi
}

# Configure PipeWire for low latency
configure_low_latency() {
    print_status "Configuring low latency audio..."
    
    # Create PipeWire client config
    mkdir -p ~/.config/pipewire
    cat > ~/.config/pipewire/client.conf << 'EOF'
# ShouArch Low Latency Client Configuration

context.properties = {
    link.max-buffers = 16
    log.level = 0
}

stream.properties = {
    node.latency = 128/48000
    resample.quality = 4
}
EOF

    # Create PipeWire main config override
    mkdir -p ~/.config/pipewire/pipewire.conf.d/
    cat > ~/.config/pipewire/pipewire.conf.d/10-shouarch-lowlatency.conf << 'EOF'
# ShouArch Low Latency Configuration

context.modules = [
    { name = libpipewire-module-rtkit
        args = {
            nice.level = -15
            rt.prio = 88
            rt.time.soft = 200000
            rt.time.hard = 200000
        }
        flags = [ ifexists nofail ]
    }
]

context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 128
    default.clock.min-quantum = 32
    default.clock.max-quantum = 512
}
EOF
}

# Configure PulseAudio compatibility
configure_pulse_compat() {
    print_status "Configuring PulseAudio compatibility..."
    
    # Start PulseAudio services
    systemctl --user enable --now pipewire-pulse.socket
    systemctl --user enable --now pipewire-pulse.service
}

# Setup easy effects if installed
setup_easy_effects() {
    if command -v easyeffects &> /dev/null; then
        print_status "Setting up EasyEffects..."
        
        # Import ShouArch audio profile
        if [[ -f "/etc/configs/audio/shouarch-easyeffects.json" ]]; then
            mkdir -p ~/.config/easyeffects/output/
            cp /etc/configs/audio/shouarch-easyeffects.json ~/.config/easyeffects/output/
            print_info "EasyEffects profile imported"
        fi
        
        # Autostart EasyEffects
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/easyeffects.desktop << EOF
[Desktop Entry]
Type=Application
Name=EasyEffects
Exec=easyeffects --gapplication-service
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    fi
}

# Audio quality tweaks
audio_quality_tweaks() {
    print_status "Applying audio quality tweaks..."
    
    # ALSA configuration
    sudo mkdir -p /etc/alsa/conf.d/
    sudo tee /etc/alsa/conf.d/10-shouarch-quality.conf > /dev/null << 'EOF'
# ShouArch ALSA Quality Tweaks

defaults.pcm.dmix.rate 48000
defaults.pcm.dmix.format S24_3LE
defaults.pcm.dsnoop.rate 48000
defaults.ctl.card 0
defaults.pcm.card 0
defaults.pcm.rate_converter "speexrate_medium"
EOF

    # WirePlumber configuration
    mkdir -p ~/.config/wireplumber/main.lua.d/
    cat > ~/.config/wireplumber/main.lua.d/10-shouarch-audio.lua << 'EOF'
-- ShouArch WirePlumber Configuration

alsa_monitor.rules = {
  {
    matches = {
      {
        { "device.name", "matches", "alsa_card.*" },
      },
    },
    apply_properties = {
      ["api.alsa.use-acp"] = true,
      ["api.acp.auto-profile"] = false,
      ["api.acp.auto-port"] = false,
    },
  },
  {
    matches = {
      {
        { "node.name", "matches", "alsa_output.*" },
      },
    },
    apply_properties = {
      ["audio.format"] = "S24_3LE",
      ["audio.rate"] = 48000,
      ["api.alsa.period-size"] = 128,
      ["session.suspend-timeout-seconds"] = 0,
    },
  }
}
EOF
}

# Main function
main() {
    print_status "Starting ShouArch audio tweaks..."
    
    check_pipewire
    configure_low_latency
    configure_pulse_compat
    setup_easy_effects
    audio_quality_tweaks
    
    print_status "Audio tweaks completed!"
    print_info "Please restart PipeWire for changes to take effect:"
    echo "systemctl --user restart pipewire"
}

# Execute main function
main "$@"