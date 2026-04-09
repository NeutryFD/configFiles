#!/bin/bash

# =============================================================================
# Kubectl Node Resources Script
# Show node resources (CPU/memory) in the cluster
# =============================================================================

kubectl get nodes -o custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory | \
    awk 'NR>1 {mem=$3; gsub(/[KMGi]+/, "", mem); printf "%-20s CPU: %s cores  Memory: %.1f GB\n", $1, $2, $3/1024000}'
