#!/bin/bash

PLAYER="spotify"
FORMAT="{{ artist }} - {{ title }}"
SCROLL_SPEED=0.2
PADDING="    "
last_metadata=""

scroll_text() {
    local text="$1$PADDING"
    for ((i = 0; i < ${#text}; i++)); do
        echo "${text}"
        text="${text:1}${text:0:1}"
        sleep $SCROLL_SPEED
    done
}

get_status() {
    playerctl --player=$PLAYER status 2>/dev/null || echo "No player is running"
}

get_metadata() {
    playerctl --player=$PLAYER metadata --format "$FORMAT" 2>/dev/null
}

while true; do
    STATUS=$(get_status)

    if [[ "$STATUS" == "Stopped" || "$STATUS" == "No player is running" ]]; then
        metadata="No music is playing"
    else
        metadata=$(get_metadata)
    fi

    if [[ "$metadata" != "$last_metadata" ]]; then
        last_metadata="$metadata"
        # En lugar de reiniciar la barra, actualiza el módulo
        polybar-msg hook spotify 1 > /dev/null 2>&1
    fi

    scroll_text "$metadata"
done

