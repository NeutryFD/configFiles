#!/bin/bash

# =============================================================================
# SSHFS Local Mount Script
# Mount remote filesystem via SSHFS and cd into it
# Usage: sshfslocal.sh <host> [dir]
# =============================================================================

host="$1"
dir="${2:-$HOME/remoteDir}"

mkdir -p "$dir"
sshfs -o idmap=user "$host" "$dir" && cd "$dir"
