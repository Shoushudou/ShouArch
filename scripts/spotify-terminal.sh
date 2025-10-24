#!/bin/bash

# ShouArch Spotify Terminal Integration
# Auto play RANDOM album + show REAL album art

# Spotify URIs for each artist (album favorites)
declare -A ARTIST_ALBUMS=(
    ["xxxtentacion"]="spotify:album:4UlGauD7ROb3YbVOFMgW5u"  # ?
    ["shilohdynasty"]="spotify:album:0Jd6b2WLqjWrVM7VURselB"  # Shiloh Dynasty Album
    ["lilpeep"]="spotify:album:2B0fUi0BSwxK2HGNtaFApb"  # Come Over When You're Sober, Pt. 1
    ["trippieredd"]="spotify:album:3WYOXs6siW1WkUFSWKOFwD"  # A Love Letter To You 4
    ["theweeknd"]="spotify:album:3lS1y25WAhcqJDATJK70Mq"  # After Hours
    ["ynwmelly"]="spotify:album:7rHlFTAIJ4BxF6WbKAV2jS"  # We All Shine
    ["kanyewest"]="spotify:album:4xPY7C8cM2pA9g1w1cYdfh"  # The Life of Pablo
    ["danielcaesar"]="spotify:album:1xrKMrOnjVaY7Qf1x4YzgG"  # CASE STUDY 01
)

# Additional albums for more variety
declare -a EXTRA_ALBUMS=(
    "spotify:album:2yDVYxqU9f7RicmlPye7hK"  # XXXTENTACION - Bad Vibes Forever
    "spotify:album:4aawyAB9vmqN3uQ7FjRGTy"  # The Weeknd - Starboy
    "spotify:album:2D7W7q5sUIMIcYrnGsul1L"  # Lil Peep - Hellboy
    "spotify:album:5gsJsMI2o5ReO7JNw5jzBX"  # Trippie Redd - !
    "spotify:album:0FgZKfoU2Br5sHOfvZKTI9"  # Kanye West - Graduation
    "spotify:album:0aDuNMhd1dUF9UC0J1Hllp"  # Daniel Caesar - Freudian
    "spotify:album:1ATL5GLyefJaxhQzSPVrLX"  # YNW Melly - I Am You
)

