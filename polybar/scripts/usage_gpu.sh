#!/bin/sh

# =============================================================================
# GPU Usage Script for Polybar
# Displays NVIDIA GPU memory usage
# =============================================================================

# Get GPU memory usage and total from nvidia-smi
MEMORY_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
MEMORY_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)

# Output GPU memory usage in GB format
awk -v x="$MEMORY_USED" 'BEGIN { printf "   %.1fGB", (x/1024) }'
