#!/usr/bin/env bash
# Note: No set -e here as we expect some checks to fail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 System Health Check${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

installed=0
total=0

check_tool() {
    local name="$1"
    local cmd="$2"
    local version_cmd="$3"
    
    ((total++)) || true
    if command -v "$cmd" &> /dev/null; then
        local version=$(eval "$version_cmd" 2>/dev/null | head -1 || echo "installed")
        echo -e "  ${GREEN}✅${NC} $name: $version"
        ((installed++)) || true
    else
        echo -e "  ${RED}❌${NC} $name: not installed"
    fi
}

check_dir() {
    local name="$1"
    local dir="$2"
    
    ((total++)) || true
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}✅${NC} $name: installed"
        ((installed++)) || true
    else
        echo -e "  ${RED}❌${NC} $name: not installed"
    fi
}

echo -e "${YELLOW}📦 Browsers${NC}"
check_tool "Microsoft Edge" "microsoft-edge" "microsoft-edge --version"
check_tool "Google Chrome" "google-chrome" "google-chrome --version"
echo ""

echo -e "${YELLOW}💻 Development Tools${NC}"
check_tool "VS Code" "code" "code --version"
# Cursor is installed via AppImage at ~/.local/bin/cursor
((total++)) || true
if [ -f "$HOME/.local/bin/cursor" ]; then
    echo -e "  ${GREEN}✅${NC} Cursor: installed"
    ((installed++)) || true
else
    echo -e "  ${RED}❌${NC} Cursor: not installed"
fi
check_tool "Antigravity" "antigravity" "antigravity --version"
check_dir "JetBrains Toolbox" "$HOME/.local/share/JetBrains/Toolbox"
check_tool "VMware Workstation" "vmware" "vmware --version | head -1"
echo ""

echo -e "${YELLOW}🗣️ Programming Languages${NC}"
if [ -d "$HOME/.nvm" ]; then
    source "$HOME/.nvm/nvm.sh" 2>/dev/null || true
    check_tool "Node.js (NVM)" "node" "node --version"
    # Only show actually installed versions (lines with actual version at start, may have -> prefix)
    INSTALLED_VERSIONS=$(nvm list --no-colors 2>/dev/null | grep -E "^\s*(->)?\s*v[0-9]" | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | sort -uV | tr '\n' ' ')
    echo "     Versions: $INSTALLED_VERSIONS"
else
    ((total++)) || true
    echo -e "  ${RED}❌${NC} Node.js (NVM): not installed"
fi

if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
    check_tool "Python (Pyenv)" "python" "python --version"
    echo "     Versions: $(pyenv versions --bare 2>/dev/null | tr '\n' ' ' || echo 'none')"
else
    ((total++)) || true
    echo -e "  ${RED}❌${NC} Python (Pyenv): not installed"
fi

check_tool "Go" "go" "go version"
echo ""

echo -e "${YELLOW}🐳 DevOps Tools${NC}"
check_tool "Git" "git" "git --version"
check_tool "Docker" "docker" "docker --version"
check_tool "Docker Compose" "docker" "docker compose version"
check_tool "Terraform" "terraform" "terraform version | head -1"
check_tool "AWS CLI" "aws" "aws --version"
check_tool "Azure CLI" "az" "az --version | head -1"
check_tool "kubectl" "kubectl" "kubectl version --client --short 2>/dev/null | head -1"
# helm writes to stderr for version --short in some versions, and stdout in others
check_tool "Helm" "helm" "helm version --short"
check_tool "k9s" "k9s" "k9s version --short | head -1"
echo ""

echo -e "${YELLOW}🗄️  Database & Apps${NC}"
check_tool "DBeaver" "dbeaver" "dbeaver -version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo 'installed'"
# Snap apps might not be in PATH for command -v sometimes, but usually are /snap/bin
check_tool "Telegram" "telegram-desktop" "echo 'installed'"
check_tool "Postman" "postman" "echo 'installed'"
echo ""

echo -e "${YELLOW}🐚 Shell & Terminal${NC}"
check_tool "Zsh" "zsh" "zsh --version"
check_dir "Oh My Zsh" "$HOME/.oh-my-zsh"
check_tool "ripgrep" "rg" "rg --version | head -1"
check_tool "jq" "jq" "jq --version"
check_tool "yq" "yq" "yq --version"
check_tool "htop" "htop" "htop --version | head -1"
check_tool "flameshot" "flameshot" "flameshot --version 2>&1 | head -1"
echo ""

echo -e "${YELLOW}🔑 SSH${NC}"
if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "  ${GREEN}✅${NC} SSH Key: configured"
    ssh-add -l 2>/dev/null | head -3 || echo "     No keys loaded in agent"
else
    echo -e "  ${YELLOW}⚠️${NC} SSH Key: not configured"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📊 ${GREEN}$installed${NC}/$total tools installed"
echo ""

