#!/bin/bash

# =============================================================================
# Media Status Script for Polybar
# Displays the current track of the last active MPRIS player (Spotify, Chrome...)
# and controls playback hooks
# =============================================================================

# Player configuration
# playerctld (D-Bus activated) follows the most recently active player
PLAYER="playerctld"
# Unit separator, not whitespace: read keeps the empty artist of browser videos
SEP=$'\x1f'
FORMAT="{{ artist }}${SEP}{{ title }}"
SCROLL_SPEED=0.2
PADDING="    "
# --static:  no scrolling (polybar truncates the label)
# --fit <n>: show titles up to <n> characters as they are, scroll longer ones in a <n> wide window
STATIC=false
FIT=0
case "${1:-}" in
    --static) STATIC=true ;;
    --fit)    FIT=${2:?--fit requires a width} ;;
esac

# Track previous state to detect changes
last_status=""

# Scroll text horizontally for long titles
# Usage: scroll_text <text> [width] - width > 0 prints only that many characters
scroll_text() {
    local text="$1$PADDING"
    local width=${2:-0}
    for ((i = 0; i < ${#text}; i++)); do
        if (( width > 0 )); then
            echo "${text:0:width}"
        else
            echo "$text"
        fi
        text="${text:1}${text:0:1}"
        sleep $SCROLL_SPEED
    done
}

# Get current player status (Playing/Paused/Stopped)
get_status() {
    playerctl --player="$PLAYER" status 2>/dev/null || echo "No player is running"
}

# Get current track metadata: "artist - title", or just "title" without artist
get_metadata() {
    local artist title
    IFS="$SEP" read -r artist title < <(playerctl --player="$PLAYER" metadata --format "$FORMAT" 2>/dev/null)
    if [[ -n "$artist" ]]; then
        echo "$artist - $title"
    else
        echo "$title"
    fi
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
    if $STATIC || (( FIT > 0 && ${#metadata} <= FIT )); then
        echo "$metadata"
        sleep 1
    elif (( FIT > 0 )); then
        scroll_text "$metadata" "$FIT"
    else
        scroll_text "$metadata"
    fi
done
