#!/bin/bash

# =============================================================================
# Spotify Status Script for Polybar
# Displays current playing track and controls playback hooks
# =============================================================================

# Player configuration
PLAYER="spotify"
FORMAT="{{ artist }} - {{ title }}"
SCROLL_SPEED=0.2
PADDING="    "

# Track previous state to detect changes
last_metadata=""
last_status=""
# Get polybar parent process for hook updates
PARENT_BAR_PID=$(pgrep -f "polybar")

# Scroll text horizontally for long titles
scroll_text() {
    local text="$1$PADDING"
    for ((i = 0; i < ${#text}; i++)); do
        echo "$text"
        text="${text:1}${text:0:1}"
        sleep $SCROLL_SPEED
    done
}

# Get current player status (Playing/Paused/Stopped)
get_status() {
    playerctl --player="$PLAYER" status 2>/dev/null || echo "No player is running"
}

# Get current track metadata (artist - title)
get_metadata() {
    playerctl --player="$PLAYER" metadata --format "$FORMAT" 2>/dev/null
}

# Update polybar hooks when status changes
update_hooks() {
    echo "$1" | while IFS= read -r id; do
        polybar-msg -p "$id" hook spotify-play-pause "$2" 1>/dev/null 2>&1
    done
}

# Main loop - monitor Spotify status and scroll metadata
while true; do
    STATUS=$(get_status)

    # Handle stopped or no player state
    if [[ "$STATUS" == "Stopped" || "$STATUS" == "No player is running" ]]; then
        metadata="No music is playing"
    else
        metadata=$(get_metadata)
    fi

    # Trigger polybar refresh on metadata change
    if [[ "$metadata" != "$last_metadata" ]]; then
        last_metadata="$metadata"
        polybar-msg hook spotify 1 > /dev/null 2>&1
    fi

    # Update play/pause icon on status change
    if [[ "$STATUS" != "$last_status" ]]; then
        last_status="$STATUS"
        if [[ "$STATUS" == "Playing" ]]; then
            update_hooks "$PARENT_BAR_PID" 1
        else
            update_hooks "$PARENT_BAR_PID" 0
        fi
    fi

    # Scroll and display the current text
    scroll_text "$metadata"
done
