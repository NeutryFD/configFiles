#!/bin/bash

# =============================================================================
# Set Audio Card Script
# Set default audio output to G435 Wireless Gaming Headset
# =============================================================================

HEADSET_NAME="G435 Wireless Gaming Headset"

id=$(alsactl info | grep -B 2 "name: $HEADSET_NAME" | grep card | cut -d " " -f 3)

if [[ -n "$id" ]]; then
    echo -e "defaults.pcm.card $id\ndefaults.ctl.card $id" > /etc/asound.conf
    alsactl restore
    echo "Audio card set to: $HEADSET_NAME (card $id)"
else
    echo "Audio card not found: $HEADSET_NAME"
fi
