#!/bin/bash

# Get default sink volume
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)
mute=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'yes|no')

if [ "$mute" = "yes" ]; then
    echo " MUTED"
else
    echo "VOL: $volume"
fi
