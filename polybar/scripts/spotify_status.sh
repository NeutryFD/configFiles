#!/bin/bash

# =============================================================================
# Spotify Status Script for Polybar
# Displays current playing track and controls playback hooks
# =============================================================================

# Player configuration
PLAYER="fastpotify"
FORMAT="{{ artist }} - {{ title }}"
SCROLL_SPEED=0.2
PADDING="    "
# --static: no scrolling (polybar truncates the label)
STATIC=false
[[ "${1:-}" == "--static" ]] && STATIC=true

# Track previous state to detect changes
last_status=""

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

# Update the play/pause hook only on bars that have that module
# Hook actions are 0-based; timeout: a bar shutting down never answers
update_hooks() {
    local pid conf bar
    for pid in $(pgrep -x polybar); do
        read -r conf bar < <(tr '\0' ' ' < "/proc/$pid/cmdline" | sed -n 's/.*-c \([^ ]*\) \([^ ]*\).*/\1 \2/p')
        [[ -f "$conf" ]] || conf="/proc/$pid/cwd/$conf"
        awk -v s="[bar/$bar]" '$0 == s { f = 1; next } /^\[/ { f = 0 } f && /^modules-/ && /spotify-play-pause/ { ok = 1 } END { exit !ok }' "$conf" 2>/dev/null \
            && timeout 1 polybar-msg -p "$pid" action "#spotify-play-pause.hook.$1" 1>/dev/null 2>&1
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

    # Update play/pause icon on status change
    if [[ "$STATUS" != "$last_status" ]]; then
        last_status="$STATUS"
        if [[ "$STATUS" == "Playing" ]]; then
            update_hooks 1
        else
            update_hooks 0
        fi
    fi

    # Scroll and display the current text
    if $STATIC; then
        echo "$metadata"
        sleep 1
    else
        scroll_text "$metadata"
    fi
done
