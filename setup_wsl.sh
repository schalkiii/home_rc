#!/bin/bash
#
# home_rc - WSL Environment Setup Script
# =======================================
# This script configures a WSL Ubuntu environment with:
#   - Chinese apt mirror (optional)
#   - Oh My Zsh (ys theme)
#   - Zsh plugins: incr, zsh-autosuggestions, zsh-syntax-highlighting
#   - Vim plugins: tabular, supertab, nerdtree
#   - Git configuration
#   - Emacs verilog-mode (for FPGA/ASIC design)
#
# Usage:
#   chmod +x setup_wsl.sh
#   ./setup_wsl.sh
#   ./setup_wsl.sh --mirror ustc    Use USTC mirror for apt
#   ./setup_wsl.sh --mirror aliyun  Use Aliyun mirror for apt
#   ./setup_wsl.sh --mirror tuna    Use Tsinghua mirror for apt
#   ./setup_wsl.sh --dry-run        Preview without making changes
#

set -euo pipefail

DRY_RUN=false
MIRROR=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --mirror)
                MIRROR="${2:-}"
                if [[ -z "$MIRROR" ]]; then
                    error "--mirror requires an argument: ustc|aliyun|tuna"
                    exit 1
                fi
                shift 2
                ;;
            --help|-h)
                echo "Usage: ./setup_wsl.sh [OPTION]"
                echo ""
                echo "Options:"
                echo "  --dry-run           Preview without making changes"
                echo "  --mirror MIRROR     Use Chinese apt mirror (ustc|aliyun|tuna)"
                echo "  --help              Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo "Usage: ./setup_wsl.sh [--dry-run] [--mirror ustc|aliyun|tuna]"
                exit 1
                ;;
        esac
    done
}

info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

run() {
    if $DRY_RUN; then
        echo "    Would run: $*"
    else
        "$@"
    fi
}

# ──────────────────────────────────────────────
# Step 0: Configure Chinese apt mirror
# ──────────────────────────────────────────────
configure_mirror() {
    if [[ -z "$MIRROR" ]]; then
        info "Step 0: Skipping apt mirror configuration (use --mirror to enable)"
        return
    fi

    info "Step 0: Configuring apt mirror ($MIRROR)..."

    local ubuntu_codename
    ubuntu_codename="$(lsb_release -cs 2>/dev/null || :)"
    if [[ -z "$ubuntu_codename" ]]; then
        warn "Cannot detect Ubuntu codename, skipping mirror configuration"
        return
    fi

    local mirror_url=""
    case "$MIRROR" in
        ustc)  mirror_url="https://mirrors.ustc.edu.cn" ;;
        aliyun) mirror_url="https://mirrors.aliyun.com" ;;
        tuna)  mirror_url="https://mirrors.tuna.tsinghua.edu.cn" ;;
        *)
            warn "Unknown mirror: $MIRROR (supported: ustc, aliyun, tuna)"
            return
            ;;
    esac

    if $DRY_RUN; then
        echo "    Would replace /etc/apt/sources.list with $mirror_url"
        return
    fi

    local sources_list="deb ${mirror_url}/ubuntu/ ${ubuntu_codename} main restricted universe multiverse
deb ${mirror_url}/ubuntu/ ${ubuntu_codename}-updates main restricted universe multiverse
deb ${mirror_url}/ubuntu/ ${ubuntu_codename}-backports main restricted universe multiverse
deb ${mirror_url}/ubuntu/ ${ubuntu_codename}-security main restricted universe multiverse"

    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        info "Backed up /etc/apt/sources.list -> /etc/apt/sources.list.bak"
    fi

    echo "$sources_list" > /etc/apt/sources.list
    apt-get update -qq
    ok "Apt mirror configured: $mirror_url ($ubuntu_codename)"
}

# ──────────────────────────────────────────────
# Step 1: System package installation
# ──────────────────────────────────────────────
install_packages() {
    info "Step 1: Installing system packages..."

    local packages=(
        zsh
        git
        vim
        curl
        wget
        tree
        grep
    )

    if $DRY_RUN; then
        echo "    Would install: ${packages[*]}"
        return
    fi

    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}"
    ok "System packages installed"
}

# ──────────────────────────────────────────────
# Step 2: Install Oh My Zsh
# ──────────────────────────────────────────────
install_oh_my_zsh() {
    info "Step 2: Installing Oh My Zsh..."

    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Oh My Zsh already installed, skipping"
        return
    fi

    if $DRY_RUN; then
        echo "    Would install Oh My Zsh"
        return
    fi

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed"
}

