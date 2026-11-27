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
    # Main at its native 1440p, chat monitor at 1080p (both 27"): HDMI-0 sizes are the 1080p ones x4/3
    xrandr --output "$DESKTOP_DISPLAY"        --primary --mode 2560x1440 --rate 144 \
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
    xrandr --output "$DESKTOP_DISPLAY" --mode 2560x1440 --rate 144 --pos 0x0
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

# Pills sit 10px from the screen edges and 40px tall: windows (padding + window_gap 6) start 11px past them
bspc config top_padding    55
bspc config bottom_padding 55
bspc config left_padding   2
bspc config right_padding  2

# privacy.sh icon offset and the sxhkdrc slot machine font, x4/3
export PRIVACY_ICON_GAP=11
export GHOSTTY_SLOT_FONT_SIZE=20
export GHOSTTY_CMD="$HOME/.config/dotfiles-host/ghostty-launch.sh"
export GHOSTTY_FLOAT_RECT=960x480+0+0 GHOSTTY_FLOAT_CENTER=on

# Launch polybar
if [ "$BAR_LAYOUT" == "vertical" ]; then
    "$HOME/.config/polybar/scripts/bspwm_desktops_daemon.sh" &

    # config/polybar/vertical.conf sizes x4/3; stacked segments keep touching
    export VBAR_WIDTH=80 VBAR_SLOT=40 VBAR_X=11 VBAR_RADIUS=13
    export VBAR_TOP_Y=5 VBAR_TOP_H=14 VBAR_KBD_Y=19 VBAR_DISK_Y=48 VBAR_ROW_H=29 VBAR_UPPER_Y=77
    export VBAR_DAY_Y=100%:-184 VBAR_MONTH_Y=100%:-152 VBAR_SEP_Y=100%:-120 VBAR_HOUR_Y=100%:-101
    export VBAR_MIN_Y=100%:-69 VBAR_BOTTOM_Y=100%:-37 VBAR_CLOCK_H=32 VBAR_SEP_H=19
    export VBAR_FONT_5="Hack Nerd Font Propo:style=Bold:pixelsize=28;7"
    export VBAR_FONT_6="Hack Nerd Font Propo:style=Regular:pixelsize=19;4"
    export VBAR_FONT_7="Hack Nerd Font Propo:style=Regular:pixelsize=21;5"
    export VBAR_FONT_8="Droid Sans:style=Regular:pixelsize=20;5"
    export VBAR_FONT_9="fixed:pixelsize=13;4"
    export VBAR_FONT_10="fixed:pixelsize=13;3"
    export VBAR_FONT_11="Hack Nerd Font Propo:style=Regular:pixelsize=13;4"

    launch_left_bar "$POLYBAR_VERTICAL_CONFIG" "$DESKTOP_DISPLAY" vbar- "$DESKTOP_COUNT"

    launch_polybar "$POLYBAR_VERTICAL_CONFIG" "" \
        top-gearbox top-privacy top-banner top-volume top-music bottom-resources bottom-vpn bottom-tunnels bottom-ethernet

    # visible bar edge 86 + 10 gap - window_gap
    bspc config left_padding 90
else
    # The Pac-Man pill fits its desktops (about 32px each); gearbox and privacy follow it 10px apart
    export BSPWM_PILL_WIDTH=$(( DESKTOP_COUNT * 32 + 59 ))
    export GEARBOX_X=$(( 5 + BSPWM_PILL_WIDTH ))
    export PRIVACY_X=$(( GEARBOX_X + 107 ))
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
