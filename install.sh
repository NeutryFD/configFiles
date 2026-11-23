#!/bin/bash
# ---------------------------------------------------------------
# install.sh - Bootstrap script for dotfiles
# ---------------------------------------------------------------
# Creates symlinks and installs packages for the desktop setup.
# Run from the repo root: ./install.sh [--dry-run] [--only <module>[,<module>...]]
#
# Layout:
#   - config/<app>  -> ~/.config/<app>
#   - home/<file>   -> ~/<file>
#   - bin/          -> added to PATH in .zshrc via $DOTFILES
#   - hosts/<host>  -> ~/.config/dotfiles-host (host from $DOTFILES_HOST, else hostnamectl chassis)
# ---------------------------------------------------------------

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Helpers ---------------------------------------------------

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; }
dry()   { echo -e "${CYAN}[dry-run]${NC} $1"; }

# Create parent directory and symlink (file or directory -> target)
#   link_config <repo_relative_path> <destination>
# A real directory at <destination> is moved aside to <destination>.bak-<timestamp>
link_config() {
    local src="${REPO_DIR}/$1"
    local dst="$2"
    local backup

    if [[ ! -e "$src" ]]; then
        error "Source not found: $src"
        return 1
    fi

    if [[ -d "$dst" && ! -L "$dst" ]]; then
        backup="${dst}.bak-$(date +%Y%m%d%H%M%S)"
        if $DRY_RUN; then
            dry "mv $dst $backup"
        else
            mv "$dst" "$backup"
            warn "Moved existing $dst to $backup"
        fi
    fi

    if $DRY_RUN; then
        dry "ln -sfn $src $dst"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    info "Linked $dst -> $src"
}

# Host whose hosts/<host> files are linked: $DOTFILES_HOST, else laptop -> thinkpad, otherwise arch
detect_host() {
    if [[ -n "${DOTFILES_HOST:-}" ]]; then
        echo "$DOTFILES_HOST"
    elif [[ "$(hostnamectl chassis 2>/dev/null)" == "laptop" ]]; then
        echo "thinkpad"
    else
        echo "arch"
    fi
}

# Determine package manager based on /etc/os-release
get_package_mgmt() {
	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		echo "$ID"
		if [[ "$ID" == "arch" ]]; then
		 	package_mgmt="pacman"
		elif [[ "$ID" == "ubuntu" ]]; then
			package_mgmt="apt"
		else
			echo "unknown"
		fi
	else
		echo "unknown"
	fi
}

# Check if all binaries are available via which
# Usage: check_deps <binary>[:<package>] ...
# Returns 0 if all found, 1 if any missing (and prints which ones)
check_deps() {
    local missing=()
    for entry in "$@"; do
        local bin
        bin="${entry%%:*}"
        if ! which "$bin" &>/dev/null; then
            missing+=("$bin")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing dependencies: ${missing[*]}"
        return 1
    fi
    return 0
}

# Install packages (skip already available ones, regardless of how they were installed)
# Each argument can be:
#   "pkg"          - package name and binary name are the same
#   "binary:pkg"   - binary name differs from package name (e.g. "i3lock:i3lock-color")
install_packages() {
	local package_mgmt
	package_mgmt="$(get_package_mgmt)"
    local to_install=()
    local install_cmd

    if [[ "$package_mgmt" == "unknown" ]]; then
		error "Unsupported OS. Cannot determine package manager."
		return 1
	elif [[ "$package_mgmt" == "ubuntu" ]]; then
	    install_cmd="apt install -y"
	elif [[ "$package_mgmt" == "arch" ]]; then
	    install_cmd="pacman -S --noconfirm"
	fi

    if check_deps "$@"; then
        info "All packages already installed"
        return 0
    fi

    for entry in "$@"; do
        local bin pkg
        if [[ "$entry" == *:* ]]; then
            bin="${entry%%:*}"
            pkg="${entry##*:}"
        else
            bin="$entry"
            pkg="$entry"
        fi
        if ! which "$bin" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if $DRY_RUN; then
        dry "sudo $install_cmd ${to_install[*]}"
        return
    fi
    info "Installing: ${to_install[*]}"
    sudo $install_cmd "${to_install[@]}"
}

# --- Module functions ------------------------------------------

