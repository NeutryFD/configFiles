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
    # Main kept at 1080p like the chat monitor so text matches (both 27"); 119.88 is its fastest 1080p rate
    xrandr --output "$DESKTOP_DISPLAY"        --primary --mode 1920x1080 --rate 119.88 \
           --output "$DESKTOP_SECOND_DISPLAY" --auto --rotate right --scale 1x1 --left-of "$DESKTOP_DISPLAY"

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
    xrandr --output "$DESKTOP_DISPLAY" --mode 1920x1080 --rate 119.88 --pos 0x0
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

# Pills sit 8px from the screen edges and 30px tall: windows (padding + window_gap 6) start 8px past them
bspc config top_padding    40
bspc config bottom_padding 40
bspc config left_padding   2
bspc config right_padding  2

# Launch polybar
if [ "$BAR_LAYOUT" == "vertical" ]; then
    "$HOME/.config/polybar/scripts/bspwm_desktops_daemon.sh" &

    launch_left_bar "$POLYBAR_VERTICAL_CONFIG" "$DESKTOP_DISPLAY" vbar- "$DESKTOP_COUNT"

    launch_polybar "$POLYBAR_VERTICAL_CONFIG" "" \
        top-gearbox top-privacy top-banner top-volume top-music bottom-resources bottom-vpn bottom-tunnels bottom-ethernet

    # visible bar edge 64 + 8 gap - window_gap
    bspc config left_padding 66
else
    # The Pac-Man pill fits its desktops (about 24px each); gearbox and privacy follow it 8px apart
    export BSPWM_PILL_WIDTH=$(( DESKTOP_COUNT * 24 + 44 ))
    export GEARBOX_X=$(( 4 + BSPWM_PILL_WIDTH ))
    export PRIVACY_X=$(( GEARBOX_X + 80 ))
    launch_polybar "$POLYBAR_CONFIG" "" \
        bspwm gearbox privacy banner volume music left status clock vpn tunnels ethernet
fi

# Global paddings above also apply here: override them afterwards
if [ -n "$DESKTOP_SECOND_DISPLAY" ]; then
    # Pac-Man pill in the horizontal layout, the blue desktop lines in the vertical one
    SECOND_BAR=second-bspwm
    [ "$BAR_LAYOUT" == "vertical" ] && SECOND_BAR=second-bspwm-lines
    launch_polybar "$POLYBAR_CONFIG" "$DESKTOP_SECOND_DISPLAY" "$SECOND_BAR"

    # 38px bar 8px from the bottom
    bspc config -m "$DESKTOP_SECOND_DISPLAY" top_padding    2
    bspc config -m "$DESKTOP_SECOND_DISPLAY" bottom_padding 48
    bspc config -m "$DESKTOP_SECOND_DISPLAY" left_padding   2
    bspc config -m "$DESKTOP_SECOND_DISPLAY" right_padding  2
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
