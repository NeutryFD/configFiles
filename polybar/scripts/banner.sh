#!/bin/bash
LINUX=$(hostnamectl hostname)
USER=$(echo $USER)

ARCH_ICON=󰣇
UBUNTU_ICON=󰕈

if [ $LINUX == "archlinux" ]; then

	ICON=$ARCH_ICON
fi

text="| 󱓞  $USER  | $ICON  $LINUX |    Neovim |   Stay Tiling "

while true; do
    echo "${text}"
    text="${text:1}${text:0:1}"
    sleep 0.2
done
