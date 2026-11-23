#!/bin/bash

# =============================================================================
# BSPWM Desktops Daemon for the vertical Polybar
# Runs a single `bspc subscribe report` and appends the icon of every desktop
# to $STATE_DIR/<monitor>-<index>, only when it changes. Each desktop slot bar
# (v-desk-N) follows its file with `tail -F`, so the slots stacked in a column
# read as a vertical bspwm module. Glyphs and colors match [module/bspwm].
# The daemon is started by bspwmrc in vertical layout mode.
#
# Usage:
#   bspwm_desktops_daemon.sh                 run the daemon
#   bspwm_desktops_daemon.sh --follow <n>    print slot <n> of $MONITOR (polybar tail = true)
#   bspwm_desktops_daemon.sh --focus <n>     focus desktop <n> of $MONITOR
#   bspwm_desktops_daemon.sh --next|--prev   focus the next/previous desktop of $MONITOR
# =============================================================================

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/polybar-desks"

# Slot files are rewritten to their last line after this many appends
MAX_LINES=200

# Same colors as [module/bspwm] and [colors]
ALERT="#bd2c40"
FOCUSED_COLOR="#FFD700"
OCCUPIED_COLOR="#96CDFB"
EMPTY_COLOR="#FFC0CB"

# Labels include the module's padding = 1 (one space on each side)
# Unlike [module/bspwm], the focused label has no background (every slot must
# draw exactly the bar background) and no underline: only the icon
FOCUSED_LABEL="%{F${FOCUSED_COLOR}}  󰮯  %{F-}"
OCCUPIED_LABEL="%{F${OCCUPIED_COLOR}}  󰊠  %{F-}"
EMPTY_LABEL="%{F${EMPTY_COLOR}}  󰧵  %{F-}"

# Last written label and line count per "<monitor>-<index>", desktops per monitor
declare -A last_label
declare -A line_count
declare -A desktop_count

# Append a label to a slot file if it changed. tail -F follows appends, and a
# rewrite to a single line is seen as a truncation, so it re-reads the file.
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

# Label for a report desktop item: same precedence as polybar,
# focused (uppercase), urgent, occupied, empty
desktop_label() {
    local state=$1 index=$2
    case "$state" in
        [FOU]) echo "$FOCUSED_LABEL" ;;
        u)     echo "%{B${ALERT}}  ${index}!  %{B-}" ;;
        o)     echo "$OCCUPIED_LABEL" ;;
        *)     echo "$EMPTY_LABEL" ;;
    esac
}

# Parse one report line: WM<mon>:o<desk>:F<desk>:...:LT:TT:G:m<mon>:...
handle_report() {
    local line=${1#W}
    local item monitor="" index=0 i
    local -a items
    IFS=':' read -ra items <<< "$line"

    for item in "${items[@]}" ""; do
        case "${item:0:1}" in
            M|m|"")
                # Close the previous monitor: blank slots of removed desktops
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
                write_slot "$monitor-$index" "$(desktop_label "${item:0:1}" "$index")"
                ;;
        esac
    done
}

run_daemon() {
    mkdir -p "$STATE_DIR"

    # Read the subscriber through a file descriptor so the trap can stop it:
    # no orphaned bspc subscribe survives a polybar restart or bspc wm -r
    exec {report_fd}< <(exec bspc subscribe report)
    subscriber_pid=$!
    trap 'kill "$subscriber_pid" 2>/dev/null; exit 0' INT TERM HUP

    while read -r -u "$report_fd" report; do
        handle_report "$report"
    done

    kill "$subscriber_pid" 2>/dev/null
}

# Follow a slot file. It is created first: tail -F only gets instant (inotify)
# updates for files that exist when it starts, otherwise it polls.
follow_slot() {
    local slot="$STATE_DIR/${MONITOR}-$1"
    mkdir -p "$STATE_DIR"
    touch "$slot"
    exec tail -n1 -F "$slot" 2>/dev/null
}

# Bars launched without MONITOR live on the primary (or focused) monitor
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
