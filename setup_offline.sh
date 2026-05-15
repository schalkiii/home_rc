#!/bin/bash
#
# setup_offline.sh - Offline Development Environment Setup
# ========================================================
# This script configures a Linux / WSL development environment using
# ONLY local files from this repository. No network access required.
#
# It installs:
#   - Oh My Zsh (from bundled .oh-my-zsh/)
#   - Zsh plugins (from offline_src/): incr, zsh-autosuggestions, zsh-syntax-highlighting
#   - Vim plugins (from offline_src/): tabular, supertab, nerdtree
#   - Shell/editor/git config files (.zshrc, .vimrc, .gitconfig)
#   - Emacs verilog-mode (from elisp/)
#   - Verible (from offline_src/verible-*.tar.gz, optional)
#
# Usage:
#   cd home_rc/
#   chmod +x setup_offline.sh
#   ./setup_offline.sh
#
# Options:
#   ./setup_offline.sh --dry-run    Preview changes without modifying anything
#   ./setup_offline.sh --help       Show this help message
#

set -euo pipefail

# ──────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.home_rc_backup_$(date +%Y%m%d_%H%M%S)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Plugin source paths (relative to repo root)
OFFLINE_ZSH_AUTOSUGGESTIONS="$SCRIPT_DIR/offline_src/zsh-autosuggestions"
OFFLINE_ZSH_SYNTAX_HIGHLIGHTING="$SCRIPT_DIR/offline_src/zsh-syntax-highlighting"
OFFLINE_VIM_TABULAR="$SCRIPT_DIR/offline_src/tabular"
OFFLINE_VIM_SUPERTAB="$SCRIPT_DIR/offline_src/supertab"
OFFLINE_VIM_NERDTREE="$SCRIPT_DIR/offline_src/nerdtree"

# Verible offline tarball (optional)
VERIBLE_TARBALL="$(ls "$SCRIPT_DIR"/offline_src/verible-*.tar.gz 2>/dev/null | head -1 || true)"

# Target paths
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_PLUGINS="$OH_MY_ZSH_DIR/custom/plugins"
VIM_PACK_DIR="$HOME/.vim/pack/plugins/start"

# Config files to deploy
CONFIG_FILES=(
    ".zshrc"
    ".vimrc"
    ".gitconfig"
    ".gitignore"
)

# ──────────────────────────────────────────────
# Utilities
# ──────────────────────────────────────────────
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

DRY_RUN=false
run() {
    if $DRY_RUN; then
        echo "         Would run: $*"
        return 0
    fi
    "$@"
}

check_path_exists() {
    local path="$1"
    local label="$2"
    if [ ! -e "$path" ]; then
        error "$label not found: $path"
        error "Make sure you are running this script from within the home_rc repository."
        exit 1
    fi
}

backup_file() {
    local src="$1"
    if [ -e "$src" ] && [ ! -L "$src" ]; then
        local dest="$BACKUP_DIR/$(basename "$src")"
        run mkdir -p "$BACKUP_DIR"
        run cp -r "$src" "$dest"
        info "Backed up $src -> $dest"
    fi
}

is_dir_populated() {
    local dir="$1"
    [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null | wc -l)" -gt 0 ]
}

# ──────────────────────────────────────────────
# Step 1: Pre-flight check
# ──────────────────────────────────────────────
preflight_check() {
    info "Step 1: Pre-flight check..."

    # Verify we are inside the home_rc repository
    if [ ! -f "$SCRIPT_DIR/.zshrc" ] || [ ! -d "$SCRIPT_DIR/offline_src" ]; then
        error "Cannot find home_rc files in current directory."
        error "Please run this script from the root of the home_rc repository."
        echo "  Expected to find: .zshrc, offline_src/, .oh-my-zsh/, etc."
        echo "  Current directory: $SCRIPT_DIR"
        exit 1
    fi

    # Verify offline_src contains required plugin sources
    local required_paths=(
        "$OFFLINE_ZSH_AUTOSUGGESTIONS/zsh-autosuggestions.plugin.zsh"
        "$OFFLINE_VIM_TABULAR/plugin/Tabular.vim"
        "$OFFLINE_VIM_SUPERTAB/plugin/supertab.vim"
        "$OFFLINE_VIM_NERDTREE/plugin/NERD_tree.vim"
    )

    for path in "${required_paths[@]}"; do
        if [ ! -f "$path" ]; then
            warn "Offline source missing (some features may not work): $path"
        fi
    done

    # Check if .oh-my-zsh is bundled (for full offline Oh My Zsh install)
    if [ -d "$SCRIPT_DIR/.oh-my-zsh" ] && [ -f "$SCRIPT_DIR/.oh-my-zsh/oh-my-zsh.sh" ]; then
        BUNDLED_OMZ=true
        ok "Bundled Oh My Zsh found"
    else
        BUNDLED_OMZ=false
        warn "No bundled Oh My Zsh found in repository."
        warn "If Oh My Zsh is not already installed, the setup will be incomplete."
    fi

    ok "Pre-flight check passed"
}

