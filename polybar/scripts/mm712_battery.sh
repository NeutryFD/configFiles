#!/usr/bin/env bash

# =============================================================================
# MM712 Battery Script for Polybar
# Displays the Cooler Master MM712 battery level read through its 2.4 GHz dongle
# Requires the mm712 CLI from ~/Documents/gearbox/mm712 (make && sudo make install)
# Fonts T6 (small icon) and T7 (bold percentage) are defined in the gearbox bars
#
# Usage:
#   mm712_battery.sh           print once
#   mm712_battery.sh --tail    print every REFRESH_SECONDS; SIGUSR1 refreshes now
#   mm712_battery.sh --status  show the full mm712 status in a rofi message box
# =============================================================================

REFRESH_SECONDS=60
LOW_THRESHOLD=20
MID_THRESHOLD=50

ICON_COLOR="#8a87a6"
DIM_COLOR="#555"
HIGH_COLOR="#9ece6a"
MID_COLOR="#e0af68"
LOW_COLOR="#bd2c40"
CHARGE_COLOR="#7aa2f7"

icon() {
    printf '%%{T6}%%{F%s}%s%%{F-}%%{T-}' "$1" "$2"
}

value() {
    printf '%%{T7}%%{F%s}%s%%{F-}%%{T-}' "$1" "$2"
}

unavailable() {
    echo "$(icon "$DIM_COLOR" "󰍽") $(value "$DIM_COLOR" "$1")"
}

print_battery() {
    if ! command -v mm712 >/dev/null 2>&1; then
        unavailable "n/a"
        return
    fi

    # Exit codes: 3 dongle not found, 4 permission denied, 5 mouse asleep/off
    local status percent charging color
    if ! status=$(mm712 battery --json --timeout-ms 1000 2>/dev/null); then
        unavailable "--"
        return
    fi

    percent=$(jq -r '.battery_percent' <<<"$status")
    charging=$(jq -r '.charging' <<<"$status")

    if [[ ! "$percent" =~ ^[0-9]+$ ]]; then
        unavailable "--"
        return
    fi

    if (( percent <= LOW_THRESHOLD )); then
        color=$LOW_COLOR
    elif (( percent <= MID_THRESHOLD )); then
        color=$MID_COLOR
    else
        color=$HIGH_COLOR
    fi

    if [[ "$charging" == "true" ]]; then
        echo "$(icon "$CHARGE_COLOR" "󰍽󰂄") $(value "$CHARGE_COLOR" "${percent}%")"
    else
        echo "$(icon "$ICON_COLOR" "󰍽") $(value "$color" "${percent}%")"
    fi
}

show_status() {
    local status
    status=$(mm712 status 2>&1)
    rofi -e "MM712
${status}"
}

tail_battery() {
    trap 'kill "$sleep_pid" 2>/dev/null' USR1
    while true; do
        print_battery
        sleep "$REFRESH_SECONDS" &
        sleep_pid=$!
        wait "$sleep_pid"
    done
}

case "${1:-}" in
    --tail)   tail_battery ;;
    --status) show_status ;;
    *)        print_battery ;;
esac
