#!/usr/bin/env bash

# =============================================================================
# VPN Status Script for Polybar
# Detects active VPN connections by checking network interface states
# Supports: tun, tap, wireguard, ppp interfaces
# =============================================================================

VPN_INTERFACES="tun tap wireguard ppp"

# Get VPN information by checking interface states
get_vpn_info() {
    # First, check common numbered interfaces (tun0, tun1, etc.)
    for iface in $VPN_INTERFACES; do
        for num in 0 1 2 3 4 5 6 7 8 9; do
            if ip link show "${iface}${num}" 2>/dev/null | grep -q "state UNKNOWN\|state UP"; then
                VPN_IP=$(ip addr show "${iface}${num}" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d '/' -f1)
                if [[ -n "$VPN_IP" ]]; then
                    echo "${iface^^}${num} ($VPN_IP)"
                    return 0
                fi
            fi
        done
    done
    
    # Fallback: check all interfaces matching VPN patterns
    for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
        for vpn_iface in $VPN_INTERFACES; do
            if [[ "$iface" == "$vpn_iface"* ]]; then
                if ip link show "$iface" 2>/dev/null | grep -q "state UNKNOWN\|state UP"; then
                    VPN_IP=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d '/' -f1)
                    if [[ -n "$VPN_IP" ]]; then
                        echo "$iface ($VPN_IP)"
                        return 0
                    fi
                fi
            fi
        done
    done
    
    echo "Disconnected"
    return 1
}

get_vpn_info
