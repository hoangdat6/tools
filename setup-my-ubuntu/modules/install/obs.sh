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

install_obs() {
    info "Installing OBS Studio..."
    
    # Check if already installed
    if command -v obs &> /dev/null; then
        local current_version
        current_version=$(obs --version 2>/dev/null | head -1 || echo "installed")
        warn "OBS Studio is already installed ($current_version)"
        read -p "Do you want to reinstall/upgrade? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Add OBS Studio PPA
    info "Adding OBS Studio PPA..."
    sudo add-apt-repository -y ppa:obsproject/obs-studio
    
    # Update and install
    info "Installing OBS Studio..."
    sudo apt update
    sudo apt install -y obs-studio
    
    # Install optional dependencies for better performance
    info "Installing optional dependencies (v4l2loopback for virtual camera)..."
    sudo apt install -y v4l2loopback-dkms v4l2loopback-utils 2>/dev/null || warn "v4l2loopback not available"
    
    # Verify installation
    if command -v obs &> /dev/null; then
        pass "OBS Studio installed successfully!"
        echo ""
        note "Launch OBS Studio:"
        note "  obs                    # From terminal"
        note "  or from Applications menu"
        echo ""
        note "Tips:"
        note "  - First launch will run the auto-configuration wizard"
        note "  - Use 'Start Virtual Camera' for video calls"
    else
        fail "OBS Studio installation failed!"
        exit 1
    fi
}

uninstall_obs() {
    info "Uninstalling OBS Studio..."
    
    if ! command -v obs &> /dev/null; then
        warn "OBS Studio is not installed"
        return
    fi
    
    sudo apt remove -y obs-studio
    sudo add-apt-repository -y --remove ppa:obsproject/obs-studio 2>/dev/null || true
    sudo apt update
    
    pass "OBS Studio uninstalled successfully!"
}

show_obs_menu() {
    echo ""
    echo "┌────────────────────────────────────────────────────────────────────┐"
    echo "│                      🎬 OBS STUDIO MANAGER                         │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [1]  📥 Install OBS Studio                                        │"
    echo "│  [2]  🗑️  Uninstall OBS Studio                                      │"
    echo "│  [3]  ℹ️  Check OBS version                                         │"
    echo "├────────────────────────────────────────────────────────────────────┤"
    echo "│  [B]  ⬅️  Back                                                      │"
    echo "└────────────────────────────────────────────────────────────────────┘"
    echo ""
}

check_version() {
    if command -v obs &> /dev/null; then
        info "OBS Studio version:"
        obs --version 2>/dev/null || note "Version info not available"
    else
        warn "OBS Studio is not installed"
    fi
}

main() {
    # Direct install mode
    if [ "${1:-}" = "--install" ]; then
        install_obs
        return
    fi
    
    if [ "${1:-}" = "--uninstall" ]; then
        uninstall_obs
        return
    fi
    
    # Interactive menu
    while true; do
        show_obs_menu
        read -p "Select option: " choice
        echo
        
        case "$choice" in
            1) install_obs ;;
            2) uninstall_obs ;;
            3) check_version ;;
            [Bb]) return ;;
            *) warn "Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
