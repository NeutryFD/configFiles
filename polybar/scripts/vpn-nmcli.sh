#!/usr/bin/env bash

get_vpn_info() {
    for iface in tun tap wireguard ppp; do
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
    
    for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
        case "$iface" in
            tun*|tap*|wg*|ppp*)
                if ip link show "$iface" 2>/dev/null | grep -q "state UNKNOWN\|state UP"; then
                    VPN_IP=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d '/' -f1)
                    if [[ -n "$VPN_IP" ]]; then
                        echo "$iface ($VPN_IP)"
                        return 0
                    fi
                fi
                ;;
        esac
    done
    
    echo "Disconnected"
    return 1
}

get_vpn_info
