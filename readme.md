# Desktop Configuration Files

This repository contains configuration files and scripts for my Linux desktop environment. These configurations provide a cohesive and efficient workflow with a focus on productivity and aesthetics.

## Overview

```
.
├── betterlockscreen
│   └── betterlockscreenrc
├── bspwm
│   └── bspwmrc
├── ghosty
│   ├── config
│   └── gtk-4.0
│       └── gtk.css
├── ignite.sh        # Work In Progress (WIP)
├── kitty
│   ├── color.ini
│   └── kitty.conf
├── nvim
│   ├── init.lua
│   ├── install-plugins.sh
│   ├── lua
│   │   └── config
│   │       └── statusline.lua
│   └── nvim-dev
│       ├── init.lua
│       └── lua
│           └── config
│               └── statusline.lua
├── picom
│   └── picom.conf
├── polybar
│   ├── arch.conf
│   ├── launch.sh
│   ├── scripts
│   │   ├── banner.sh
│   │   ├── spotify_status.sh
│   │   ├── usage_gpu.sh
│   │   ├── volume.sh
│   │   └── vpn-nmcli.sh
│   ├── thinkpad.conf
│   └── thinkpad-II.conf
├── readme.md
├── rofi
│   ├── config.rasi
│   └── squared-theme.rasi
├── scripts
│   ├── chkeylayout
│   ├── mountDisk
│   └── setAudioCard
├── sxhkd
│   ├── sxhkdrc
│   └── sxhkdrc.txt
├── tmux
│   └── .tmux.conf
└── zsh
    └── .zshrc
```

## Components

### Core System

- **Window Manager:** [bspwm](https://github.com/baskerville/bspwm) - A tiling window manager that represents windows as the leaves of a binary tree
- **Hotkey Daemon:** [sxhkd](https://github.com/baskerville/sxhkd) - Simple X hotkey daemon for mapping keyboard shortcuts
- **Compositor:** [Picom](https://github.com/yshui/picom) - A lightweight compositor for X11 (provides transparency and other visual effects)
- **Task Bar:** [Polybar](https://github.com/polybar/polybar) - A fast and easy-to-use status bar
- **Application Launcher:** [Rofi](https://github.com/davatorium/rofi) - A window switcher, run dialog, and dmenu replacement

### Terminals & Shell

- **Terminal Emulators:** 
  - [Kitty](https://sw.kovidgoyal.net/kitty/) - A fast, feature-rich, GPU-based terminal emulator
  - [Ghostty](https://ghostty.org/) - Modern GPU-accelerated terminal emulator
- **Shell:** [Zsh](https://sourceforge.net/projects/zsh/) with Oh-My-Zsh framework
- **Terminal Multiplexer:** [Tmux](https://github.com/tmux/tmux) - Terminal session manager

### Screen

- **Lock Screen:** [Betterlockscreen](https://github.com/betterlockscreen/betterlockscreen) - A clean and customizable lock screen

### Editor

- **Text Editor:** [Neovim](https://neovim.io/) - Hyperextensible Vim-based text editor
  - **Plugins:**
    - [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - Completion engine
    - [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) - LSP source for nvim-cmp
    - [cmp-buffer](https://github.com/hrsh7th/cmp-buffer) - Buffer completions
    - [cmp-path](https://github.com/hrsh7th/cmp-path) - Path completions
    - [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline) - Command line completions
    - [LuaSnip](https://github.com/L3MON4D3/LuaSnip) - Snippet engine
    - [cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) - Luasnip completion source
    - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
    - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Lua functions library
    - [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) - File explorer
    - [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) - File icons
    - [catppuccin](https://github.com/catppuccin/nvim) - Soothing pastel theme
    - [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) - Clean, dark theme
    - [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) - Indentation guides

## TODO Installation

The repository includes an `ignite.sh` script (Work In Progress) to help install and configure various components. When completed, this script will:
- Handle dependency installation
- Create symbolic links to configuration files
- Set up the environment
