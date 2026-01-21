#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$(dirname "$SCRIPT_DIR")" # Parent directory (modules/)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║             🚀 UBUNTU SETUP WIZARD - First Run                     ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Welcome! This wizard will help you set up your new Ubuntu installation."
echo "Choose a profile or customize your installation."
echo ""

# Profile selection
echo -e "${YELLOW}Select a profile:${NC}"
echo ""
echo "  [1] 🔧 DevOps Engineer"
echo "      Docker, Terraform, AWS CLI, Azure CLI, kubectl"
echo "      Python, Node.js, Go, Zsh, terminal tools"
echo ""
echo "  [2] 💻 Backend Developer"
echo "      VS Code, Cursor, JetBrains, Python, Node.js, Go"
echo "      Docker, Git, Zsh, terminal tools"
echo ""
echo "  [3] 🎨 Frontend Developer"
echo "      VS Code, Cursor, Node.js, Zsh"
echo "      Chrome, terminal tools"
echo ""
echo "  [4] 📦 Full Stack (All)"
echo "      Everything included"
echo ""
echo "  [5] 🛠️  Custom"
echo "      Choose what to install"
echo ""

read -p "Select profile [1-5]: " profile

run_module() {
    local module="$1"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installing: $module${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check install modules
    if [ -f "$MODULES_DIR/install/$module.sh" ]; then
        bash "$MODULES_DIR/install/$module.sh"
    # Check utility modules
    elif [ -f "$MODULES_DIR/utils/$module.sh" ]; then
        bash "$MODULES_DIR/utils/$module.sh"
    else
        echo "⚠️ Module not found: $module"
    fi
}

case "$profile" in
    1) # DevOps
        echo ""
        echo -e "${CYAN}🔧 Installing DevOps Engineer profile...${NC}"
        run_module "devops"
        run_module "azure-cli"
        run_module "python"
        run_module "nodejs"
        run_module "golang"
        run_module "zsh"
        run_module "terminal-tools"
        run_module "ssh-keygen"
        run_module "k8s"
        run_module "apps"
        ;;
    2) # Backend
        echo ""
        echo -e "${CYAN}💻 Installing Backend Developer profile...${NC}"
        run_module "vscode"
        run_module "cursor"
        run_module "jetbrains"
        run_module "dbeaver"
        run_module "python"
        run_module "nodejs"
        run_module "golang"
        run_module "devops"
        run_module "zsh"
        run_module "terminal-tools"
        run_module "apps"
        ;;
    3) # Frontend
        echo ""
        echo -e "${CYAN}🎨 Installing Frontend Developer profile...${NC}"
        run_module "browsers"
        run_module "vscode"
        run_module "cursor"
        run_module "nodejs"
        run_module "zsh"
        run_module "terminal-tools"
        ;;
    4) # Full stack
        echo ""
        echo -e "${CYAN}📦 Installing Full Stack (All) profile...${NC}"
        run_module "browsers"
        run_module "dock"
        run_module "vscode"
        run_module "cursor"
        run_module "antigravity"
        run_module "jetbrains"
        run_module "ibus-unikey"
        run_module "devops"
        run_module "azure-cli"
        run_module "k8s"
        run_module "dbeaver"
        run_module "nodejs"
        run_module "python"
        run_module "golang"
        run_module "zsh"
        run_module "terminal-tools"
        run_module "gnome-extensions"
        run_module "ssh-keygen"
        run_module "apps"
        ;;
    5) # Custom
        echo ""
        echo -e "${CYAN}🛠️  Custom Installation${NC}"
        echo "Select components to install (y/n for each):"
        echo ""
        
        components=(
            "browsers:🌐 Browsers (Edge + Chrome)"
            "dock:🖥️ GNOME Dock Configuration"
            "vscode:📝 VS Code"
            "cursor:🔮 Cursor Editor"
            "antigravity:🌌 Antigravity"
            "jetbrains:🛠️ JetBrains Toolbox"
            "ibus-unikey:🇻🇳 IBus Unikey"
            "devops:🐳 DevOps Tools (Docker, Terraform, AWS)"
            "azure-cli:☁️ Azure CLI"
            "k8s:☸️  Kubernetes Pack (kubectl, helm, k9s)"
            "dbeaver:🗄️  DBeaver CE"
            "apps:💬 Communication & Productivity"
            "nodejs:📦 Node.js (NVM)"
            "python:🐍 Python (Pyenv)"
            "golang:🐹 Go"
            "zsh:🐚 Zsh + Oh My Zsh"
            "terminal-tools:🔧 Terminal Tools"
            "gnome-extensions:🧩 GNOME Extensions"
            "ssh-keygen:🔑 SSH Key Setup"
            "vmware:🖥️  VMware Workstation 17 Pro"
        )
        
        selected=()
        for comp in "${components[@]}"; do
            module="${comp%%:*}"
            desc="${comp#*:}"
            read -p "  $desc? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                selected+=("$module")
            fi
        done
        
        echo ""
        echo "Installing selected components..."
        for module in "${selected[@]}"; do
            run_module "$module"
        done
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📝 Next steps:"
echo "   1. Log out and log back in for all changes to take effect"
echo "   2. Run 'source ~/.bashrc' or 'source ~/.zshrc' for immediate changes"
echo "   3. Run './setup.sh' anytime to access the full menu"
echo ""