setup_betterlockscreen() {
    echo -e "\n${YELLOW}--- Betterlockscreen ---${NC}"
    install_packages i3lock:i3lock-color xrandr:xorg-xrandr xdpyinfo:xorg-xdpyinfo convert:imagemagick bc
    if ! which betterlockscreen &>/dev/null; then
        info "Installing betterlockscreen..."
        info "Repo: https://github.com/betterlockscreen/betterlockscreen"
        if $DRY_RUN; then
            dry "curl -fsSL https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh | bash"
        else
            curl -fsSL https://raw.githubusercontent.com/betterlockscreen/betterlockscreen/main/install.sh | bash
        fi
    else
        info "Betterlockscreen already installed: $(which betterlockscreen)"
    fi
    link_config "config/betterlockscreen" "$HOME/.config/betterlockscreen"

    # Lock the screen on suspend/sleep
    local unit="betterlockscreen@.service"
    if $DRY_RUN; then
        dry "sudo install -Dm644 $REPO_DIR/config/betterlockscreen/$unit /etc/systemd/system/$unit"
        dry "sudo systemctl enable betterlockscreen@$USER"
    else
        sudo install -Dm644 "$REPO_DIR/config/betterlockscreen/$unit" "/etc/systemd/system/$unit"
        sudo systemctl daemon-reload
        sudo systemctl enable "betterlockscreen@$USER"
        info "Enabled betterlockscreen@$USER (locks on suspend)"
    fi
}

setup_host() {
    local host
    host="$(detect_host)"
    echo -e "\n${YELLOW}--- Host ($host) ---${NC}"
    link_config "hosts/$host" "$HOME/.config/dotfiles-host"
}

setup_bspwm() {
    echo -e "\n${YELLOW}--- bspwm ---${NC}"
    install_packages bspwm
    link_config "config/bspwm" "$HOME/.config/bspwm"
    # Monitor and polybar layout comes from ~/.config/dotfiles-host (host module)
}

setup_ghostty() {
    echo -e "\n${YELLOW}--- Ghostty ---${NC}"
    install_packages ghostty
    link_config "config/ghostty" "$HOME/.config/ghostty"
}

setup_kitty() {
    echo -e "\n${YELLOW}--- Kitty ---${NC}"
    link_config "config/kitty" "$HOME/.config/kitty"
}

setup_nvim() {
    echo -e "\n${YELLOW}--- Neovim ---${NC}"
	local package_mgmt
	package_mgmt="$(get_package_mgmt)"
	if ! which nvim &>/dev/null; then
		if [ "$package_mgmt" == "ubuntu" ]; then
			if $DRY_RUN; then
				dry "curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
				dry "sudo rm -rf /opt/nvim-linux-x86_64"
				dry "sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz"
				dry "ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim"
			else
				curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
				sudo rm -rf /opt/nvim-linux-x86_64
				sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
				ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
			fi
		elif [ "$package_mgmt" == "arch" ]; then
			install_packages nvim:neovim
		fi
	else
		info "Neovim already installed: $(which nvim)"
	fi
    # Per-item links keep the plugin lockfile out of the repo
    link_config "config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    link_config "config/nvim/lua" "$HOME/.config/nvim/lua"
}

setup_picom() {
    echo -e "\n${YELLOW}--- Picom ---${NC}"
    install_packages picom
    link_config "config/picom" "$HOME/.config/picom"
}

setup_rofi() {
    echo -e "\n${YELLOW}--- Rofi ---${NC}"
    install_packages rofi
    link_config "config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
    link_config "config/rofi/squared-theme.rasi" "$HOME/.config/rofi/squared-theme.rasi"
}

setup_sxhkd() {
    echo -e "\n${YELLOW}--- sxhkd ---${NC}"
    install_packages sxhkd
    link_config "config/sxhkd" "$HOME/.config/sxhkd"
}