get_random_album() {
    # Combine both arrays
    local all_albums=()
    
    # Add albums from ARTIST_ALBUMS
    for album in "${ARTIST_ALBUMS[@]}"; do
        all_albums+=("$album")
    done
    
    # Add extra albums
    for album in "${EXTRA_ALBUMS[@]}"; do
        all_albums+=("$album")
    done
    
    # Select random album
    local random_index=$((RANDOM % ${#all_albums[@]}))
    SELECTED_ALBUM="${all_albums[$random_index]}"
    
    # Get artist name for logging
    for artist in "${!ARTIST_ALBUMS[@]}"; do
        if [[ "${ARTIST_ALBUMS[$artist]}" == "$SELECTED_ALBUM" ]]; then
            SELECTED_ARTIST="$artist"
            break
        fi
    done
    
    # If not found in main array, check extra albums
    if [[ -z "$SELECTED_ARTIST" ]]; then
        SELECTED_ARTIST="various"
    fi
    
    echo "🎲 Selected: $SELECTED_ARTIST"
}

check_spotify_ready() {
    local max_attempts=15
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        # Check if Spotify is responding to DBus
        if dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
            /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
            string:"org.mpris.MediaPlayer2.Player" string:"PlaybackStatus" 2>/dev/null | grep -q "string"; then
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    
    echo "❌ Spotify is not responding to DBus commands"
    return 1
}

start_spotify_playback() {
    # Get random album
    get_random_album
    
    # Start Spotify jika belum running
    if ! pgrep -x "spotify" > /dev/null; then
        echo "🎵 Starting Spotify..."
        spotify --uri="" --minimized &
        local spotify_pid=$!
        
        # Wait for Spotify window to appear
        sleep 7
    else
        echo "🎵 Spotify is already running"
    fi
    
    # Tunggu sampai Spotify ready
    if ! check_spotify_ready; then
        echo "❌ Failed to connect to Spotify. Please make sure Spotify is running and logged in."
        return 1
    fi
    
    # Play random album
    echo "🎵 Playing album: $SELECTED_ARTIST"
    
    # Stop current playback first
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
        /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop > /dev/null 2>&1
    
    sleep 1
    
    # Play the selected album
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
        /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.OpenUri \
        string:"$SELECTED_ALBUM" > /dev/null 2>&1
    
    sleep 2
    
    # Start playback
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
        /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play > /dev/null 2>&1
    
    echo "✅ Playback started"
}

get_spotify_album_art() {
    # Wait a bit for metadata to be available
    sleep 3
    
    # Try multiple methods to get album art
    if get_album_art_playerctl; then
        return 0
    elif get_album_art_dbus; then
        return 0
    else
        display_placeholder_art
        return 1
    fi
}

get_album_art_playerctl() {
    if command -v playerctl &> /dev/null; then
        # Get album art URL from playerctl
        art_url=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
        
        if [[ -n "$art_url" ]]; then
            echo "🖼️ Downloading album art from playerctl..."
            
            # Download album art
            temp_art="/tmp/spotify_album_art_$$.jpg"
            
            if curl -s -L -A "Mozilla/5.0" "$art_url" -o "$temp_art" && [[ -s "$temp_art" ]]; then
                display_album_art "$temp_art"
                return 0
            fi
        fi
    fi
    return 1
}

get_album_art_dbus() {
    local max_attempts=3
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
            /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
            string:"org.mpris.MediaPlayer2.Player" string:"Metadata" 2>/dev/null)
        
        if [[ -n "$metadata" ]]; then
            # Try different patterns to extract artUrl
            art_url=$(echo "$metadata" | grep -oP 'artUrl.*?string "\K[^"]+' | head -1)
            
            if [[ -z "$art_url" ]]; then
                art_url=$(echo "$metadata" | grep "artUrl" | awk -F '"' '{print $2}')
            fi
            
            if [[ -n "$art_url" ]]; then
                echo "🖼️ Downloading album art via DBus..."
                temp_art="/tmp/spotify_album_art_$$.jpg"
                
                if curl -s -L -A "Mozilla/5.0" "$art_url" -o "$temp_art" && [[ -s "$temp_art" ]]; then
                    display_album_art "$temp_art"
                    return 0
                fi
            fi
        fi
        
        sleep 2
        ((attempt++))
    done
    return 1
}

display_album_art() {
    local art_file="$1"
    
    if [[ "$TERM" == "xterm-kitty" ]] && [[ -f "$art_file" ]]; then
        # Display di pojok kiri atas terminal
        kitty +kitten icat --place 60x60@1x1 --align left "$art_file" &
        local icat_pid=$!
        
        echo "🎨 Album art displayed in terminal"
        
        # Get current track info
        if command -v playerctl &> /dev/null; then
            local artist=$(playerctl -p spotify metadata artist 2>/dev/null)
            local album=$(playerctl -p spotify metadata album 2>/dev/null)
            local title=$(playerctl -p spotify metadata title 2>/dev/null)
            
            if [[ -n "$artist" && -n "$title" ]]; then
                echo "🎶 Now Playing: $artist - $title"
                echo "💿 Album: $album"
            else
                echo "🎶 Getting track info..."
                sleep 2
                # Try again after a delay
                artist=$(playerctl -p spotify metadata artist 2>/dev/null)
                title=$(playerctl -p spotify metadata title 2>/dev/null)
                if [[ -n "$artist" && -n "$title" ]]; then
                    echo "🎶 Now Playing: $artist - $title"
                fi
            fi
        fi
    else
        echo "ℹ️  Kitty terminal not detected or album art not available"
    fi
}

display_placeholder_art() {
    # Fallback placeholder
    local placeholder_dir="/etc/configs/terminal/album-covers"
    local placeholder=""
    
    # Check if placeholder directory exists
    if [[ -d "$placeholder_dir" ]]; then
        local covers=("$placeholder_dir"/*.jpg "$placeholder_dir"/*.png)
        if [[ ${#covers[@]} -gt 0 ]] && [[ ${covers[0]} != "$placeholder_dir/*.jpg" ]]; then
            placeholder="${covers[RANDOM % ${#covers[@]}]}"
        fi
    fi
    
    # If no placeholder found, use a simple fallback
    if [[ -z "$placeholder" ]] || [[ ! -f "$placeholder" ]]; then
        echo "🎨 No album art available"
        return
    fi
    
    if [[ "$TERM" == "xterm-kitty" ]]; then
        kitty +kitten icat --place 60x60@1x1 --align left "$placeholder" &
        echo "🎨 Displaying placeholder art"
    fi
}

cleanup_old_art() {
    # Bersihkan file album art lama (older than 1 hour)
    find /tmp -name "spotify_album_art_*.jpg" -mmin +60 -delete 2>/dev/null
}

# Music control functions
music_next_album() {
    echo "🔄 Switching to new random album..."
    cleanup_old_art
    # Use a different approach to avoid recursion issues
    exec bash -c '
        unset SPOTIFY_TERMINAL_STARTED
        /usr/local/bin/spotify-terminal.sh
    '
}

# Handle command line arguments
case "${1:-}" in
    "next-album")
        music_next_album
        exit 0
        ;;
    "status")
        if pgrep -x "spotify" > /dev/null; then
            echo "✅ Spotify is running"
            playerctl -p spotify metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo "No track playing"
        else
            echo "❌ Spotify is not running"
        fi
        exit 0
        ;;
    "stop")
        pkill -f "kitty +kitten icat" 2>/dev/null
        cleanup_old_art
        echo "🛑 Spotify integration stopped"
        exit 0
        ;;
esac

# Main execution
if [[ "$TERM" == "xterm-kitty" ]]; then
    if [[ -z "$SPOTIFY_TERMINAL_STARTED" ]]; then
        export SPOTIFY_TERMINAL_STARTED=1
        
        echo "🎧 Initializing Spotify integration..."
        echo "🎸 Artists: XXXTENTACION, Shiloh Dynasty, Lil Peep, Trippie Redd, The Weeknd, YNW Melly, Kanye West, Daniel Caesar"
        
        # Bersihkan file lama
        cleanup_old_art
        
        # Start playback dengan random album
        if start_spotify_playback; then
            # Get dan display album art
            get_spotify_album_art
            
            echo "✅ Spotify integration ready"
            echo "   Controls: music-pause, music-next, music-prev"
            echo "   New Album: music-next-album"
            echo "   Status: music-status"
        else
            echo "❌ Failed to start Spotify playback"
        fi
    else
        echo "🔁 Spotify integration already running in this terminal"
    fi
else
    echo "ℹ️  This feature requires Kitty terminal"
fi