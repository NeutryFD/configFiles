#!/bin/bash

# Toggle the desktop polybar layout (horizontal/vertical) and restart bspwm

STATE_FILE="$HOME/.cache/bar-layout"

if [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "vertical" ]]; then
    layout="horizontal"
else
    layout="vertical"
fi

mkdir -p "$(dirname "$STATE_FILE")"
echo "$layout" > "$STATE_FILE"
bspc wm -r
