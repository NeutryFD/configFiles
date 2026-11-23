#!/bin/bash

# Reload bspwm (bspc wm -r re-runs bspwmrc) when the set of connected outputs changes

SETTLE_SECONDS=${SETTLE_SECONDS:-1.5}
FIFO="${XDG_RUNTIME_DIR:-/tmp}/monitor-hotplug.$$"

connected_outputs() {
    xrandr --query | awk '$2 == "connected" { print $1 }' | sort | tr '\n' ' '
}

cleanup() {
    kill "${producers[@]}" 2>/dev/null
    rm -f "$FIFO"
}

rm -f "$FIFO"
mkfifo "$FIFO" || exit 1
trap 'cleanup; exit 0' INT TERM HUP

# udev reports raw plugs, bspwm only outputs that are already enabled
producers=()
udevadm monitor --udev --subsystem-match=drm > "$FIFO" 2>/dev/null &
producers+=($!)
bspc subscribe monitor_add monitor_remove monitor_geometry > "$FIFO" &
producers+=($!)
exec {events_fd}< "$FIFO"

applied=$(connected_outputs)

while read -r -u "$events_fd" event; do
    case "$event" in
        UDEV*\[*|monitor_*) ;;
        *) continue ;;
    esac

    # Wait for the burst of events to settle
    while read -r -t "$SETTLE_SECONDS" -u "$events_fd" _; do :; done

    # bspwmrc's own xrandr calls only fire events, the connected set stays the same
    [[ "$(connected_outputs)" == "$applied" ]] && continue

    # bspwmrc starts a fresh watcher
    bspc wm -r
    break
done

cleanup
