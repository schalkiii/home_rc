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
#   - WSL default user set to root
#   - Default shell set to zsh
#   - Verible (Verilog/SystemVerilog lint, format, language server)
#
# Usage:
#   cd /path/to/home_rc
#   chmod +x setup_wsl.sh
#   ./setup_wsl.sh
#   ./setup_wsl.sh --mirror ustc    Use USTC mirror for apt
#   ./setup_wsl.sh --mirror aliyun  Use Aliyun mirror for apt
#   ./setup_wsl.sh --mirror tuna    Use Tsinghua mirror for apt
#   ./setup_wsl.sh --dry-run        Preview without making changes
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
# Pre-flight check
# ──────────────────────────────────────────────
preflight_check() {
    if [ ! -f "$SCRIPT_DIR/.zshrc" ] || [ ! -d "$SCRIPT_DIR/offline_src" ]; then
        error "Cannot find home_rc files in current directory."
        error "Please run this script from the root of the home_rc repository."
        echo "  Expected to find: .zshrc, offline_src/, .oh-my-zsh/, etc."
        echo "  Current directory: $SCRIPT_DIR"
        exit 1
    fi
    ok "Running from home_rc repository root"
}

# ──────────────────────────────────────────────
# Step 1: Configure Chinese apt mirror
# ──────────────────────────────────────────────
configure_mirror() {
    if [[ -z "$MIRROR" ]]; then
        info "Step 1: Skipping apt mirror configuration (use --mirror to enable)"
        return
    fi

    info "Step 1: Configuring apt mirror ($MIRROR)..."

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
# Step 2: System package installation
# ──────────────────────────────────────────────
install_packages() {
    info "Step 2: Installing system packages..."

    local packages=(
        zsh
        git
        vim
        vim-gtk3
        curl
        wget
        tree
        grep
        fonts-noto-cjk
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
# Step 3: Install Oh My Zsh
# ──────────────────────────────────────────────
install_oh_my_zsh() {
    info "Step 3: Installing Oh My Zsh..."

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
# Step 4: Apply configs from local repo
# ──────────────────────────────────────────────
apply_configs() {
    info "Step 4: Applying configurations from home_rc..."

    if $DRY_RUN; then
        echo "    Would copy: .zshrc, .vimrc, .gitconfig, .gitignore"
        echo "    Would copy directories: .vim, .oh-my-zsh/custom, elisp"
        return
    fi

    cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    cp "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"
    cp "$SCRIPT_DIR/.gitignore" "$HOME/.gitignore"

    cp -r "$SCRIPT_DIR/.vim" "$HOME/"
    cp -r "$SCRIPT_DIR/elisp" "$HOME/"
    cp -r "$SCRIPT_DIR/.oh-my-zsh/custom" "$HOME/.oh-my-zsh/"

    ok "Configuration files applied"
}

# ──────────────────────────────────────────────
# Step 5: Install Zsh plugins
# ──────────────────────────────────────────────
install_zsh_plugins() {
    info "Step 5: Installing Zsh plugins..."

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
# Step 6: Install Vim plugins
# ──────────────────────────────────────────────
install_vim_plugins() {
    info "Step 6: Installing Vim plugins..."

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
# Step 7: Configure Git
# ──────────────────────────────────────────────
configure_git() {
    info "Step 7: Configuring Git..."

    if $DRY_RUN; then
        echo "    Would copy .gitconfig to $HOME"
        echo "    Would set user.name and user.email"
        echo "    Would set core.editor, merge.commit, merge.ff"
        return
    fi

    cp "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig" 2>/dev/null || true

    if [ ! -f "$HOME/.gitconfig" ]; then
        git config --global user.name "schalkiii"
        git config --global user.email "423338274@qq.com"
        ok "Git user configured"
    fi

    git config --global core.editor "$(which vim)"
    git config --global merge.commit no
    git config --global merge.ff false
    ok "Git editor and merge behavior configured"
}

# ──────────────────────────────────────────────
# Step 8: Set default shell to zsh
# ──────────────────────────────────────────────
set_default_shell() {
    info "Step 8: Setting default shell to zsh..."

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
# Step 0: Configure WSL default user to root
# ──────────────────────────────────────────────
configure_wsl_root() {
    info "Step 0: Configuring WSL default user to root..."

    local wsl_conf="/etc/wsl.conf"

    if $DRY_RUN; then
        echo "    Would configure $wsl_conf with [user] default=root"
        return
    fi

    if [ -f "$wsl_conf" ] && grep -q "^default=root" "$wsl_conf" 2>/dev/null; then
        warn "WSL default user is already root, skipping"
        return
    fi

    if [ -f "$wsl_conf" ]; then
        cp "$wsl_conf" "${wsl_conf}.bak"
        info "Backed up $wsl_conf -> ${wsl_conf}.bak"
    fi

    if grep -q "^\[user\]" "$wsl_conf" 2>/dev/null; then
        sed -i '/^\[user\]/,/^\[/ { /^default=/d }' "$wsl_conf"
        sed -i '/^\[user\]/a default=root' "$wsl_conf"
    else
        printf '\n[user]\ndefault=root\n' >> "$wsl_conf"
    fi
    ok "WSL default user set to root"

    echo ""
    echo "=========================================="
    echo "  WSL default user has been set to root."
    echo "  Please restart WSL for this to take effect,"
    echo "  then run this script again:"
    echo ""
    echo "    wsl --shutdown"
    echo "    ./setup_wsl.sh"
    echo ""
    echo "  (All subsequent steps will then run as root.)"
    echo "=========================================="
    exit 0
}

# ──────────────────────────────────────────────
# Step 9: Install Verible (Verilog/SystemVerilog tools)
# ──────────────────────────────────────────────
install_verible() {
    info "Step 9: Installing Verible..."

    local verible_version="v0.0-4053-g89d4d98a"
    local verible_tarball="verible-${verible_version}-linux-static-x86_64.tar.gz"
    local verible_url="https://github.com/chipsalliance/verible/releases/download/${verible_version}/${verible_tarball}"
    local install_dir="/usr/local/bin"

    if command -v verible-verilog-ls &>/dev/null; then
        warn "Verible already installed: $(verible-verilog-ls --version 2>&1 | head -1), skipping"
        return
    fi

    if $DRY_RUN; then
        echo "    Would download: $verible_url"
        echo "    Would extract and install to: $install_dir"
        return
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    info "Downloading Verible ${verible_version}..."
    if ! curl -fsSL "$verible_url" -o "$tmp_dir/$verible_tarball"; then
        warn "Failed to download Verible, skipping"
        rm -rf "$tmp_dir"
        return
    fi

    info "Extracting Verible..."
    tar -xzf "$tmp_dir/$verible_tarball" -C "$tmp_dir"

    local extracted_dir
    extracted_dir="$(find "$tmp_dir" -maxdepth 1 -type d -name "verible-*" | head -1)"
    if [[ -z "$extracted_dir" ]]; then
        warn "Failed to find extracted Verible directory, skipping"
        rm -rf "$tmp_dir"
        return
    fi

    info "Installing Verible binaries to $install_dir..."
    cp "$extracted_dir"/bin/* "$install_dir/"
    rm -rf "$tmp_dir"
    ok "Verible ${verible_version} installed to $install_dir"
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

    preflight_check
    configure_wsl_root
    configure_mirror
    install_packages
    install_oh_my_zsh
    apply_configs
    install_zsh_plugins
    install_vim_plugins
    configure_git
    set_default_shell
    install_verible

    echo ""
    echo "=========================================="
    if $DRY_RUN; then
        echo "  Dry run complete. No changes made."
    else
        echo "  Setup complete! Please:"
        echo "    1. Restart your terminal or run: zsh"
        echo "    2. Verify: zsh --version"
        echo "    3. Verify: vim --version"
        echo "    4. Verify Verible: verible-verilog-ls --version"
        echo "=========================================="
    fi
}

main "$@"