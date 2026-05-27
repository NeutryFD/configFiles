#!/bin/bash

DNS_SERVER="192.168.1.110"
DNS_MAC="bc:24:11:a4:1d:14"

if ping -c 1 "$DNS_SERVER" > /dev/null 2>&1; then
    echo "DNS: Using $DNS_SERVER"
    printf "nameserver %s\noptions edns0 trust-ad\nsearch home\n" "$DNS_SERVER" \
      | sudo tee /etc/resolv.conf > /dev/null
else
    echo "DNS: $DNS_SERVER unreachable, falling back to 127.0.0.1"
    printf "nameserver %s\noptions edns0 trust-ad\nsearch home\n" "127.0.0.1" \
      | sudo tee /etc/resolv.conf > /dev/null
fi
