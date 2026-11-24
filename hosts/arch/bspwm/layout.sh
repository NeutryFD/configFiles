#!/bin/bash

# ============================================================================
# Arch (desktop) monitor and polybar layout, sourced by bspwmrc
# ============================================================================

DESKTOP_DISPLAY="HDMI-0"

WALLPAPER_VERTICAL="$HOME/Pictures/Wallpapers/wallpaper-vertical.jpg"

POLYBAR_CONFIG="$HOME/.config/dotfiles-host/polybar/arch.conf"
POLYBAR_VERTICAL_CONFIG="$HOME/.config/dotfiles-host/polybar/arch-vertical.conf"

# Desktop polybar layout, set by polybar/scripts/toggle-layout.sh
BAR_LAYOUT=$(cat "$HOME/.cache/bar-layout" 2>/dev/null)
[ "$BAR_LAYOUT" == "vertical" ] || BAR_LAYOUT="horizontal"

# Any other connected output is the portrait chat monitor
DESKTOP_SECOND_DISPLAY=$(xrandr | awk -v main="$DESKTOP_DISPLAY" '$2 == "connected" && $1 != main { print $1; exit }')

if [ -n "$DESKTOP_SECOND_DISPLAY" ]; then
    # Portrait chat monitor on the left, without polybar
    xrandr --output "$DESKTOP_DISPLAY"        --primary --rate 60 \
           --output "$DESKTOP_SECOND_DISPLAY" --auto --rotate left --left-of "$DESKTOP_DISPLAY"

    # Move desktops beyond 8 with their windows, then drop the default "Desktop"
    while [ "$(bspc query -D -m "$DESKTOP_DISPLAY" | wc -l)" -gt 8 ]; do
        bspc desktop "$DESKTOP_DISPLAY:^9" --to-monitor "$DESKTOP_SECOND_DISPLAY"
    done
    for desk in $(bspc query -D -m "$DESKTOP_SECOND_DISPLAY"); do
        [ "$(bspc query -D -d "$desk" --names)" == "Desktop" ] && bspc desktop "$desk" -r
    done

    bspc monitor "$DESKTOP_DISPLAY"        -d 1 2 3 4 5 6 7 8
    bspc monitor "$DESKTOP_SECOND_DISPLAY" -d 9 10
    bspc wm --reorder-monitors "$DESKTOP_SECOND_DISPLAY" "$DESKTOP_DISPLAY"
    DESKTOP_COUNT=8
else
    xrandr --output "$DESKTOP_DISPLAY" --rate 60
    bspc monitor "$DESKTOP_DISPLAY" -d 1 2 3 4 5 6 7 8 9 10
    DESKTOP_COUNT=10

    # Migrate windows from disconnected monitors, then remove them
    for mon in $(bspc query -M --names); do
        [ "$mon" == "$DESKTOP_DISPLAY" ] && continue
        for wid in $(bspc query -N -m "$mon" -n .window); do
            CURRENT_DESKTOP=$(bspc query -D -n "$wid" --names)
            bspc node "$wid" -d "$DESKTOP_DISPLAY:^$CURRENT_DESKTOP" \
                || bspc node "$wid" -d "$DESKTOP_DISPLAY:focused"
        done
        [ -z "$(bspc query -N -m "$mon" -n .window)" ] && bspc monitor "$mon" -r
    done
fi

# Launch polybar
if [ "$BAR_LAYOUT" == "vertical" ]; then
    "$HOME/.config/polybar/scripts/bspwm_desktops_daemon.sh" &

    launch_left_bar "$POLYBAR_VERTICAL_CONFIG" "$DESKTOP_DISPLAY" vbar- "$DESKTOP_COUNT"

    launch_polybar "$POLYBAR_VERTICAL_CONFIG" "" \
        top-gearbox top-privacy top-banner top-volume top-music bottom-resources bottom-vpn bottom-ethernet

    # visible bar edge 64 + 8 gap - window_gap
    bspc config left_padding 66
else
    launch_polybar "$POLYBAR_CONFIG" "" \
        left banner ethernet bspwm right music tray vpn gearbox privacy
fi

# Global paddings above also apply here: override them afterwards
if [ -n "$DESKTOP_SECOND_DISPLAY" ]; then
    launch_polybar "$POLYBAR_CONFIG" "$DESKTOP_SECOND_DISPLAY" second-bspwm

    bspc config -m "$DESKTOP_SECOND_DISPLAY" top_padding    8
    bspc config -m "$DESKTOP_SECOND_DISPLAY" bottom_padding 42
    bspc config -m "$DESKTOP_SECOND_DISPLAY" left_padding   8
    bspc config -m "$DESKTOP_SECOND_DISPLAY" right_padding  8
fi

# Set wallpaper: feh takes one image per Xinerama screen, in --listactivemonitors order
if [ -n "$DESKTOP_SECOND_DISPLAY" ] && [ -f "$WALLPAPER_VERTICAL" ]; then
    WALLPAPERS=()
    for mon in $(xrandr --listactivemonitors | awk 'NR > 1 { print $NF }'); do
        if [ "$mon" == "$DESKTOP_SECOND_DISPLAY" ]; then
            WALLPAPERS+=("$WALLPAPER_VERTICAL")
        else
            WALLPAPERS+=("$WALLPAPER")
        fi
    done
    feh --bg-fill "${WALLPAPERS[@]}"
else
    feh --bg-fill "$WALLPAPER"
fi
WALLPAPER_SET=true
