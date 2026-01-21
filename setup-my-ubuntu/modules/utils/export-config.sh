#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

EXPORT_FILE="$HOME/.setup-tools-config.json"

echo -e "${BLUE}📦 Export/Import Tool Configuration${NC}"
echo ""

export_config() {
    echo "Exporting installed tools configuration..."
    
    local config="{\"exported_at\": \"$(date -Iseconds)\", \"tools\": {"
    local first=true
    
    # Helper to clean version strings (remove quotes, backslashes, newlines, control chars)
    clean_version() {
        local input="$1"
        # Remove JSON-breaking characters and control characters
        echo "$input" | tr -d '"\\`' | tr -d '[:cntrl:]' | sed 's/^[ \t]*//;s/[ \t]*$//'
    }

    # Helper to add tool to config
    add_tool() {
        local name="$1"
        local installed="$2"
        local version_raw="$3"
        local version=""
        
        if [ "$installed" = true ]; then
             version=$(clean_version "$version_raw")
        fi
        
        if [ "$first" = true ]; then
            first=false
        else
            config+=","
        fi
        config+="\"$name\": {\"installed\": $installed, \"version\": \"$version\"}"
    }
    
    # Browsers
    command -v microsoft-edge &>/dev/null && add_tool "edge" true "$(microsoft-edge --version 2>/dev/null)" || add_tool "edge" false ""
    command -v google-chrome &>/dev/null && add_tool "chrome" true "$(google-chrome --version 2>/dev/null)" || add_tool "chrome" false ""
    
    # Dev tools
    command -v code &>/dev/null && add_tool "vscode" true "$(code --version 2>/dev/null | head -1)" || add_tool "vscode" false ""
    [ -f "$HOME/.local/bin/cursor" ] && add_tool "cursor" true "installed" || add_tool "cursor" false ""
    command -v antigravity &>/dev/null && add_tool "antigravity" true "$(antigravity --version 2>/dev/null)" || add_tool "antigravity" false ""
    [ -d "$HOME/.local/share/JetBrains/Toolbox" ] && add_tool "jetbrains" true "installed" || add_tool "jetbrains" false ""
    
    # Languages
    # Correctly capture node versions - ensure no subshell inheritance issues
    if [ -d "$HOME/.nvm" ]; then
        NODE_VERSIONS=$(bash -c 'source $HOME/.nvm/nvm.sh && nvm list --no-colors' 2>/dev/null | grep -E "^\s*(->)?\s*v[0-9]" | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | sort -uV | tr '\n' ' ')
        add_tool "nodejs" true "$NODE_VERSIONS"
    else
        add_tool "nodejs" false ""
    fi

    if [ -d "$HOME/.pyenv" ]; then
        PY_VERSIONS=$(export PYENV_ROOT="$HOME/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && pyenv versions --bare 2>/dev/null | tr '\n' ' ')
        add_tool "python" true "$PY_VERSIONS"
    else
        add_tool "python" false ""
    fi
    
    command -v go &>/dev/null && add_tool "golang" true "$(go version 2>/dev/null | awk '{print $3}')" || add_tool "golang" false ""
    
    # Shell
    command -v zsh &>/dev/null && add_tool "zsh" true "$(zsh --version 2>/dev/null)" || add_tool "zsh" false ""
    
    # DevOps
    command -v docker &>/dev/null && add_tool "docker" true "$(docker --version 2>/dev/null)" || add_tool "docker" false ""
    command -v terraform &>/dev/null && add_tool "terraform" true "$(terraform version 2>/dev/null | head -1)" || add_tool "terraform" false ""
    command -v aws &>/dev/null && add_tool "aws-cli" true "$(aws --version 2>/dev/null)" || add_tool "aws-cli" false ""
    command -v az &>/dev/null && add_tool "azure-cli" true "$(az --version 2>/dev/null | head -1)" || add_tool "azure-cli" false ""
    command -v kubectl &>/dev/null && add_tool "k8s" true "$(kubectl version --client --short 2>/dev/null | head -1)" || add_tool "k8s" false ""
    
    # Virtualization
    command -v vmware &>/dev/null && add_tool "vmware" true "$(vmware --version 2>/dev/null | head -1)" || add_tool "vmware" false ""
    
    # DB & Apps
    command -v dbeaver &>/dev/null && add_tool "dbeaver" true "$(dbeaver --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 'installed')" || add_tool "dbeaver" false ""
    snap list telegram-desktop &>/dev/null && add_tool "telegram" true "installed" || add_tool "telegram" false ""
    snap list postman &>/dev/null && add_tool "postman" true "installed" || add_tool "postman" false ""
    
    # Terminal tools
    command -v rg &>/dev/null && add_tool "ripgrep" true "$(rg --version 2>/dev/null | head -1)" || add_tool "ripgrep" false ""
    command -v jq &>/dev/null && add_tool "jq" true "$(jq --version 2>/dev/null)" || add_tool "jq" false ""
    command -v htop &>/dev/null && add_tool "htop" true "$(htop --version 2>/dev/null | head -1)" || add_tool "htop" false ""
    
    config+="}}"
    
    echo "$config" | jq '.' > "$EXPORT_FILE"
    
    echo -e "${GREEN}✅ Configuration exported to $EXPORT_FILE${NC}"
    echo ""
    echo "Installed tools:"
    cat "$EXPORT_FILE" | jq -r '.tools | to_entries[] | select(.value.installed == true) | "  ✅ \(.key)"'
    echo ""
    echo "Not installed:"
    cat "$EXPORT_FILE" | jq -r '.tools | to_entries[] | select(.value.installed == false) | "  ❌ \(.key)"'
}

import_config() {
    if [ ! -f "$EXPORT_FILE" ]; then
        echo -e "${YELLOW}No configuration file found at $EXPORT_FILE${NC}"
        return 1
    fi
    
    echo "Configuration from $(cat "$EXPORT_FILE" | jq -r '.exported_at'):"
    echo ""
    echo "Tools to install:"
    cat "$EXPORT_FILE" | jq -r '.tools | to_entries[] | select(.value.installed == true) | "  • \(.key)"'
    echo ""
    read -p "Install all marked tools? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    # Install each tool
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="$(dirname "$SCRIPT_DIR")/install"
    
    for tool in $(cat "$EXPORT_FILE" | jq -r '.tools | to_entries[] | select(.value.installed == true) | .key'); do
        case "$tool" in
            edge|chrome) bash "$INSTALL_DIR/browsers.sh" ;;
            vscode) bash "$INSTALL_DIR/vscode.sh" ;;
            cursor) bash "$INSTALL_DIR/cursor.sh" ;;
            jetbrains) bash "$INSTALL_DIR/jetbrains.sh" ;;
            nodejs) bash "$INSTALL_DIR/nodejs.sh" ;;
            python) bash "$INSTALL_DIR/python.sh" ;;
            golang) bash "$INSTALL_DIR/golang.sh" ;;
            zsh) bash "$INSTALL_DIR/zsh.sh" ;;
            docker|terraform|aws-cli) bash "$INSTALL_DIR/devops.sh" ;;
            azure-cli) bash "$INSTALL_DIR/azure-cli.sh" ;;
            k8s) bash "$INSTALL_DIR/k8s.sh" ;;
            vmware) bash "$INSTALL_DIR/vmware.sh" ;;
            dbeaver) bash "$INSTALL_DIR/dbeaver.sh" ;;
            telegram|postman) bash "$INSTALL_DIR/apps.sh" ;;
            *) echo "Unknown tool: $tool" ;;
        esac
    done
}

# Menu (only if not running inside setup.sh logic, but we need to check if it's sourced or executed?)
# Since we source this sometimes (no we don't, setup.sh calls bash script.sh), we can keep the menu.
# BUT checking if run directly vs sourced is hard without checking $0.
# Assuming run_module calls 'bash module.sh', it runs directly.
echo "[1] Export current configuration"
echo "[2] Import and install from configuration"
echo "[B] Back"
echo ""
read -p "Select option: " choice

case "$choice" in
    1) export_config ;;
    2) import_config ;;
    [Bb]) exit 0 ;;
    *) echo "Invalid option" ;;
esac
