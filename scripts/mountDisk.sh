#!/bin/bash

# =============================================================================
# Mount Disk Script
# Mount virtual machines disk by UUID
# =============================================================================

DISK_UUID="56fa5147-4b24-47c2-a165-d61cc18dd92d"
MOUNT_POINT="/virtualMachines"

if lsblk -o UUID | grep -q "$DISK_UUID"; then
    mount --uuid "$DISK_UUID" "$MOUNT_POINT"
    chown -R neutry:neutry "$MOUNT_POINT"
    echo "Mounted disk at $MOUNT_POINT"
else
    echo "Disk not found"
fi
