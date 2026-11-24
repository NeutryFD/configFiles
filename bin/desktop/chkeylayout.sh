#!/bin/bash

# =============================================================================
# Change Keyboard Layout Script
# Toggle between US and ES keyboard layouts
# =============================================================================

currentLayout=$(setxkbmap -query | awk '/layout/ {print $2}')

case "$currentLayout" in
    us)
        setxkbmap es
        echo "es"
        ;;
    es)
        setxkbmap us
        echo "us"
        ;;
esac
