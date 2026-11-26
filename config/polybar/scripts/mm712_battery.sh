#!/usr/bin/env bash

# =============================================================================
# Mouse Battery Script for Polybar
# Displays the battery level of the first mouse that answers through its 2.4 GHz dongle:
# Cooler Master MM712 (mm712 CLI), then Attack Shark X8 SE (x8se CLI)
# Requires the CLIs from the gearbox repo (make && sudo make install in each tool)
# Fonts T6 (small icon) and T7 (bold percentage) are defined in the gearbox bars
#
# Usage:
#   mm712_battery.sh           print once
#   mm712_battery.sh --tail    print every REFRESH_SECONDS; SIGUSR1 refreshes now
#   mm712_battery.sh --status  show the full mouse status in a rofi message box
# =============================================================================

REFRESH_SECONDS=60
LOW_THRESHOLD=20
MID_THRESHOLD=50

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/colors.sh"

ICON_COLOR=$COLOR_ICON
DIM_COLOR=$COLOR_FOREGROUND_ALT
HIGH_COLOR=$COLOR_OK
MID_COLOR=$COLOR_WARN
LOW_COLOR=$COLOR_ALERT
CHARGE_COLOR=$COLOR_ACCENT

icon() {
    printf '%%{T6}%%{F%s}%s%%{F-}%%{T-}' "$1" "$2"
}

value() {
    printf '%%{T7}%%{F%s}%s%%{F-}%%{T-}' "$1" "$2"
}

unavailable() {
    echo "$(icon "$DIM_COLOR" "󰍽") $(value "$DIM_COLOR" "$1")"
}

# Mouse CLIs in priority order, each with its battery timeout (the X8 SE reports every ~2s)
MICE=("mm712:1000" "x8se:5000")

installed_mice() {
    local entry
    for entry in "${MICE[@]}"; do
        command -v "${entry%%:*}" >/dev/null 2>&1 && echo "$entry"
    done
}

# Prints the JSON battery status of the first mouse that answers
# Exit codes of the CLIs: 3 dongle not found, 4 permission denied, 5 mouse asleep/off
read_battery() {
    local entry
    for entry in $(installed_mice); do
        "${entry%%:*}" battery --json --timeout-ms "${entry#*:}" 2>/dev/null && return
    done
    return 1
}

print_battery() {
    if [[ -z "$(installed_mice)" ]]; then
        unavailable "n/a"
        return
    fi

    local status percent charging color
    if ! status=$(read_battery); then
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
    local entry tool status
    for entry in $(installed_mice); do
        tool=${entry%%:*}
        if status=$("$tool" status --timeout-ms "${entry#*:}" 2>&1); then
            rofi -e "${tool^^}
${status}"
            return
        fi
    done
    rofi -e "No mouse answered
${status:-mm712 and x8se are not installed}"
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
