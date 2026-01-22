#!/usr/bin/env bash
set -e

NVM_DIR="$HOME/.nvm"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

show_node_menu() {
    echo -e "${BLUE}"
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                      📦 NODE.JS MANAGER (NVM)                      │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  📥 Install NVM (if not installed)                            │"
    echo "│  [2]  📋 List installed Node versions                              │"
    echo "│  [3]  📋 List available LTS versions                               │"
    echo "│  [4]  ⬇️  Install a specific Node version                           │"
    echo "│  [5]  🔄 Switch Node version                                       │"
    echo "│  [6]  🗑️  Uninstall a Node version                                  │"
    echo "│  [7]  ⭐ Set default Node version                                  │"
    echo "│  [8]  ⚙️  Configure NVM for all terminals                           │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back                                                      │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
}

install_nvm() {
    if [ -d "$NVM_DIR" ]; then
        echo -e "${YELLOW}NVM is already installed at $NVM_DIR${NC}"
        load_nvm
        echo "NVM version: $(nvm --version)"
        return
    fi

    echo "📥 Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    load_nvm
    
    echo ""
    echo -e "${GREEN}✅ NVM installed!${NC}"
    echo "   Version: $(nvm --version)"
}

list_installed() {
    load_nvm
    echo -e "${BLUE}📋 Installed Node versions:${NC}"
    nvm list
}

list_available() {
    load_nvm
    echo -e "${BLUE}📋 Available LTS versions:${NC}"
    nvm ls-remote --lts | tail -20
    echo ""
    echo "Use 'nvm ls-remote' to see all versions"
}

install_version() {
    load_nvm
    echo -e "${BLUE}Available LTS versions (recent):${NC}"
    nvm ls-remote --lts | tail -10
    echo ""
    read -p "Enter version to install (e.g. 20, 22, 18.19.0, --lts): " version
    if [ -n "$version" ]; then
        nvm install "$version"
        echo -e "${GREEN}✅ Node $version installed!${NC}"
    fi
}

switch_version() {
    load_nvm
    echo -e "${BLUE}Installed versions:${NC}"
    nvm list
    echo ""
    read -p "Enter version to use (e.g. 20, 22.5.1): " version
    if [ -n "$version" ]; then
        nvm use "$version"
        echo -e "${GREEN}✅ Now using Node $(node --version)${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Note: This change only applies within this script.${NC}"
        echo -e "${YELLOW}   To use this version in your terminal, run one of:${NC}"
        echo -e "   ${BLUE}source ~/.nvm/nvm.sh${NC}  (current terminal)"
        echo -e "   ${BLUE}or open a new terminal${NC}"
    fi
}

uninstall_version() {
    load_nvm
    echo -e "${BLUE}Installed versions:${NC}"
    nvm list
    echo ""
    read -p "Enter version to uninstall: " version
    if [ -n "$version" ]; then
        nvm uninstall "$version"
        echo -e "${GREEN}✅ Uninstalled Node $version${NC}"
    fi
}

set_default() {
    load_nvm
    echo -e "${BLUE}Installed versions:${NC}"
    nvm list
    echo ""
    read -p "Enter version to set as default: " version
    if [ -n "$version" ]; then
        nvm alias default "$version"
        echo -e "${GREEN}✅ Default set to $version${NC}"
    fi
}

configure_nvm_global() {
    local nvm_config='
# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
'

    local shells_configured=0
    
    # Configure for Bash
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q 'NVM_DIR' "$HOME/.bashrc"; then
            echo "$nvm_config" >> "$HOME/.bashrc"
            echo -e "${GREEN}✅ Added NVM config to ~/.bashrc${NC}"
            shells_configured=$((shells_configured + 1))
        else
            echo -e "${YELLOW}⚠️  NVM already configured in ~/.bashrc${NC}"
        fi
    fi
    
    # Configure for Zsh
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q 'NVM_DIR' "$HOME/.zshrc"; then
            echo "$nvm_config" >> "$HOME/.zshrc"
            echo -e "${GREEN}✅ Added NVM config to ~/.zshrc${NC}"
            shells_configured=$((shells_configured + 1))
        else
            echo -e "${YELLOW}⚠️  NVM already configured in ~/.zshrc${NC}"
        fi
    fi
    
    if [ $shells_configured -gt 0 ]; then
        echo ""
        echo -e "${GREEN}✅ NVM configured for all terminals!${NC}"
        echo ""
        echo -e "${BLUE}To apply changes now, run:${NC}"
        echo -e "   source ~/.bashrc   ${YELLOW}(for Bash)${NC}"
        echo -e "   source ~/.zshrc    ${YELLOW}(for Zsh)${NC}"
        echo ""
        echo -e "${BLUE}Or simply open a new terminal.${NC}"
    else
        echo ""
        echo -e "${YELLOW}NVM is already configured in your shell profiles.${NC}"
        echo -e "${BLUE}If node is still not found, try opening a new terminal.${NC}"
    fi
}

# Main
main() {
    # Quick install mode (no args or first run)
    if [ ! -d "$NVM_DIR" ]; then
        install_nvm
        echo ""
        read -p "Install Node.js LTS now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            load_nvm
            nvm install --lts
            nvm alias default node
            echo -e "${GREEN}✅ Node.js LTS installed!${NC}"
        fi
        return
    fi

    # Interactive menu
    while true; do
        show_node_menu
        read -p "Select option: " choice
        echo

        case "$choice" in
            1) install_nvm ;;
            2) list_installed ;;
            3) list_available ;;
            4) install_version ;;
            5) switch_version ;;
            6) uninstall_version ;;
            7) set_default ;;
            8) configure_nvm_global ;;
            [Bb]) return ;;
            *) echo "Invalid option" ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
