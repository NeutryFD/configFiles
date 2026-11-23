# 🖥️ Desktop Configuration Files
> Personal Linux desktop environment configs with bspwm, polybar, zsh, and more.
---
## 📁 Directory Structure
```
dotfiles/
├── install.sh      # Bootstrap installer (symlinks + packages)
├── config/         # Linked into ~/.config (bspwm, polybar, sxhkd, nvim, kitty, ...)
├── home/           # Linked into ~ (.zshrc, .tmux.conf, zsh helpers & theme)
├── bin/            # Utility scripts (on PATH)
├── hosts/
│   ├── arch/       # Desktop: bspwm layout & polybar bars
│   └── thinkpad/   # Laptop: bspwm layout & polybar bars
└── README.md       # This file
```
---
## Core System
| Tool | Description |
|------|-------------|
| [bspwm](https://github.com/baskerville/bspwm) | Tiling window manager |
| [sxhkd](https://github.com/baskerville/sxhkd) | Hotkey daemon |
| [Picom](https://github.com/yshui/picom) | Compositor (transparency) |
| [Polybar](https://github.com/polybar/polybar) | Status bar |
| [Rofi](https://github.com/davatorium/rofi) | App launcher |
## Terminal & Shell
| Tool | Description |
|------|-------------|
| [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU terminal |
| [Ghostty](https://ghostty.org/) | Modern terminal |
| [Zsh](https://sourceforge.net/projects/zsh/) + Oh-My-Zsh | Shell |
| [Tmux](https://github.com/tmux/tmux) | Multiplexer |
## Editor
| Tool | Description |
|------|-------------|
| [Neovim](https://neovim.io/) | Text editor (with Lua plugins) |
---
## 📝 TODO

- [x] Complete `install.sh` installer
- [ ] Document nvim plugins
