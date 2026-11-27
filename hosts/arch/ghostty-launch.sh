#!/bin/bash
# Ghostty with the 1080p font size when opened on the portrait monitor
args=()
[ "$(bspc query -M -m focused)" != "$(bspc query -M -m primary)" ] && args=(--font-size=10)
exec ghostty "${args[@]}" "$@"