# ──────────────────────────────────────────────
# Step 2: Backup existing configuration
# ──────────────────────────────────────────────
backup_existing() {
    info "Step 2: Backing up existing configuration..."

    local items=()
    for f in "${CONFIG_FILES[@]}"; do
        items+=("$HOME/$f")
    done
    items+=("$HOME/.vim")
    items+=("$OH_MY_ZSH_DIR/custom")

    local has_backup=false
    for item in "${items[@]}"; do
        if [ -e "$item" ] && [ ! -L "$item" ]; then
            backup_file "$item"
            has_backup=true
        fi
    done

    if $has_backup; then
        ok "Backup saved to: $BACKUP_DIR"
    else
        info "No existing configuration to back up"
    fi
}

# ──────────────────────────────────────────────
# Step 3: Deploy configuration files
# ──────────────────────────────────────────────
deploy_config_files() {
    info "Step 3: Deploying configuration files..."

    for f in "${CONFIG_FILES[@]}"; do
        local src="$SCRIPT_DIR/$f"
        local dst="$HOME/$f"

        check_path_exists "$src" "Config file $f"

        if [ -f "$dst" ]; then
            if diff -q "$src" "$dst" &>/dev/null; then
                info "Skipping $f (already up to date)"
                continue
            fi
        fi

        run cp "$src" "$dst"
        ok "Deployed $f"
    done
}

# ──────────────────────────────────────────────
# Step 4: Install Oh My Zsh (offline)
# ──────────────────────────────────────────────
install_oh_my_zsh() {
    info "Step 4: Installing Oh My Zsh (offline)..."

    if [ -d "$OH_MY_ZSH_DIR" ] && [ -f "$OH_MY_ZSH_DIR/oh-my-zsh.sh" ]; then
        ok "Oh My Zsh already installed at $OH_MY_ZSH_DIR"
        return
    fi

    if ! $BUNDLED_OMZ; then
        warn "Cannot install Oh My Zsh offline - no bundled copy found."
        warn "Please install Oh My Zsh manually, then re-run this script."
        return
    fi

    run cp -r "$SCRIPT_DIR/.oh-my-zsh" "$OH_MY_ZSH_DIR"
    ok "Oh My Zsh installed from bundled copy"
}

# ──────────────────────────────────────────────
# Step 5: Install Zsh plugins from offline_src
# ──────────────────────────────────────────────
install_zsh_plugins() {
    info "Step 5: Installing Zsh plugins from offline_src..."

    run mkdir -p "$ZSH_CUSTOM_PLUGINS"

    # incr plugin (bundled in .oh-my-zsh/custom/plugins/)
    if [ -d "$SCRIPT_DIR/.oh-my-zsh/custom/plugins/incr" ]; then
        if [ ! -d "$ZSH_CUSTOM_PLUGINS/incr" ]; then
            run cp -r "$SCRIPT_DIR/.oh-my-zsh/custom/plugins/incr" "$ZSH_CUSTOM_PLUGINS/incr"
            ok "Installed incr plugin"
        else
            info "incr plugin already installed"
        fi
    else
        warn "incr plugin not found in repository"
    fi

    # zsh-autosuggestions
    if [ -f "$OFFLINE_ZSH_AUTOSUGGESTIONS/zsh-autosuggestions.plugin.zsh" ]; then
        if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then
            run cp -r "$OFFLINE_ZSH_AUTOSUGGESTIONS" "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"
            ok "Installed zsh-autosuggestions"
        else
            info "zsh-autosuggestions already installed"
        fi
    else
        warn "zsh-autosuggestions offline source not found"
    fi

    # zsh-syntax-highlighting
    if [ -d "$OFFLINE_ZSH_SYNTAX_HIGHLIGHTING" ]; then
        if is_dir_populated "$OFFLINE_ZSH_SYNTAX_HIGHLIGHTING"; then
            if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
                run cp -r "$OFFLINE_ZSH_SYNTAX_HIGHLIGHTING" "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"
                ok "Installed zsh-syntax-highlighting"
            else
                info "zsh-syntax-highlighting already installed"
            fi
        else
            warn "zsh-syntax-highlighting offline source is empty (submodule not initialized)"
        fi
    else
        warn "zsh-syntax-highlighting offline source not found"
    fi
}

