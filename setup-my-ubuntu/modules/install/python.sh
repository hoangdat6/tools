#!/usr/bin/env bash
set -e

PYENV_ROOT="$HOME/.pyenv"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

load_pyenv() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
}

show_python_menu() {
    echo -e "${BLUE}"
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                      🐍 PYTHON MANAGER (PYENV)                     │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  📥 Install Pyenv (if not installed)                          │"
    echo "│  [2]  📋 List installed Python versions                            │"
    echo "│  [3]  📋 List available Python versions                            │"
    echo "│  [4]  ⬇️  Install a specific Python version                         │"
    echo "│  [5]  🔄 Switch Python version (global)                            │"
    echo "│  [6]  📁 Set Python version for current directory                  │"
    echo "│  [7]  🗑️  Uninstall a Python version                                │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back                                                      │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
}

install_pyenv() {
    if [ -d "$PYENV_ROOT" ]; then
        echo -e "${YELLOW}Pyenv is already installed at $PYENV_ROOT${NC}"
        load_pyenv
        echo "Pyenv version: $(pyenv --version)"
        return
    fi

    echo "📥 Installing build dependencies..."
    sudo apt update
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev

    echo "📥 Installing Pyenv..."
    curl https://pyenv.run | bash

    # Add to shell config
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

    if ! grep -q "PYENV_ROOT" "$SHELL_RC" 2>/dev/null; then
        cat >> "$SHELL_RC" << 'EOF'

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
    fi

    load_pyenv
    echo -e "${GREEN}✅ Pyenv installed!${NC}"
}

list_installed() {
    load_pyenv
    echo -e "${BLUE}📋 Installed Python versions:${NC}"
    pyenv versions
}

list_available() {
    load_pyenv
    echo -e "${BLUE}📋 Available Python versions (3.x):${NC}"
    pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -20
    echo ""
    echo "Use 'pyenv install --list' for all versions"
}

install_version() {
    load_pyenv
    echo -e "${BLUE}Recent Python 3.x versions:${NC}"
    pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -10
    echo ""
    read -p "Enter version to install (e.g. 3.12.0, 3.11.6): " version
    if [ -n "$version" ]; then
        echo "Installing Python $version (this may take a few minutes)..."
        pyenv install "$version"
        echo -e "${GREEN}✅ Python $version installed!${NC}"
    fi
}

switch_global() {
    load_pyenv
    echo -e "${BLUE}Installed versions:${NC}"
    pyenv versions
    echo ""
    read -p "Enter version to set as global: " version
    if [ -n "$version" ]; then
        pyenv global "$version"
        echo -e "${GREEN}✅ Global Python set to $version${NC}"
        python --version
    fi
}

set_local() {
    load_pyenv
    echo -e "${BLUE}Installed versions:${NC}"
    pyenv versions
    echo ""
    read -p "Enter version for current directory: " version
    if [ -n "$version" ]; then
        pyenv local "$version"
        echo -e "${GREEN}✅ Local Python set to $version${NC}"
        echo "Created .python-version file"
    fi
}

uninstall_version() {
    load_pyenv
    echo -e "${BLUE}Installed versions:${NC}"
    pyenv versions
    echo ""
    read -p "Enter version to uninstall: " version
    if [ -n "$version" ]; then
        pyenv uninstall "$version"
        echo -e "${GREEN}✅ Uninstalled Python $version${NC}"
    fi
}

# Main
main() {
    # Quick install mode (first run)
    if [ ! -d "$PYENV_ROOT" ]; then
        install_pyenv
        echo ""
        read -p "Install latest Python now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            load_pyenv
            LATEST=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
            echo "Installing Python $LATEST..."
            pyenv install "$LATEST"
            pyenv global "$LATEST"
            echo -e "${GREEN}✅ Python $LATEST installed and set as global!${NC}"
        fi
        return
    fi

    # Interactive menu
    while true; do
        show_python_menu
        read -p "Select option: " choice
        echo

        case "$choice" in
            1) install_pyenv ;;
            2) list_installed ;;
            3) list_available ;;
            4) install_version ;;
            5) switch_global ;;
            6) set_local ;;
            7) uninstall_version ;;
            [Bb]) return ;;
            *) echo "Invalid option" ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
