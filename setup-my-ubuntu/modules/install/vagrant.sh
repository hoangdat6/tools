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

install_vagrant() {
    info "Installing Vagrant..."
    
    # Check if already installed
    if command -v vagrant &> /dev/null; then
        local current_version
        current_version=$(vagrant --version | awk '{print $2}')
        warn "Vagrant is already installed (version: $current_version)"
        read -p "Do you want to reinstall/upgrade? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Install dependencies
    info "Installing dependencies..."
    sudo apt update
    sudo apt install -y wget gpg apt-transport-https
    
    # Add HashiCorp GPG key
    info "Adding HashiCorp GPG key..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    
    # Add HashiCorp repository
    info "Adding HashiCorp repository..."
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    # Install Vagrant
    info "Installing Vagrant from HashiCorp repository..."
    sudo apt update
    sudo apt install -y vagrant
    
    # Verify installation
    if command -v vagrant &> /dev/null; then
        local installed_version
        installed_version=$(vagrant --version)
        pass "Vagrant installed successfully!"
        note "Version: $installed_version"
        echo ""
        note "Quick start commands:"
        note "  vagrant init ubuntu/jammy64  # Initialize Ubuntu 22.04 VM"
        note "  vagrant up                   # Start the VM"
        note "  vagrant ssh                  # SSH into the VM"
        note "  vagrant halt                 # Stop the VM"
        note "  vagrant destroy              # Delete the VM"
    else
        fail "Vagrant installation failed!"
        exit 1
    fi
}

uninstall_vagrant() {
    info "Uninstalling Vagrant..."
    
    if ! command -v vagrant &> /dev/null; then
        warn "Vagrant is not installed"
        return
    fi
    
    sudo apt remove -y vagrant
    sudo rm -f /etc/apt/sources.list.d/hashicorp.list
    sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
    sudo apt update
    
    pass "Vagrant uninstalled successfully!"
}

show_vagrant_menu() {
    echo ""
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                      📦 VAGRANT MANAGER                            │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  📥 Install Vagrant                                           │"
    echo "│  [2]  🗑️  Uninstall Vagrant                                         │"
    echo "│  [3]  ℹ️  Check Vagrant version                                     │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back                                                      │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo ""
}

check_version() {
    if command -v vagrant &> /dev/null; then
        info "Vagrant version:"
        vagrant --version
        echo ""
        info "Installed plugins:"
        vagrant plugin list 2>/dev/null || note "No plugins installed"
    else
        warn "Vagrant is not installed"
    fi
}

main() {
    # Direct install mode if no menu needed
    if [ "${1:-}" = "--install" ]; then
        install_vagrant
        return
    fi
    
    if [ "${1:-}" = "--uninstall" ]; then
        uninstall_vagrant
        return
    fi
    
    # Interactive menu
    while true; do
        show_vagrant_menu
        read -p "Select option: " choice
        echo
        
        case "$choice" in
            1) install_vagrant ;;
            2) uninstall_vagrant ;;
            3) check_version ;;
            [Bb]) return ;;
            *) warn "Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
