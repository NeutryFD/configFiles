#!/bin/bash

# =============================================================================
# Volume Script for Polybar
# Gets the current volume level and mute status of the default sink
# =============================================================================

# Get default sink volume and mute status
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)
mute=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no')

# Output volume status based on mute state
if [[ "$mute" == "yes" ]]; then
    # Sink is muted - show muted status
    echo "MUTED"
else
    # Sink is active - show volume level
    echo "VOL: $volume"
fi
