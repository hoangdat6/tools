#!/usr/bin/env bash
set -e

# ╔════════════════════════════════════════════════════════════════════╗
# ║                    🚀 UBUNTU SETUP TOOL                            ║
# ║                     by dathv2                                      ║
# ╚════════════════════════════════════════════════════════════════════╝

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LIB_DIR="$SCRIPT_DIR/lib"

# Source common functions
if [ -f "$LIB_DIR/common.sh" ]; then
    source "$LIB_DIR/common.sh"
else
    echo "Error: lib/common.sh not found!"
    exit 1
fi

run_module() {
    local module="$1"
    local module_path=""
    
    # Check install modules
    if [ -f "$MODULES_DIR/install/$module.sh" ]; then
        module_path="$MODULES_DIR/install/$module.sh"
    # Check utility modules
    elif [ -f "$MODULES_DIR/utils/$module.sh" ]; then
        module_path="$MODULES_DIR/utils/$module.sh"
    # Legacy check (if any left in root modules)
    elif [ -f "$MODULES_DIR/$module.sh" ]; then
        module_path="$MODULES_DIR/$module.sh"
    fi
    
    if [ -n "$module_path" ]; then
        print_info "Running module: $module"
        bash "$module_path"
        print_success "Module $module completed!"
    else
        print_error "Module not found: $module"
        return 1
    fi
}

run_uninstall() {
    local module="$1"
    local uninstall_path="$MODULES_DIR/uninstall/$module.sh"
    
    if [ -f "$uninstall_path" ]; then
        print_warning "Uninstalling: $module"
        bash "$uninstall_path"
        print_success "Uninstall $module completed!"
    else
        print_error "Uninstall script not found: $uninstall_path"
        return 1
    fi
}

show_menu() {
    echo -e "${YELLOW}"
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                        INSTALLATION MENU                           │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  🌐 Browsers (Edge + Chrome)                                  │"
    echo "│  [2]  🖥️  GNOME Dock Configuration                                 │"
    echo "│  [3]  📝 VS Code                                                   │"
    echo "│  [4]  🔮 Cursor Editor                                             │"
    echo "│  [5]  🌌 Antigravity                                               │"
    echo "│  [6]  🛠️  JetBrains Toolbox                                         │"
    echo "│  [7]  🇻🇳 IBus Unikey (Vietnamese Input)                            │"
    echo "│  [8]  🐳 DevOps Tools (Docker, Terraform, AWS CLI, Portainer)      │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [9]  📦 Node.js (NVM)                                             │"
    echo "│  [10] 🐍 Python (Pyenv)                                            │"
    echo "│  [11] 🐹 Go (Golang)                                               │"
    echo "│  [12] 🐚 Zsh + Oh My Zsh                                           │"
    echo "│  [13] 🔧 Terminal Tools (rg, jq, yq, htop, flameshot...)           │"
    echo "│  [14] 🧩 GNOME Extensions (System Monitor, Vitals...)              │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [15] ☁️  Azure CLI                                                 │"
    echo "│  [16] 🔑 SSH Key Setup                                             │"
    echo "│  [17] 🖥️  VMware Workstation 17 Pro                                 │"
    echo "│  [18] ☸️  Kubernetes Pack (kubectl, helm, k9s)                      │"
    echo "│  [19] 🗄️  DBeaver (Database Client)                                 │"
    echo "│  [20] 💬 Communication & Productivity (Telegram, Postman)          │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [W]  🧙 Wizard Mode (Profile-based setup)                         │"
    echo "│  [H]  🔍 Health Check (Show installed tools)                       │"
    echo "│  [E]  📦 Export/Import Config                                      │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [A]  📦 Install ALL                                               │"
    echo "│  [D]  💻 Dev Tools Only (VSCode, Cursor, Antigravity, JetBrains)   │"
    echo "│  [L]  🗣️  Languages Only (Node, Python, Go)                         │"
    echo "│  [O]  🔧 DevOps Only (Docker, Terraform, AWS, Portainer)           │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [U]  🗑️  Uninstall Menu                                            │"
    echo "│  [Q]  ❌ Quit                                                       │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
}

show_uninstall_menu() {
    echo -e "${RED}"
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                        🗑️ UNINSTALL MENU                            │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  🌐 Browsers (Edge + Chrome)                                  │"
    echo "│  [3]  📝 VS Code                                                   │"
    echo "│  [4]  🔮 Cursor Editor                                             │"
    echo "│  [5]  🌌 Antigravity                                               │"
    echo "│  [6]  🛠️  JetBrains Toolbox                                         │"
    echo "│  [7]  🇻🇳 IBus Unikey                                               │"
    echo "│  [8]  🐳 DevOps Tools                                              │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [9]  📦 Node.js (NVM)                                             │"
    echo "│  [10] 🐍 Python (Pyenv)                                            │"
    echo "│  [11] 🐹 Go (Golang)                                               │"
    echo "│  [12] 🐚 Zsh + Oh My Zsh                                           │"
    echo "│  [13] 🔧 Terminal Tools                                            │"
    echo "│  [14] 🧩 GNOME Extensions                                          │"
    echo "│  [17] 🖥️  VMware Workstation                                        │"
    echo "│  [18] ☸️  Kubernetes Pack                                           │"
    echo "│  [19] 🗄️  DBeaver                                                   │"
    echo "│  [20] 💬 Communication Apps                                        │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back to Main Menu                                         │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    read -p "Select to uninstall: " uchoice
    echo
    
    case "$uchoice" in
        1) run_uninstall "browsers" ;;
        3) run_uninstall "vscode" ;;
        4) run_uninstall "cursor" ;;
        5) run_uninstall "antigravity" ;;
        6) run_uninstall "jetbrains" ;;
        7) run_uninstall "ibus-unikey" ;;
        8) run_uninstall "devops" ;;
        9) run_uninstall "nodejs" ;;
        10) run_uninstall "python" ;;
        11) run_uninstall "golang" ;;
        12) run_uninstall "zsh" ;;
        13) run_uninstall "terminal-tools" ;;
        14) run_uninstall "gnome-extensions" ;;
        17) run_uninstall "vmware" ;;
        18) run_uninstall "k8s" ;;
        19) run_uninstall "dbeaver" ;;
        20) run_uninstall "apps" ;;
        [Bb]) return ;;
        *)
            print_error "Invalid option: $uchoice"
            ;;
    esac
}

