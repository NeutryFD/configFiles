#!/bin/bash

# =============================================================================
# Clean Clipboard Script
# Clean clipboard and restart bspwm
# =============================================================================
ID=$(id -u)
rm -rf /run/user/$ID/clipmenu*
pgrep -f clipmenu | xargs -r kill >/dev/null
bspc wm -r
echo "Clipboard cleaned"
