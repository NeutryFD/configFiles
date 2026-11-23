#!/bin/bash
# Reload every running polybar bar after editing its config.
# Bars are started by bspwmrc (launch_polybar). To add or remove a bar,
# edit the launch_polybar lines in hosts/<host>/bspwm/layout.sh and reload bspwm: bspc wm -r
polybar-msg cmd restart
