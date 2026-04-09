#!/bin/bash

# =============================================================================
# Clean Clipboard Script
# Clean clipboard and restart bspwm
# =============================================================================

rm -rf /run/user/1000/clipmenu*
pgrep -f clipmenu | xargs -r kill >/dev/null
bspc wm -r
echo "Clipboard cleaned"