# ──────────────────────────────────────────────
# Step 6: Install Vim plugins from offline_src
# ──────────────────────────────────────────────
install_vim_plugins() {
    info "Step 6: Installing Vim plugins from offline_src..."

    run mkdir -p "$VIM_PACK_DIR"

    # tabular
    if [ -f "$OFFLINE_VIM_TABULAR/plugin/Tabular.vim" ]; then
        if [ ! -d "$VIM_PACK_DIR/tabular" ]; then
            run cp -r "$OFFLINE_VIM_TABULAR" "$VIM_PACK_DIR/tabular"
            ok "Installed tabular plugin"
        else
            # Check if existing tabular is empty (submodule not initialized)
            if ! is_dir_populated "$VIM_PACK_DIR/tabular"; then
                run rm -rf "$VIM_PACK_DIR/tabular"
                run cp -r "$OFFLINE_VIM_TABULAR" "$VIM_PACK_DIR/tabular"
                ok "Restored tabular plugin from offline_src"
            else
                info "tabular plugin already installed"
            fi
        fi
    else
        warn "tabular offline source not found"
    fi

    # supertab
    if [ -f "$OFFLINE_VIM_SUPERTAB/plugin/supertab.vim" ]; then
        if [ ! -d "$VIM_PACK_DIR/supertab" ]; then
            run cp -r "$OFFLINE_VIM_SUPERTAB" "$VIM_PACK_DIR/supertab"
            ok "Installed supertab plugin"
        else
            if ! is_dir_populated "$VIM_PACK_DIR/supertab"; then
                run rm -rf "$VIM_PACK_DIR/supertab"
                run cp -r "$OFFLINE_VIM_SUPERTAB" "$VIM_PACK_DIR/supertab"
                ok "Restored supertab plugin from offline_src"
            else
                info "supertab plugin already installed"
            fi
        fi
    else
        warn "supertab offline source not found"
    fi

    # nerdtree
    if [ -f "$OFFLINE_VIM_NERDTREE/plugin/NERD_tree.vim" ]; then
        if [ ! -d "$VIM_PACK_DIR/nerdtree" ]; then
            run cp -r "$OFFLINE_VIM_NERDTREE" "$VIM_PACK_DIR/nerdtree"
            ok "Installed nerdtree plugin"
        else
            if ! is_dir_populated "$VIM_PACK_DIR/nerdtree"; then
                run rm -rf "$VIM_PACK_DIR/nerdtree"
                run cp -r "$OFFLINE_VIM_NERDTREE" "$VIM_PACK_DIR/nerdtree"
                ok "Restored nerdtree plugin from offline_src"
            else
                info "nerdtree plugin already installed"
            fi
        fi
    else
        warn "nerdtree offline source not found"
    fi
}

