# home_rc - Home Directory Configuration Backup

> Personal backup of shell, editor, and git configurations for development environment setup.

## Overview

This repository stores my home directory configuration files (`~/.zshrc`, `~/.vimrc`, etc.) and plugin dependencies. It is designed for quick environment restoration on Linux / WSL machines, especially for **RTL / FPGA / ASIC design workflows**.

### What's Included

| Category | Content | Description |
|----------|---------|-------------|
| **Shell** | `.zshrc`, `.oh-my-zsh/` | Zsh + Oh My Zsh with ys theme and plugins |
| **Editor** | `.vimrc`, `.vim/` | Vim with tabular & supertab plugins |
| **Git** | `.gitconfig`, `.gitignore` | Git config with GitHub credential helper |
| **Emacs** | `elisp/` | Verilog mode for HDL editing |
| **Offline** | `offline_src/` | Plugin source backups for air-gapped install |

## Quick Start

### One-Command Setup (Linux / WSL)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/schalkiii/home_rc/main/setup.sh)
```

### Step-by-Step Setup

```bash
# 1. Install dependencies
sudo apt-get update
sudo apt-get install -y zsh git vim curl wget tree

# 2. Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 3. Clone this repo and apply configs
git clone https://github.com/schalkiii/home_rc.git /tmp/home_rc
cd /tmp/home_rc
cp .zshrc ~/
cp .vimrc ~/
cp .gitignore ~/
cp -r .vim ~/
cp -r .oh-my-zsh/custom ~/.oh-my-zsh/
cp -r elisp ~/

# 4. Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# 5. Install Vim plugins
mkdir -p ~/.vim/pack/plugins/start
git clone https://github.com/godlygeek/tabular.git \
    ~/.vim/pack/plugins/start/tabular
git clone https://github.com/ervandew/supertab.git \
    ~/.vim/pack/plugins/start/supertab

# 6. Configure Git
cp .gitconfig ~/

# 7. Set zsh as default shell
chsh -s "$(which zsh)"
```

### WSL-Specific Setup

For WSL (Windows Subsystem for Linux):

1. Open PowerShell as Administrator and run:
   ```powershell
   wsl --install -d Ubuntu
   ```

2. After WSL starts, run the setup commands above, or use the enhanced script:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/schalkiii/home_rc/main/setup_wsl.sh -o setup.sh
   chmod +x setup.sh && ./setup.sh
   ```

## Configuration Details

### Shell (`.zshrc`)

- **Theme**: `ys` (a clean, informative prompt)
- **Plugins**:
  - `zsh-autosuggestions` - suggests commands based on history
  - `zsh-syntax-highlighting` - syntax highlighting as you type
  - `incr` - incremental auto-completion
- **Key Bindings**:
  - `↑/↓` - history search by typed prefix
  - `Ctrl+B` - backward word
  - `Ctrl+W` - forward word
- **Aliases**:
  - `g` → `gvim`
  - `ga` → `git add`
  - `gs` → `git status`
  - `gp` → `grep -nr --color`
  - `h` → `history`
  - `t1/t2/t3` → `tree -C -L N`
  - `ss` → `source`

### Editor (`.vimrc`)

- UTF-8 encoding with Chinese support (`zh_CN.UTF-8`)
- Dark background, 4-space indentation (expandtab)
- Custom highlights: cursor line/column, line numbers, comments, search
- **F2**: Insert modification comment with timestamp
  ```vim
  //--------Modified by Qi.Shao on 2025-01-01------v
  ```
- **F9**: Copy current file path to clipboard
- **Plugins**:
  - `tabular` - align text/table formatting
  - `supertab` - Tab key for omni-completion

### Git (`.gitconfig`)

- GitHub credential helper via `gh auth git-credential`
- Trailing whitespace detection
- Credential caching via `git-credential-store`

### Emacs (`elisp/`)

- `verilog-mode.el` - Verilog/SystemVerilog editing mode for FPGA/ASIC development

## Project Structure

```
home_rc/
├── .oh-my-zsh/                        # Oh My Zsh framework
│   └── custom/plugins/
│       ├── incr/                      # Incremental completion
│       ├── zsh-autosuggestions/       # Command suggestions
│       └── zsh-syntax-highlighting/   # Syntax highlighting
├── .vim/pack/plugins/start/
│   ├── tabular/                       # Text alignment
│   └── supertab/                      # Tab completion
├── elisp/
│   └── verilog-mode.el                # Verilog mode for Emacs
├── offline_src/                       # Plugin backups for offline use
│   ├── supertab.vmb / supertab/
│   ├── tabular/
│   ├── zsh-autosuggestions/
│   └── zsh-syntax-highlighting/
├── .gitconfig                         # Git configuration
├── .gitignore                         # Git ignore rules
├── .gitmodules                        # Git submodules
├── .vimrc                             # Vim configuration
├── .zshrc                             # Zsh configuration
├── setup.sh                           # Original setup script
└── setup_wsl.sh                       # Enhanced WSL setup script
```

## Offline Installation

If you're on an air-gapped machine, the `offline_src/` directory contains all plugin sources:

```bash
# For Vim plugins
gvim -c "%so" offline_src/supertab.vmb
cp -r offline_src/tabular ~/.vim/pack/plugins/start/
cp -r offline_src/supertab ~/.vim/pack/plugins/start/

# For Zsh plugins
cp -r offline_src/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/
cp -r offline_src/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/
```

## Recommended Enhancements

If you're forking this project, consider:

1. **Personalize `.gitconfig`** - Replace name/email with your own
2. **Custom `.zshrc`** - Comment out `ZKVM_ROOT` if not doing RTL work
3. **Add more aliases** - Extend `~/.oh-my-zsh/custom/aliases.zsh`
4. **Vim plugins** - Add more via `~/.vim/pack/plugins/start/`

## License

MIT