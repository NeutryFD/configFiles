#!/bin/bash

for iface in $(ip -o link show | awk -F': ' '$2 ~ /^(eth|ether|en|enx|usb|rndis)/ {print $2}'); do
    ip=$(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -n "$ip" ]; then
        echo "󰌗 : $ip"
        exit 0
    fi
done
echo "No connected"
