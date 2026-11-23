#!/bin/bash

# Single bspc subscriber that writes one desktop indicator per vertical bar slot

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/polybar-desks"

MAX_LINES=200

ALERT="#bd2c40"
FOCUSED_COLOR="#7aa2f7"
OCCUPIED_COLOR="#6b6880"
EMPTY_COLOR="#38354c"

CAPSULE="⏽"
FOCUSED_LABEL="%{T6}%{F${FOCUSED_COLOR}}${CAPSULE}%{F-}%{T-}"
URGENT_LABEL="%{T6}%{F${ALERT}}${CAPSULE}%{F-}%{T-}"
OCCUPIED_LABEL="%{T7}%{F${OCCUPIED_COLOR}}${CAPSULE}%{F-}%{T-}"
EMPTY_LABEL="%{T8}%{F${EMPTY_COLOR}}•%{F-}%{T-}"

declare -A last_label
declare -A line_count
declare -A desktop_count

# tail -F misses same-size rewrites and renames: append, and truncate to rotate
write_slot() {
    local slot=$1 label=$2
    [[ "${last_label[$slot]-unset}" == "$label" ]] && return
    last_label[$slot]=$label

    if (( ${line_count[$slot]:-0} >= MAX_LINES )); then
        printf '%s\n' "$label" > "$STATE_DIR/$slot"
        line_count[$slot]=1
    else
        printf '%s\n' "$label" >> "$STATE_DIR/$slot"
        line_count[$slot]=$(( ${line_count[$slot]:-0} + 1 ))
    fi
}

desktop_label() {
    case "$1" in
        [FOU]) echo "$FOCUSED_LABEL" ;;
        u)     echo "$URGENT_LABEL" ;;
        o)     echo "$OCCUPIED_LABEL" ;;
        *)     echo "$EMPTY_LABEL" ;;
    esac
}

# Report line: WM<mon>:o<desk>:F<desk>:...:LT:TT:G:m<mon>:...
handle_report() {
    local line=${1#W}
    local item monitor="" index=0 i
    local -a items
    IFS=':' read -ra items <<< "$line"

    for item in "${items[@]}" ""; do
        case "${item:0:1}" in
            M|m|"")
                if [[ -n "$monitor" ]]; then
                    for ((i = index + 1; i <= ${desktop_count[$monitor]:-0}; i++)); do
                        write_slot "$monitor-$i" ""
                    done
                    desktop_count[$monitor]=$index
                fi
                monitor=${item:1}
                index=0
                ;;
            [fFoOuU])
                index=$((index + 1))
                write_slot "$monitor-$index" "$(desktop_label "${item:0:1}")"
                ;;
        esac
    done
}

run_daemon() {
    mkdir -p "$STATE_DIR"

    # fd + trap so no orphaned bspc subscribe survives a restart
    exec {report_fd}< <(exec bspc subscribe report)
    subscriber_pid=$!
    trap 'kill "$subscriber_pid" 2>/dev/null; exit 0' INT TERM HUP

    while read -r -u "$report_fd" report; do
        handle_report "$report"
    done

    kill "$subscriber_pid" 2>/dev/null
}

# tail -F only uses inotify for files that exist when it starts
follow_slot() {
    local slot="$STATE_DIR/${MONITOR}-$1"
    mkdir -p "$STATE_DIR"
    touch "$slot"
    exec tail -n1 -F "$slot" 2>/dev/null
}

monitor_name() {
    echo "${MONITOR:-$(bspc query -M -m primary --names 2>/dev/null || bspc query -M -m focused --names)}"
}

case "${1:-}" in
    "")       run_daemon ;;
    --follow) MONITOR=$(monitor_name) follow_slot "${2:?slot index required}" ;;
    --focus)  bspc desktop -f "$(monitor_name):^${2:?desktop index required}" ;;
    --next)   bspc desktop -f "$(monitor_name):focused#next.local" ;;
    --prev)   bspc desktop -f "$(monitor_name):focused#prev.local" ;;
    *)
        echo "Usage: $0 [--follow <n>|--focus <n>|--next|--prev]" >&2
        exit 1
        ;;
esac
