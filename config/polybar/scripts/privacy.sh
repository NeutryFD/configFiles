#!/bin/bash

# =============================================================================
# Privacy indicator for Polybar
# Shows whether the microphone or the camera is in use, and by which apps
# =============================================================================
# Usage: privacy.sh           - tail mode: print the icons whenever they change
#        privacy.sh --notify  - notification with the apps using them (click)

INTERVAL=2

MIC_ICON="󰍬"
MIC_OFF_ICON="󰍭"
CAM_ICON="󰄀"
# the slashed camera-off glyph looks clipped in the bar: grey camera instead
CAM_OFF_ICON="$CAM_ICON"

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/colors.sh"

# Apps recording from a PulseAudio/PipeWire source, one per line
# Monitor sources only capture playback (visualizers, screen recorders), not the mic
mic_apps() {
    local monitors
    monitors=$(pactl list short sources 2>/dev/null | awk '$2 ~ /\.monitor$/ { print $1 }')
    pactl list source-outputs 2>/dev/null | awk -v monitors=" ${monitors//$'\n'/ } " '
        /^Source Output #/ { if (name != "" && !mon) print name; name = ""; mon = 0 }
        /^[[:space:]]*Source: / { if (index(monitors, " " $2 " ")) mon = 1 }
        /application.name = / && name == "" { sub(/.*application.name = "/, ""); sub(/"$/, ""); name = $0 }
        /application.process.binary = / && name == "" { sub(/.*binary = "/, ""); sub(/"$/, ""); name = $0 }
        END { if (name != "" && !mon) print name }
    ' | sort -u
}

# Processes holding a video device open, one per line
cam_apps() {
    local pid
    for pid in $(fuser /dev/video* 2>/dev/null); do
        ps -o comm= -p "$pid"
    done | sort -u
}

render() {
    local mic cam
    if [[ -n "$(mic_apps)" ]]; then
        mic="%{F${COLOR_ALERT}}${MIC_ICON}%{F-}"
    else
        mic="%{F${COLOR_SUBTLE}}${MIC_OFF_ICON}%{F-}"
    fi
    if [[ -n "$(cam_apps)" ]]; then
        cam="%{F${COLOR_ALERT}}${CAM_ICON}%{F-}"
    else
        cam="%{F${COLOR_SUBTLE}}${CAM_OFF_ICON}%{F-}"
    fi
    # %{O8}: the icons overhang their advance; the trailing one keeps the camera from being clipped
    echo "${mic}%{O8}${cam}%{O8}"
}

# Apps using the mic and the camera: "<mic> app, app   <cam> app"
summary() {
    local mic cam
    mic=$(mic_apps | sed 's/ input$//' | paste -sd ',' | sed 's/,/, /g')
    cam=$(cam_apps | paste -sd ',' | sed 's/,/, /g')
    printf '%s %s   %s %s' "$MIC_ICON" "${mic:-off}" "$CAM_ICON" "${cam:-off}"
}

# One-line notification; the stack tag replaces the previous one instead of piling up
notify() {
    notify-send -a privacy -t 4000 -h string:x-dunst-stack-tag:privacy "$(summary)"
}

case "${1:-}" in
    "")
        last=""
        while true; do
            line=$(render)
            [[ "$line" != "$last" ]] && echo "$line" && last=$line
            sleep "$INTERVAL"
        done
        ;;
    --notify) notify ;;
    *)
        echo "Usage: $0 [--notify]" >&2
        exit 1
        ;;
esac