# ====== MAIN ======
main() {
    print_header
    
    # Check if running with arguments
    if [ $# -gt 0 ]; then
        case "$1" in
            --all|-a)
                install_all
                exit 0
                ;;
            --dev|-d)
                install_dev_tools
                exit 0
                ;;
            --devops|-o)
                install_devops
                exit 0
                ;;
            --wizard|-w)
                run_module "wizard"
                exit 0
                ;;
            --health|-c)
                run_module "health-check"
                exit 0
                ;;
            --export|-e)
                run_module "export-config"
                exit 0
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --uninstall|-r)
                if [ -n "$2" ]; then
                    run_uninstall "$2"
                else
                    print_error "Usage: ./setup.sh --uninstall <module>"
                fi
                exit 0
                ;;
            *)
                run_module "$1"
                exit 0
                ;;
        esac
    fi
    
    # Interactive menu
    while true; do
        show_menu
        read -p "Select an option: " choice
        echo
        
        case "$choice" in
            1) run_module "browsers" ;;
            2) run_module "dock" ;;
            3) run_module "vscode" ;;
            4) run_module "cursor" ;;
            5) run_module "antigravity" ;;
            6) run_module "jetbrains" ;;
            7) run_module "ibus-unikey" ;;
            8) run_module "devops" ;;
            9) run_module "nodejs" ;;
            10) run_module "python" ;;
            11) run_module "golang" ;;
            12) run_module "zsh" ;;
            13) run_module "terminal-tools" ;;
            14) run_module "gnome-extensions" ;;
            15) run_module "azure-cli" ;;
            16) run_module "ssh-keygen" ;;
            17) run_module "vmware" ;;
            18) run_module "k8s" ;;
            19) run_module "dbeaver" ;;
            20) run_module "apps" ;;
            [Ww]) run_module "wizard" ;;
            [Hh]) run_module "health-check" ;;
            [Ee]) run_module "export-config" ;;
            [Aa]) install_all ;;
            [Dd]) install_dev_tools ;;
            [Ll]) install_languages ;;
            [Oo]) install_devops ;;
            [Uu]) show_uninstall_menu ;;
            [Qq]) 
                echo "Goodbye! 👋"
                exit 0
                ;;
            *)
                print_error "Invalid option: $choice"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
        clear
    done
}

install_all() {
    print_info "Installing ALL components..."
    run_module "browsers"
    run_module "dock"
    run_module "vscode"
    run_module "cursor"
    run_module "antigravity"
    run_module "jetbrains"
    run_module "ibus-unikey"
    run_module "devops"
    run_module "nodejs"
    run_module "python"
    run_module "golang"
    run_module "zsh"
    run_module "terminal-tools"
    run_module "gnome-extensions"
    print_success "All installations complete!"
}

install_dev_tools() {
    print_info "Installing Dev Tools..."
    run_module "vscode"
    run_module "cursor"
    run_module "antigravity"
    run_module "jetbrains"
    print_success "Dev Tools installation complete!"
}

install_languages() {
    print_info "Installing Programming Languages..."
    run_module "nodejs"
    run_module "python"
    run_module "golang"
    print_success "Languages installation complete!"
}

install_devops() {
    print_info "Installing DevOps Tools..."
    run_module "devops"
    run_module "azure-cli"
    print_success "DevOps Tools installation complete!"
}

show_help() {
    echo "Usage: ./setup.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  --all, -a              Install all components"
    echo "  --dev, -d              Install dev tools only (VSCode, Cursor, etc.)"
    echo "  --lang, -l             Install languages only (Node, Python, Go)"
    echo "  --devops, -o           Install DevOps tools only (Docker, Azure CLI, etc.)"
    echo "  --wizard, -w           Run setup wizard with profiles"
    echo "  --health, -c           Show health check (installed tools)"
    echo "  --uninstall, -r <mod>  Uninstall specific module"
    echo "  --help, -h             Show this help message"
    echo "  <module>               Install specific module"
    echo
    echo "Available modules:"
    echo "  browsers, dock, vscode, cursor, antigravity, jetbrains, ibus-unikey, devops"
    echo "  nodejs, python, golang, zsh, terminal-tools, gnome-extensions"
    echo "  azure-cli, ssh-keygen, health-check, export-config, wizard"
    echo
    echo "Examples:"
    echo "  ./setup.sh                    # Interactive menu"
    echo "  ./setup.sh --wizard           # Run setup wizard"
    echo "  ./setup.sh --health           # Show installed tools"
    echo "  ./setup.sh zsh                # Install Zsh only"
    echo "  ./setup.sh --uninstall cursor # Uninstall Cursor"
}

main "$@"
