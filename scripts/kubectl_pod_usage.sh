#!/bin/bash

# Show pod resource usage (CPU/memory) in a namespace
# Usage: kubectl_pod_usage <namespace> [label_selector]

namespace="$1"
label_selector="$2"

if [[ -z "$namespace" ]]; then
    echo "Usage: kubectl_pod_usage <namespace> [label_selector]"
    exit 1
fi

metrics_url="/apis/metrics.k8s.io/v1beta1/namespaces/$namespace/pods"
[[ -n "$label_selector" ]] && metrics_url="$metrics_url?labelSelector=$label_selector"

echo -e "POD_NAME\tCPU_USAGE\tMEMORY_USAGE"
echo -e "--------\t---------\t------------"
kubectl get --raw "$metrics_url" | jq -r '
  .items[] |
  (.containers[0].usage.cpu // "0") as $cpu |
  (.containers[0].usage.memory // "0") as $mem |
  ($cpu | gsub("n$"; "") | tonumber / 1000000000) as $cpu_cores |
  ($mem | gsub("Ki$"; "") | tonumber / 1048576) as $mem_gb |
  "\(.metadata.name)\t\($cpu_cores | . * 1000 | round / 1000) cpu\t\($mem_gb | . * 100 | round / 100) GB"
' | column -t | head -15
