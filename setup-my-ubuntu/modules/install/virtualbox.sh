#!/usr/bin/env bash
set -eu

[ "${DEBUG-}" = "1" ] && set -x

# @formatter:off
note() { printf "       %s\n" "${1}"; }
info() { [ "${TERM:-}" != "dumb" ] && tput colors >/dev/null 2>&1 && printf "\033[34m[INFO] %s\033[0m\n" "${1}" || printf "[INFO] %s\n" "${1}"; }
pass() { [ "${TERM:-}" != "dumb" ] && tput colors >/dev/null 2>&1 && printf "\033[32m[ OK ] %s\033[0m\n" "${1}" || printf "[ OK ] %s\n" "${1}"; }
fail() { [ "${TERM:-}" != "dumb" ] && tput colors >/dev/null 2>&1 && printf "\033[31m[FAIL] %s\033[0m\n" "${1}" || printf "[FAIL] %s\n" "${1}"; }
warn() { [ "${TERM:-}" != "dumb" ] && tput colors >/dev/null 2>&1 && printf "\033[33m[WARN] %s\033[0m\n" "${1}" || printf "[WARN] %s\n" "${1}"; }
# @formatter:on

install_virtualbox() {
    info "Installing VirtualBox..."
    
    # Check if already installed
    if command -v virtualbox &> /dev/null; then
        local current_version
        current_version=$(vboxmanage --version 2>/dev/null || echo "unknown")
        warn "VirtualBox is already installed (version: $current_version)"
        read -p "Do you want to reinstall/upgrade? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Install dependencies
    info "Installing dependencies..."
    sudo apt update
    sudo apt install -y wget gpg software-properties-common
    
    # Add Oracle VirtualBox GPG key
    info "Adding Oracle VirtualBox GPG key..."
    wget -qO- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /usr/share/keyrings/oracle-virtualbox-2016.gpg
    
    # Add VirtualBox repository
    info "Adding VirtualBox repository..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    
    # Install VirtualBox
    info "Installing VirtualBox 7.1..."
    sudo apt update
    sudo apt install -y virtualbox-7.1
    
    # Add user to vboxusers group
    info "Adding user to vboxusers group..."
    sudo usermod -aG vboxusers "$USER"
    
    # Verify installation
    if command -v virtualbox &> /dev/null; then
        local installed_version
        installed_version=$(vboxmanage --version 2>/dev/null || echo "installed")
        pass "VirtualBox installed successfully!"
        note "Version: $installed_version"
        echo ""
        warn "Please log out and log back in for group changes to take effect."
        echo ""
        note "Quick start:"
        note "  virtualbox          # Launch VirtualBox GUI"
        note "  vboxmanage list vms # List VMs"
    else
        fail "VirtualBox installation failed!"
        exit 1
    fi
}

uninstall_virtualbox() {
    info "Uninstalling VirtualBox..."
    
    if ! command -v virtualbox &> /dev/null; then
        warn "VirtualBox is not installed"
        return
    fi
    
    sudo apt remove -y virtualbox-7.1 virtualbox-7.0 virtualbox-6.1 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/virtualbox.list
    sudo rm -f /usr/share/keyrings/oracle-virtualbox-2016.gpg
    sudo apt update
    
    pass "VirtualBox uninstalled successfully!"
}

show_virtualbox_menu() {
    echo ""
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                      📦 VIRTUALBOX MANAGER                         │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  📥 Install VirtualBox                                        │"
    echo "│  [2]  🗑️  Uninstall VirtualBox                                      │"
    echo "│  [3]  ℹ️  Check VirtualBox version                                  │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back                                                      │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo ""
}

check_version() {
    if command -v virtualbox &> /dev/null; then
        info "VirtualBox version:"
        vboxmanage --version
        echo ""
        info "Extension packs:"
        vboxmanage list extpacks 2>/dev/null || note "No extension packs installed"
    else
        warn "VirtualBox is not installed"
    fi
}

main() {
    # Direct install mode
    if [ "${1:-}" = "--install" ]; then
        install_virtualbox
        return
    fi
    
    if [ "${1:-}" = "--uninstall" ]; then
        uninstall_virtualbox
        return
    fi
    
    # Interactive menu
    while true; do
        show_virtualbox_menu
        read -p "Select option: " choice
        echo
        
        case "$choice" in
            1) install_virtualbox ;;
            2) uninstall_virtualbox ;;
            3) check_version ;;
            [Bb]) return ;;
            *) warn "Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
