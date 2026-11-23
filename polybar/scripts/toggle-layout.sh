#!/bin/bash

# =============================================================================
# Polybar Layout Toggle
# Flips the bar layout between horizontal and vertical and restarts bspwm,
# whose bspwmrc reads ~/.cache/bar-layout and relaunches polybar.
# Only desktop mode has a vertical layout; laptop mode stays horizontal.
# =============================================================================

STATE_FILE="$HOME/.cache/bar-layout"

if [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "vertical" ]]; then
    layout="horizontal"
else
    layout="vertical"
fi

mkdir -p "$(dirname "$STATE_FILE")"
echo "$layout" > "$STATE_FILE"
bspc wm -r