# ──────────────────────────────────────────────
# Step 7: Deploy bundled .vim/ directory
# ──────────────────────────────────────────────
deploy_vim_dir() {
    info "Step 7: Deploying bundled .vim/ directory..."

    if [ -d "$SCRIPT_DIR/.vim" ] && [ -d "$SCRIPT_DIR/.vim/pack" ]; then
        if [ ! -d "$HOME/.vim/pack" ]; then
            run cp -r "$SCRIPT_DIR/.vim" "$HOME/"
            ok "Deployed .vim/ directory"
        else
            info ".vim/ already exists, merging plugin packs"
            run mkdir -p "$VIM_PACK_DIR"
            if is_dir_populated "$SCRIPT_DIR/.vim/pack/plugins/start/tabular" && \
               ! is_dir_populated "$VIM_PACK_DIR/tabular"; then
                run cp -r "$SCRIPT_DIR/.vim/pack/plugins/start/tabular" "$VIM_PACK_DIR/tabular"
                ok "Merged tabular from bundled .vim/"
            fi
            if is_dir_populated "$SCRIPT_DIR/.vim/pack/plugins/start/supertab" && \
               ! is_dir_populated "$VIM_PACK_DIR/supertab"; then
                run cp -r "$SCRIPT_DIR/.vim/pack/plugins/start/supertab" "$VIM_PACK_DIR/supertab"
                ok "Merged supertab from bundled .vim/"
            fi
            if is_dir_populated "$SCRIPT_DIR/.vim/pack/plugins/start/nerdtree" && \
               ! is_dir_populated "$VIM_PACK_DIR/nerdtree"; then
                run cp -r "$SCRIPT_DIR/.vim/pack/plugins/start/nerdtree" "$VIM_PACK_DIR/nerdtree"
                ok "Merged nerdtree from bundled .vim/"
            fi
        fi
    else
        info "No bundled .vim/ directory found (relying on offline_src)"
    fi
}

