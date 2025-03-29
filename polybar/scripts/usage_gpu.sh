#!/bin/sh

memory_total=16376
memory_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
awk -v x="$memory_used" -v y="$memory_total" 'BEGIN { printf "GPU %.1f%",(x / y) * 100 }'
