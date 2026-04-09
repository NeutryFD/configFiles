#!/bin/bash

# =============================================================================
# Banner Script for Polybar
# Displays system information: user, OS, and tiling status
# =============================================================================

# Get system hostname and current user
HOSTNAME=$(hostnamectl hostname)
USER="$USER"

# OS icons based on hostname
case "$HOSTNAME" in
    archlinux) ICON="󰣇" ;;
    *)         ICON="󰕈" ;;
esac

# Banner text to display (with icons)
text="| 󱓞  $USER  | $ICON  $HOSTNAME |    Neovim |   Stay Tiling "

# Main loop - scroll banner text horizontally
while true; do
    echo "$text"
    text="${text:1}${text:0:1}"
    sleep 0.2
done
