#!/usr/bin/env bash

# =============================================================================
# VPN Status Script for Polybar
# Shows the active vpn.sh clients, or their sshuttle tunnels with --tunnels
# Falls back to vpn-nmcli.sh / pgrep when vpn.sh or jq is missing
#
# Usage:
#   vpn-status.sh            VPN pill: active clients
#   vpn-status.sh --tunnels  tunnel pill: active sshuttle tunnels
#   vpn-status.sh --status   show `vpn status` in a rofi message box
# =============================================================================

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
VPN="${DOTFILES:-$HOME/dotfiles}/bin/network/vpn.sh"

source "$SCRIPT_DIR/colors.sh"

VPN_COLOR=$COLOR_OK
TUNNEL_COLOR=$COLOR_OK
DIM_COLOR=$COLOR_FOREGROUND_ALT
VPN_ICON="󰖂"
TUNNEL_ICON="󱠽"

mode=vpn
case "${1:-}" in
    --tunnels) mode=tunnels ;;
    --status)
        rofi -e "$("$VPN" status 2>&1)"
        exit 0
        ;;
esac

# %{O6}: the icon overhangs its advance
pill() {
    echo "%{F$1}$2%{F-}%{O6} $3"
}

off() {
    echo "%{F${DIM_COLOR}}$1%{O6} off%{F-}"
}

# Single item by name, several as "first +N"
names() {
    if (( $# == 1 )); then
        echo "$1"
    else
        echo "$1 +$(( $# - 1 ))"
    fi
}

fallback() {
    if [[ "$mode" == vpn ]]; then
        exec "$SCRIPT_DIR/vpn-nmcli.sh" --icons
    fi
    local count
    count=$(pgrep -ax sshuttle | grep -vc -- '--firewall')
    if (( count > 0 )); then
        pill "$TUNNEL_COLOR" "$TUNNEL_ICON" "$count"
    else
        off "$TUNNEL_ICON"
    fi
    exit 0
}

if [[ ! -x "$VPN" ]] || ! command -v jq >/dev/null 2>&1; then
    fallback
fi

json=$("$VPN" status --json 2>/dev/null) || fallback

if [[ "$mode" == vpn ]]; then
    # Interfaces only when no known VPN process is up (e.g. a manual wg-quick)
    mapfile -t items < <(jq -r '
        ([.clients[] | select(.vpn.up) | .name] + [.unmanaged.vpns[] | .iface // .type]) as $vpns
        | if ($vpns | length) > 0 then $vpns[] else (.interfaces[] | select(.up) | .name) end' <<<"$json")
    icon=$VPN_ICON color=$VPN_COLOR
else
    # Outer tunnels first, so a nested pair reads "outer +1"
    mapfile -t items < <(jq -r '
        ([.clients[] | .tunnels[] | select(.up)] | sort_by(.nested_in != null) | .[].name),
        (.unmanaged.tunnels[] | .remote // "sshuttle")' <<<"$json")
    icon=$TUNNEL_ICON color=$TUNNEL_COLOR
fi

if (( ${#items[@]} == 0 )); then
    off "$icon"
else
    pill "$color" "$icon" "$(names "${items[@]}")"
fi