setup_polybar() {
    echo -e "\n${YELLOW}--- Polybar ---${NC}"
    install_packages polybar
    link_config "config/polybar" "$HOME/.config/polybar"
    # Bar configs live in ~/.config/dotfiles-host/polybar (host module)
    if $DRY_RUN; then
        dry "chmod +x ${REPO_DIR}/config/polybar/scripts/*.sh"
    else
        chmod +x "${REPO_DIR}"/config/polybar/scripts/*.sh 2>/dev/null || true
    fi
}

setup_gearbox() {
    echo -e "\n${YELLOW}--- Gearbox (device tools) ---${NC}"
    local gearbox_dir="$HOME/Documents/gearbox"
    install_packages jq cargo:rust make
    if [[ ! -d "$gearbox_dir/mm712" ]]; then
        warn "Gearbox not found at $gearbox_dir, skipping"
        return
    fi
    # Build as the user, install as root (make install never builds)
    if $DRY_RUN; then
        dry "make -C $gearbox_dir/mm712"
        dry "sudo make -C $gearbox_dir/mm712 install"
    else
        make -C "$gearbox_dir/mm712"
        sudo make -C "$gearbox_dir/mm712" install
        info "Installed mm712 and its udev rule (polybar gearbox bar)"
    fi
}

setup_clipmenu() {
    echo -e "\n${YELLOW}--- clipmenu ---${NC}"
    # The Arch package (6.x) lacks touch_on_select, so build upstream from source
    if ! grep -aq touch_on_select "$(which clipmenu 2>/dev/null)" 2>/dev/null; then
        install_packages git make gcc
        info "Building clipmenu from https://github.com/cdown/clipmenu (develop)"
        if $DRY_RUN; then
            dry "git clone --depth 1 -b develop https://github.com/cdown/clipmenu.git <tmp>"
            dry "make -C <tmp> && sudo make -C <tmp> install"
        else
            local tmp_dir
            tmp_dir="$(mktemp -d)"
            git clone --depth 1 -b develop https://github.com/cdown/clipmenu.git "$tmp_dir"
            make -C "$tmp_dir"
            sudo make -C "$tmp_dir" install
            rm -rf "$tmp_dir"
        fi
    else
        info "clipmenu already supports touch_on_select: $(which clipmenu)"
    fi
    link_config "config/clipmenu" "$HOME/.config/clipmenu"
    # clipmenud is started by bspwmrc
}

setup_dunst() {
    echo -e "\n${YELLOW}--- Dunst ---${NC}"
    install_packages dunst notify-send:libnotify
    link_config "config/dunst" "$HOME/.config/dunst"
}

setup_tmux() {
    echo -e "\n${YELLOW}--- tmux ---${NC}"
    install_packages tmux
    link_config "home/.tmux.conf" "$HOME/.tmux.conf"
}

setup_fzf() {
    echo -e "\n${YELLOW}--- fzf ---${NC}"
    if ! which fzf &>/dev/null; then
        info "Installing fzf from source..."
        if $DRY_RUN; then
            dry "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf"
            dry "~/.fzf/install --all"
        else
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
            "$HOME/.fzf/install" --all
        fi
    else
        info "fzf already installed: $(which fzf)"
    fi
}

# Install zsh plugins to ~/.zsh/plugins
# Each entry is one of:
#   "https://github.com/user/repo"               - clone full repo, plugin name = repo basename
#   "https://github.com/user/repo::subdir/path"   - sparse-checkout a subdirectory, plugin name = path basename
install_zsh_plugins() {
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins/"

    for entry in "$@"; do
        local repo subdir name
        if [[ "$entry" == *"::"* ]]; then
            repo="${entry%%::*}"
            subdir="${entry##*::}"
            name="$(basename "$subdir")"
        else
            repo="$entry"
            subdir=""
            name="$(basename "$repo")"
        fi

        if [[ -d "$plugins_dir/$name" ]]; then
            info "$name already installed"
            continue
        fi

        info "Installing $name..."
        if $DRY_RUN; then
            if [[ -n "$subdir" ]]; then
                dry "git clone --depth 1 --filter=blob:none --sparse $repo (checkout $subdir) -> $plugins_dir/$name"
            else
                dry "git clone --depth 1 $repo $plugins_dir/$name"
            fi
            continue
        fi

        if [[ -n "$subdir" ]]; then
            # Sparse checkout: clone only the subdirectory we need
            local tmp_dir
            tmp_dir="$(mktemp -d)"
            git clone --depth 1 --filter=blob:none --sparse "$repo" "$tmp_dir" 2>/dev/null
            git -C "$tmp_dir" sparse-checkout set "$subdir" 2>/dev/null
            mv "$tmp_dir/$subdir" "$plugins_dir/$name"
            rm -rf "$tmp_dir"
        else
            git clone --depth 1 "$repo" "$plugins_dir/$name"
        fi
    done
}

setup_zsh() {
    echo -e "\n${YELLOW}--- Zsh ---${NC}"
    install_packages zsh lsd lazygit xclip
    setup_fzf

    # Zsh plugins (no oh-my-zsh framework)
    # Add new plugins here - the name is extracted from the URL automatically
    local zsh_plugins=(
        "https://github.com/zsh-users/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting"
        "https://github.com/ohmyzsh/ohmyzsh::plugins/zsh-interactive-cd"
		"https://github.com/Aloxaf/fzf-tab"
    )
    install_zsh_plugins "${zsh_plugins[@]}"

    link_config "home/.zshrc" "$HOME/.zshrc"
    link_config "home/.zsh/functions/helpers.zsh" "$HOME/.zsh/functions/helpers.zsh"
    link_config "home/.oh-my-zsh/custom/themes/neutry.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/neutry.zsh-theme"

    if $DRY_RUN; then
        dry "chmod +x ${REPO_DIR}/bin/*.sh"
    else
        chmod +x "${REPO_DIR}"/bin/*.sh 2>/dev/null || true
    fi
    info "bin/ added to PATH via \$DOTFILES in .zshrc (default \$HOME/dotfiles)"
    [[ "$REPO_DIR" == "$HOME/dotfiles" ]] || warn "Repo is not at \$HOME/dotfiles: export DOTFILES=$REPO_DIR in ~/.zshenv"
}

setup_opencode() {
    echo -e "\n${YELLOW}--- OpenCode ---${NC}"
    if ! which opencode &>/dev/null && [[ ! -x "$HOME/.opencode/bin/opencode" ]]; then
        info "Installing opencode..."
        if $DRY_RUN; then
            dry "curl -fsSL https://opencode.ai/install | bash"
        else
            curl -fsSL https://opencode.ai/install | bash
        fi
    else
        local opencode_bin
        opencode_bin="$(which opencode 2>/dev/null || echo "$HOME/.opencode/bin/opencode")"
        info "OpenCode already installed: $opencode_bin"
    fi
    # ~/.config/opencode also holds local state, so link per item
    link_config "config/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
    link_config "config/opencode/agent" "$HOME/.config/opencode/agent"
    link_config "config/opencode/commands" "$HOME/.config/opencode/commands"
    link_config "config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
}

setup_herdr() {
    echo -e "\n${YELLOW}--- herdr ---${NC}"
    which herdr &>/dev/null || warn "herdr not found in PATH, linking config anyway"
    # ~/.config/herdr also holds sessions and logs, so link only the config
    link_config "config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
}

# --- Main ------------------------------------------------------

# All available modules in default install order
ALL_MODULES=(host zsh fzf bspwm sxhkd clipmenu dunst polybar gearbox picom ghostty kitty nvim rofi tmux opencode herdr betterlockscreen)

usage() {
    echo "Usage: $0 [--dry-run] [--only <module>[,<module>...]]"
    echo ""
    echo "  --dry-run              Print what would be done without making changes"
    echo "  --only <modules>       Comma-separated list of modules to install"
    echo ""
    echo "Available modules: ${ALL_MODULES[*]}"
    echo ""
    echo "Examples:"
    echo "  $0 --only nvim"
    echo "  $0 --only zsh,tmux,nvim"
    echo "  $0 --only nvim --dry-run"
}

run_module() {
    local mod="$1"
    case "$mod" in
        host)            setup_host ;;
        zsh)             setup_zsh ;;
        fzf)             setup_fzf ;;
        bspwm)           setup_bspwm ;;
        sxhkd)           setup_sxhkd ;;
        clipmenu)        setup_clipmenu ;;
        dunst)           setup_dunst ;;
        polybar)         setup_polybar ;;
        gearbox)         setup_gearbox ;;
        picom)           setup_picom ;;
        ghostty)         setup_ghostty ;;
        kitty)           setup_kitty ;;
        nvim)            setup_nvim ;;
        rofi)            setup_rofi ;;
        tmux)            setup_tmux ;;
        opencode)        setup_opencode ;;
        herdr)           setup_herdr ;;
        betterlockscreen) setup_betterlockscreen ;;
        *) error "Unknown module: $mod"; echo "Available: ${ALL_MODULES[*]}"; return 1 ;;
    esac
}

main() {
    local selected_modules=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=true ;;
            --only)
                if [[ -z "${2:-}" ]]; then
                    error "--only requires a module name"
                    usage; exit 1
                fi
                IFS=',' read -ra selected_modules <<< "$2"
                shift
                ;;
            -h|--help) usage; exit 0 ;;
            *) error "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done

    echo -e "${GREEN}"
    echo "  install.sh - dotfiles bootstrap"
    echo "  repo: ${REPO_DIR}"
    $DRY_RUN && echo -e "  ${CYAN}** DRY-RUN MODE **${NC}"
    echo -e "${NC}"

    if [[ ${#selected_modules[@]} -gt 0 ]]; then
        for mod in "${selected_modules[@]}"; do
            run_module "$mod"
        done
    else
        for mod in "${ALL_MODULES[@]}"; do
            run_module "$mod"
        done
    fi

    echo -e "\n${GREEN}[*] Done. Restart your session to apply changes.${NC}"
}

main "$@"
