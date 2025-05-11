#!/bin/bash

PLAYER="spotify"
FORMAT="{{ artist }} - {{ title }}"
PARENT_BAR_PID=$(pgrep -f "polybar")  # O ajústalo si tienes una mejor forma de obtener el ID
SCROLL_SPEED=0.2  # segundos entre scroll
PADDING="    "    # espacio entre repeticiones

scroll_text() {
    local text="$1$PADDING"
    while true; do
        echo "%{l}${text}"
        text="${text:1}${text:0:1}"
        sleep $SCROLL_SPEED
    done
}

get_status() {
    PLAYERCTL_STATUS=$(playerctl --player=$PLAYER status 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$PLAYERCTL_STATUS"
    else
        echo "No player is running"
    fi
}

main() {
    STATUS=$(get_status)

    if [ "$1" == "--status" ]; then
        echo "$STATUS"
        exit 0
    fi

    if [ "$STATUS" = "Stopped" ]; then
        scroll_text "No music is playing"
    elif [ "$STATUS" = "Paused" ]; then
        playerctl --player=$PLAYER metadata --format "$FORMAT" | while read -r metadata; do
            update_hooks "$PARENT_BAR_PID" 2
            scroll_text "$metadata"
        done
    elif [ "$STATUS" = "No player is running" ]; then
        scroll_text "$STATUS"
    else
        playerctl --player=$PLAYER metadata --format "$FORMAT" | while read -r metadata; do
            update_hooks "$PARENT_BAR_PID" 1
            scroll_text "$metadata"
        done
    fi
}

update_hooks() {
    echo "$1" | while IFS= read -r id
    do
        polybar-msg -p "$id" hook spotify-play-pause $2 1>/dev/null 2>&1
    done
}

main "$@"
