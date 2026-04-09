#!/bin/bash
# ---------------------------------------------------------------
# ignite.sh - Bootstrap script for configFiles
# ---------------------------------------------------------------
# Creates symlinks and installs packages for the desktop setup.
# Run from the repo root: ./ignite.sh [--dry-run]
#
# Configs that don't need symlinks (loaded by absolute path):
#   - sxhkd     -> loaded via sxhkd -c in bspwmrc
#   - polybar    -> loaded via polybar -c in bspwmrc
#   - starship   -> loaded via STARSHIP_CONFIG in .zshrc
#   - nvim/lua/  -> loaded via package.path in init.lua
#   - scripts/   -> added to PATH in .zshrc
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

# Create parent directory and symlink (file -> target)
#   link_config <repo_relative_path> <destination>
link_config() {
    local src="${REPO_DIR}/$1"
    local dst="$2"

    if [[ ! -e "$src" ]]; then
        error "Source not found: $src"
        return 1
    fi

    if $DRY_RUN; then
        dry "ln -sf $src $dst"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    info "Linked $dst -> $src"
}

# Install packages with pacman (skip already installed)
install_packages() {
    local to_install=()
    for pkg in "$@"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        if $DRY_RUN; then
            dry "pacman -S --noconfirm ${to_install[*]}"
            return
        fi
        info "Installing: ${to_install[*]}"
        sudo pacman -S --noconfirm "${to_install[@]}"
    else
        info "All packages already installed"
    fi
}

# --- Module functions ------------------------------------------

setup_betterlockscreen() {
    echo -e "\n${YELLOW}--- Betterlockscreen ---${NC}"
    info "Repo: https://github.com/betterlockscreen/betterlockscreen"
    install_packages i3lock-color xorg-xrandr xorg-xdpyinfo imagemagick bc
    link_config "betterlockscreen/betterlockscreenrc" \
                "$HOME/.config/betterlockscreen/betterlockscreenrc"
}

setup_bspwm() {
    echo -e "\n${YELLOW}--- bspwm ---${NC}"
    install_packages bspwm
    link_config "bspwm/bspwmrc" "$HOME/.config/bspwm/bspwmrc"
}

setup_ghostty() {
    echo -e "\n${YELLOW}--- Ghostty ---${NC}"
    install_packages ghostty
    link_config "ghostty/config" "$HOME/.config/ghostty/config"
}

setup_nvim() {
    echo -e "\n${YELLOW}--- Neovim ---${NC}"
    install_packages neovim
    link_config "nvim/init.lua" "$HOME/.config/nvim/init.lua"
    # lua/ directory is loaded via package.path set in init.lua
}

setup_picom() {
    echo -e "\n${YELLOW}--- Picom ---${NC}"
    install_packages picom
    link_config "picom/picom.conf" "$HOME/.config/picom/picom.conf"
}

setup_rofi() {
    echo -e "\n${YELLOW}--- Rofi ---${NC}"
    install_packages rofi
    link_config "rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
    # squared-theme.rasi is referenced by absolute path in config.rasi
}

setup_sxhkd() {
    echo -e "\n${YELLOW}--- sxhkd ---${NC}"
    install_packages sxhkd
    # No symlink needed - loaded via sxhkd -c in bspwmrc
    info "Config loaded directly from repo by bspwmrc"
}

setup_polybar() {
    echo -e "\n${YELLOW}--- Polybar ---${NC}"
    install_packages polybar
    # No symlink needed - loaded via polybar -c in bspwmrc
    info "Config loaded directly from repo by bspwmrc"
    if $DRY_RUN; then
        dry "chmod +x ${REPO_DIR}/polybar/scripts/*.sh"
    else
        chmod +x "${REPO_DIR}"/polybar/scripts/*.sh 2>/dev/null || true
    fi
}

setup_tmux() {
    echo -e "\n${YELLOW}--- tmux ---${NC}"
    install_packages tmux
    link_config "tmux/.tmux.conf" "$HOME/.tmux.conf"
}

setup_zsh() {
    echo -e "\n${YELLOW}--- Zsh ---${NC}"
    install_packages zsh fzf
    link_config "zsh/.zshrc" "$HOME/.zshrc"
    # scripts/ directory is added to PATH in .zshrc
    if $DRY_RUN; then
        dry "chmod +x ${REPO_DIR}/scripts/*.sh"
    else
        chmod +x "${REPO_DIR}"/scripts/*.sh 2>/dev/null || true
    fi
    info "Scripts directory added to PATH via .zshrc"
}

setup_opencode() {
    echo -e "\n${YELLOW}--- OpenCode ---${NC}"
    if ! command -v opencode &>/dev/null; then
        info "Installing opencode..."
        if $DRY_RUN; then
            dry "curl -fsSL https://opencode.ai/install | bash"
        else
            curl -fsSL https://opencode.ai/install | bash
        fi
    else
        info "OpenCode already installed"
    fi
    link_config "opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
}

setup_starship() {
    echo -e "\n${YELLOW}--- Starship ---${NC}"
    if ! command -v starship &>/dev/null; then
        warn "Starship not found. Install with: curl -sS https://starship.rs/install.sh | sh"
    else
        info "Starship already installed"
    fi
    # Config loaded via STARSHIP_CONFIG env var in .zshrc
    info "Config loaded via STARSHIP_CONFIG in .zshrc"
}

# --- Main ------------------------------------------------------

usage() {
    echo "Usage: $0 [--dry-run]"
    echo "  --dry-run   Print what would be done without making changes"
}

main() {
    for arg in "$@"; do
        case "$arg" in
            --dry-run) DRY_RUN=true ;;
            -h|--help) usage; exit 0 ;;
            *) error "Unknown option: $arg"; usage; exit 1 ;;
        esac
    done

    echo -e "${GREEN}"
    echo "  ignite.sh - configFiles bootstrap"
    echo "  repo: ${REPO_DIR}"
    $DRY_RUN && echo -e "  ${CYAN}** DRY-RUN MODE **${NC}"
    echo -e "${NC}"

    setup_zsh
    setup_bspwm
    setup_sxhkd
    setup_polybar
    setup_picom
    setup_ghostty
    setup_nvim
    setup_rofi
    setup_tmux
    setup_starship
    setup_opencode
    setup_betterlockscreen

    echo -e "\n${GREEN}[*] Done. Restart your session to apply changes.${NC}"
}

main "$@"
