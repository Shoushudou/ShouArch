# ShouArch Custom Bash Configuration

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Spotify Terminal Integration (only in Kitty)
if [[ "$TERM" == "xterm-kitty" ]]; then
    ~/scripts/spotify-terminal.sh
fi

# ShouArch Welcome Message
echo -e "\033[1;35m"
echo "    ███████╗██╗  ██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗"
echo "    ██╔════╝██║  ██║██╔═══██╗██║   ██║██╔══██╗██╔══██╗██╔════╝██║  ██║"
echo "    ███████╗███████║██║   ██║██║   ██║███████║██████╔╝██║     ███████║"
echo "    ╚════██║██╔══██║██║   ██║╚██╗ ██╔╝██╔══██║██╔══██╗██║     ██╔══██║"
echo "    ███████║██║  ██║╚██████╔╝ ╚████╔╝ ██║  ██║██║  ██║╚██████╗██║  ██║"
echo "    ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
echo -e "\033[0m"

# System info dengan style
echo -e "\033[1;36m╔════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║                 SYSTEM SNAPSHOT               ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════╝\033[0m"

fastfetch

# Additional system info
echo -e "\033[1;33m📊 Quick Stats:\033[0m"
echo -e "   💾 Disk: $(df -h / | awk 'NR==2 {print $4 " free / " $2 " total"}')"
echo -e "   🧠 RAM: $(free -h | awk 'NR==2 {print $3 " used / " $2 " total"}')"
echo -e "   🔥 Temp: $(sensors | grep 'Package id' | awk '{print $4}' | head -1)"

# Music status (if Spotify is running)
if pgrep -x "spotify" > /dev/null; then
    echo -e "\033[1;32m🎵 Now Playing:\033[0m"
    playerctl -p spotify metadata --format "   🎸 {{ artist }} - {{ title }}" 2>/dev/null || echo "   ⏸️  No track playing"
fi

# Pywal colors
cat ~/.cache/wal/sequences

# Aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias update='sudo pacman -Syu'
alias clean='sudo pacman -Scc'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias hyprconf='nvim ~/.config/hypr/hyprland.conf'
alias waybarconf='nvim ~/.config/waybar/config'
alias walset='walset.sh'

# Spotify control aliases
alias music-play='dbus-send --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play'
alias music-pause='dbus-send --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause'
alias music-playpause='dbus-send --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause'
alias music-next='dbus-send --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next'
alias music-prev='dbus-send --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous'
alias music-stop='dbus-send --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop'
alias music-status='playerctl -p spotify status'
alias music-info='playerctl -p spotify metadata'
alias music-next-album='~/scripts/spotify-terminal.sh next-album'

# Quick commands
alias neo='neofetch'
alias temp='sensors | grep -E "(Package id|Core)"'
alias bat='cat /sys/class/power_supply/BAT*/capacity'

# Environment variables
export EDITOR=nvim
export VISUAL=nvim
export BROWSER=firefox
export TERMINAL=kitty

# History settings
HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=ignoreboth

# Append to history file
shopt -s histappend

# Check window size after commands
shopt -s checkwinsize

# Custom prompt
PS1='\[\033[1;36m\][\u@\h \W]\$\[\033[0m\] '

# Startup applications
if [[ -z "$TMUX" ]] && command -v tmux &> /dev/null; then
    tmux new-session -A -s main
fi

# Cheatsheet alias
alias cheatsheet='~/scripts/cheatsheet.sh'

# Fun random messages
messages=(
    "🎸 Rock on with ShouArch!"
    "🎧 Vibing with the music?"
    "🚀 Ready to code and create!"
    "🎨 Make something beautiful today!"
    "🔥 Stay productive, stay creative!"
)

echo -e "\033[1;35m💫 ${messages[$RANDOM % ${#messages[@]}]}\033[0m"