#!/bin/bash

text="| 󱓞  Neutry  |    Arch Linux |    Neovim |   Stay Tiling "

while true; do
    echo "${text}"
    text="${text:1}${text:0:1}"
    sleep 0.2
done