# ──────────────────────────────────────────────
# Step 3: Clone home_rc and apply configs
# ──────────────────────────────────────────────
apply_configs() {
    info "Step 3: Applying configurations from home_rc..."

    local repo_url="https://github.com/schalkiii/home_rc.git"
    local tmp_dir="/tmp/home_rc"

    if $DRY_RUN; then
        echo "    Would clone $repo_url to $tmp_dir"
        echo "    Would copy: .zshrc, .vimrc, .gitconfig, .gitignore"
        echo "    Would copy directories: .vim, .oh-my-zsh/custom, elisp"
        return
    fi

    if [ ! -d "$tmp_dir" ]; then
        git clone "$repo_url" "$tmp_dir"
    else
        warn "$tmp_dir already exists, pulling latest"
        cd "$tmp_dir" && git pull
    fi

    cd "$tmp_dir"

    cp .zshrc "$HOME/.zshrc"
    cp .vimrc "$HOME/.vimrc"
    cp .gitignore "$HOME/.gitignore"

    cp -r .vim "$HOME/"
    cp -r elisp "$HOME/"
    cp -r .oh-my-zsh/custom "$HOME/.oh-my-zsh/"

    ok "Configuration files applied"
}

# ──────────────────────────────────────────────
# Step 4: Install Zsh plugins
# ──────────────────────────────────────────────
install_zsh_plugins() {
    info "Step 4: Installing Zsh plugins..."

    local custom_plugins="$HOME/.oh-my-zsh/custom/plugins"

    if $DRY_RUN; then
        echo "    Would clone plugins to $custom_plugins"
        return
    fi

    mkdir -p "$custom_plugins"

    if [ ! -d "$custom_plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$custom_plugins/zsh-autosuggestions"
        ok "zsh-autosuggestions installed"
    else
        warn "zsh-autosuggestions already exists"
    fi

    if [ ! -d "$custom_plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$custom_plugins/zsh-syntax-highlighting"
        ok "zsh-syntax-highlighting installed"
    else
        warn "zsh-syntax-highlighting already exists"
    fi
}

# ──────────────────────────────────────────────
# Step 5: Install Vim plugins
# ──────────────────────────────────────────────
install_vim_plugins() {
    info "Step 5: Installing Vim plugins..."

    local vim_pack="$HOME/.vim/pack/plugins/start"

    if $DRY_RUN; then
        echo "    Would clone plugins to $vim_pack"
        return
    fi

    mkdir -p "$vim_pack"

    if [ ! -d "$vim_pack/tabular" ]; then
        git clone https://github.com/godlygeek/tabular.git "$vim_pack/tabular"
        ok "tabular installed"
    else
        warn "tabular already exists"
    fi

    if [ ! -d "$vim_pack/supertab" ]; then
        git clone https://github.com/ervandew/supertab.git "$vim_pack/supertab"
        ok "supertab installed"
    else
        warn "supertab already exists"
    fi

    if [ ! -d "$vim_pack/nerdtree" ]; then
        git clone https://github.com/preservim/nerdtree.git "$vim_pack/nerdtree"
        ok "nerdtree installed"
    else
        warn "nerdtree already exists"
    fi
}

# ──────────────────────────────────────────────
# Step 6: Configure Git
# ──────────────────────────────────────────────
configure_git() {
    info "Step 6: Configuring Git..."

    if $DRY_RUN; then
        echo "    Would copy .gitconfig to $HOME"
        echo "    Would set user.name and user.email"
        return
    fi

    cp /tmp/home_rc/.gitconfig "$HOME/.gitconfig" 2>/dev/null || true

    if [ ! -f "$HOME/.gitconfig" ]; then
        git config --global user.name "schalkiii"
        git config --global user.email "423338274@qq.com"
        ok "Git user configured"
    fi
}

# ──────────────────────────────────────────────
# Step 7: Set default shell to zsh
# ──────────────────────────────────────────────
set_default_shell() {
    info "Step 7: Setting default shell to zsh..."

    if $DRY_RUN; then
        echo "    Would run: chsh -s $(which zsh)"
        return
    fi

    local zsh_path
    zsh_path="$(which zsh)"

    if [ "$SHELL" != "$zsh_path" ]; then
        chsh -s "$zsh_path"
        ok "Default shell changed to zsh"
    else
        warn "zsh is already the default shell"
    fi
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    parse_args "$@"

    echo "=========================================="
    echo "  home_rc - WSL Environment Setup"
    echo "=========================================="
    echo ""

    configure_mirror
    install_packages
    install_oh_my_zsh
    apply_configs
    install_zsh_plugins
    install_vim_plugins
    configure_git
    set_default_shell

    echo ""
    echo "=========================================="
    if $DRY_RUN; then
        echo "  Dry run complete. No changes made."
    else
        echo "  Setup complete! Please:"
        echo "    1. Restart your terminal or run: zsh"
        echo "    2. Verify: zsh --version"
        echo "    3. Verify: vim --version"
        echo "=========================================="
    fi
}

main "$@"