# ──────────────────────────────────────────────
# Step 8: Deploy Emacs elisp files
# ──────────────────────────────────────────────
deploy_elisp() {
    info "Step 8: Deploying Emacs elisp files..."

    if [ -d "$SCRIPT_DIR/elisp" ] && [ "$(ls -A "$SCRIPT_DIR/elisp" 2>/dev/null | wc -l)" -gt 0 ]; then
        run mkdir -p "$HOME/elisp"
        for f in "$SCRIPT_DIR/elisp"/*; do
            local basename_f
            basename_f="$(basename "$f")"
            if [ ! -e "$HOME/elisp/$basename_f" ]; then
                run cp -r "$f" "$HOME/elisp/$basename_f"
                ok "Deployed elisp/$basename_f"
            else
                info "elisp/$basename_f already exists"
            fi
        done
    else
        info "No elisp files to deploy"
    fi
}

# ──────────────────────────────────────────────
# Step 9: Install Verible from offline_src (optional)
# ──────────────────────────────────────────────
install_verible() {
    info "Step 9: Installing Verible from offline_src..."

    if command -v verible-verilog-ls &>/dev/null; then
        warn "Verible already installed: $(verible-verilog-ls --version 2>&1 | head -1), skipping"
        return
    fi

    if [[ -z "$VERIBLE_TARBALL" ]]; then
        info "No Verible tarball found in offline_src/ (skipping)"
        info "  To include Verible, place verible-*-linux-static-x86_64.tar.gz in offline_src/"
        return
    fi

    if $DRY_RUN; then
        echo "    Would install Verible from: $VERIBLE_TARBALL"
        return
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    info "Extracting Verible from $(basename "$VERIBLE_TARBALL")..."
    tar -xzf "$VERIBLE_TARBALL" -C "$tmp_dir"

    local extracted_dir
    extracted_dir="$(find "$tmp_dir" -maxdepth 1 -type d -name "verible-*" | head -1)"
    if [[ -z "$extracted_dir" ]]; then
        warn "Failed to find extracted Verible directory, skipping"
        rm -rf "$tmp_dir"
        return
    fi

    info "Installing Verible binaries to /usr/local/bin/..."
    cp "$extracted_dir"/bin/* /usr/local/bin/
    rm -rf "$tmp_dir"
    ok "Verible installed from offline_src"
}

# ──────────────────────────────────────────────
# Step 10: Post-install checks
# ──────────────────────────────────────────────
post_install_checks() {
    info "Step 10: Post-install checks..."

    local all_ok=true

    # Check zsh
    if command -v zsh &>/dev/null; then
        ok "zsh: $(zsh --version 2>&1 | head -1)"
    else
        warn "zsh is not installed. Run: sudo apt-get install zsh"
        all_ok=false
    fi

    # Check Oh My Zsh
    if [ -f "$OH_MY_ZSH_DIR/oh-my-zsh.sh" ]; then
        ok "Oh My Zsh: installed"
    else
        warn "Oh My Zsh is not installed"
        all_ok=false
    fi

    # Check Vim
    if command -v vim &>/dev/null; then
        ok "vim: $(vim --version 2>&1 | head -1)"
    else
        warn "vim is not installed. Run: sudo apt-get install vim"
        all_ok=false
    fi

    # Check Zsh plugins
    for plugin in incr zsh-autosuggestions zsh-syntax-highlighting; do
        if [ -d "$ZSH_CUSTOM_PLUGINS/$plugin" ]; then
            ok "Zsh plugin: $plugin"
        else
            warn "Zsh plugin missing: $plugin"
            all_ok=false
        fi
    done

    # Check Vim plugins
    for plugin in tabular supertab nerdtree; do
        if [ -d "$VIM_PACK_DIR/$plugin" ] && is_dir_populated "$VIM_PACK_DIR/$plugin"; then
            ok "Vim plugin: $plugin"
        else
            warn "Vim plugin missing: $plugin"
            all_ok=false
        fi
    done

    # Check .zshrc loading
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "oh-my-zsh.sh" "$HOME/.zshrc" 2>/dev/null; then
            ok ".zshrc references Oh My Zsh"
        else
            warn ".zshrc may not reference Oh My Zsh correctly"
        fi
    fi

    # Check Verible
    if command -v verible-verilog-ls &>/dev/null; then
        ok "Verible: $(verible-verilog-ls --version 2>&1 | head -1)"
    else
        info "Verible not installed (optional, for Verilog/SystemVerilog development)"
    fi

    echo ""
    if $all_ok; then
        ok "All checks passed"
    else
        warn "Some components are missing (see above)"
    fi
}

# ──────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────
show_help() {
    cat <<EOF
setup_offline.sh - Offline Development Environment Setup

Usage:  ./setup_offline.sh [OPTION]

Options:
  --dry-run   Preview what the script would do, without making changes
  --help      Show this help message

This script installs and configures development tools using only local files.
No network access is required.

It deploys:
  - Shell configuration (.zshrc)
  - Editor configuration (.vimrc)
  - Git configuration (.gitconfig, .gitignore)
  - Oh My Zsh (from bundled .oh-my-zsh/)
  - Zsh plugins (from offline_src/)
  - Vim plugins (from offline_src/)
  - Emacs verilog-mode (from elisp/)
  - Verible (from offline_src/verible-*.tar.gz, optional)

Run this script from the root of the home_rc repository:
  cd /path/to/home_rc
  chmod +x setup_offline.sh
  ./setup_offline.sh
EOF
    exit 0
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --dry-run)
            DRY_RUN=true
            echo ""
            echo -e "${YELLOW}[DRY RUN]${NC} No changes will be made"
            echo ""
            ;;
    esac

    echo ""
    echo "=============================================="
    echo "  home_rc - Offline Environment Setup"
    echo "  $TIMESTAMP"
    echo "=============================================="
    echo ""

    preflight_check
    echo ""
    backup_existing
    echo ""
    deploy_config_files
    echo ""
    install_oh_my_zsh
    echo ""
    install_zsh_plugins
    echo ""
    deploy_vim_dir
    echo ""
    install_vim_plugins
    echo ""
    deploy_elisp
    echo ""
    install_verible
    echo ""
    post_install_checks

    echo ""
    echo "=============================================="
    if $DRY_RUN; then
        echo "  Dry run complete. No changes made."
    else
        echo "  Setup complete!"
        echo ""
        echo "  Next steps:"
        echo "    1. Restart your terminal or run: exec zsh"
        echo "    2. Review ~/.zshrc and customize as needed"
        echo "    3. If zsh is not your default shell:"
        echo "       chsh -s \$(which zsh)"
        echo "    4. Verify Verible (if installed): verible-verilog-ls --version"
        echo ""
        echo "  Backup saved to: $BACKUP_DIR"
    fi
    echo "=============================================="
    echo ""
}

main "$@"