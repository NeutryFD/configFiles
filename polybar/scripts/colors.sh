#!/bin/bash

# Source to load polybar/colors.conf [colors] as COLOR_<NAME> (foreground-alt -> COLOR_FOREGROUND_ALT)

while read -r key value; do
    key=${key//-/_}
    printf -v "COLOR_${key^^}" '%s' "$value"
done < <(awk -F'=' '
    /^\[/ { in_colors = ($0 == "[colors]"); next }
    in_colors && /^[a-z]/ && NF == 2 { gsub(/[ \t]/, ""); print $1, $2 }
' "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../colors.conf")
