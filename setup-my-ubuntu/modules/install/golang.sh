#!/usr/bin/env bash
set -e

GO_INSTALL_DIR="/usr/local"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_go_menu() {
    echo -e "${BLUE}"
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                        🐹 GO (GOLANG) MANAGER                      │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  📥 Install latest Go                                         │"
    echo "│  [2]  📋 Show current Go version                                   │"
    echo "│  [3]  📋 List available Go versions                                │"
    echo "│  [4]  ⬇️  Install specific Go version                               │"
    echo "│  [5]  🗑️  Uninstall Go                                              │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back                                                      │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
}

get_latest_version() {
    curl -sL "https://go.dev/VERSION?m=text" | head -1 | sed 's/go//'
}

get_available_versions() {
    curl -sL "https://go.dev/dl/?mode=json" | jq -r '.[].version' | sed 's/go//' | head -10
}

show_current() {
    if command -v go &> /dev/null; then
        echo -e "${GREEN}Current Go version:${NC}"
        go version
        echo ""
        echo "GOROOT: $(go env GOROOT)"
        echo "GOPATH: $(go env GOPATH)"
    else
        echo -e "${YELLOW}Go is not installed${NC}"
    fi
}

install_go() {
    local version="$1"
    
    if [ -z "$version" ]; then
        version=$(get_latest_version)
        echo "Latest version: $version"
    fi

    echo "📥 Downloading Go $version..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    wget -q --show-progress "https://go.dev/dl/go${version}.linux-amd64.tar.gz"

    # Remove old installation
    sudo rm -rf "$GO_INSTALL_DIR/go"

    # Extract
    echo "Installing to $GO_INSTALL_DIR/go..."
    sudo tar -C "$GO_INSTALL_DIR" -xzf "go${version}.linux-amd64.tar.gz"

    # Cleanup
    cd ~
    rm -rf "$TEMP_DIR"

    # Add to PATH
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

    if ! grep -q "GO PATH" "$SHELL_RC" 2>/dev/null; then
        cat >> "$SHELL_RC" << 'EOF'

# GO PATH
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
    fi

    export PATH=$PATH:/usr/local/go/bin

    echo -e "${GREEN}✅ Go $version installed!${NC}"
    /usr/local/go/bin/go version
}

list_available() {
    echo -e "${BLUE}📋 Available Go versions (recent):${NC}"
    if command -v jq &> /dev/null; then
        get_available_versions
    else
        echo "Install 'jq' to list versions, or visit https://go.dev/dl/"
        echo ""
        echo "Recent versions: 1.23.4, 1.22.10, 1.21.13"
    fi
}

install_specific() {
    list_available
    echo ""
    read -p "Enter version to install (e.g. 1.23.4, 1.22.10): " version
    if [ -n "$version" ]; then
        install_go "$version"
    fi
}

uninstall_go() {
    if [ -d "$GO_INSTALL_DIR/go" ]; then
        read -p "Remove Go from $GO_INSTALL_DIR/go? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo rm -rf "$GO_INSTALL_DIR/go"
            echo -e "${GREEN}✅ Go removed${NC}"
            
            read -p "Remove GOPATH ($HOME/go)? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$HOME/go"
                echo "Removed $HOME/go"
            fi
        fi
    else
        echo -e "${YELLOW}Go is not installed${NC}"
    fi
}

# Main
main() {
    # Quick install mode (first run)
    if ! command -v go &> /dev/null && [ ! -d "$GO_INSTALL_DIR/go" ]; then
        echo "🐹 Go is not installed"
        read -p "Install latest Go? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_go
        fi
        return
    fi

    # Interactive menu
    while true; do
        show_go_menu
        read -p "Select option: " choice
        echo

        case "$choice" in
            1) install_go ;;
            2) show_current ;;
            3) list_available ;;
            4) install_specific ;;
            5) uninstall_go ;;
            [Bb]) return ;;
            *) echo "Invalid option" ;;
        esac

        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
