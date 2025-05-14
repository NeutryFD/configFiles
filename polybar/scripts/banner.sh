#!/bin/bash
LINUX=$(hostnamectl | grep System | awk '{print $3}')
HOSTNAME=$(hostname)

text="| 󱓞  $HOSTNAME  |  󰕈  $LINUX |    Neovim |   Stay Tiling "

while true; do
    echo "${text}"
    text="${text:1}${text:0:1}"
    sleep 0.2
done
