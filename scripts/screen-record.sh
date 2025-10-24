#!/bin/bash

# ShouArch Screen Recorder

RECORDINGS_DIR="$HOME/Videos/Recordings"
mkdir -p "$RECORDINGS_DIR"

timestamp=$(date +"%Y%m%d_%H%M%S")

case "${1:-}" in
    "start")
        # Start recording
        filename="recording_${timestamp}.mp4"
        wf-recorder -g "$(slurp)" -f "$RECORDINGS_DIR/$filename" &
        echo $! > /tmp/shouarch_recording.pid
        notify-send "Recording Started" "Select area to record"
        ;;
    "stop")
        # Stop recording
        if [[ -f /tmp/shouarch_recording.pid ]]; then
            kill -SIGINT "$(cat /tmp/shouarch_recording.pid)"
            rm /tmp/shouarch_recording.pid
            notify-send "Recording Stopped" "Video saved to Recordings folder"
        else
            notify-send "No active recording found"
        fi
        ;;
    *)
        echo "Usage: $0 [start|stop]"
        ;;
esac